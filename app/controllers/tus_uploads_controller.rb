# frozen_string_literal: true

# Minimal TUS-inspired resumable upload endpoint.
# POST create, PATCH append, HEAD status. Finalize creates ActiveStorage::Blob and returns signed_id.
# CSRF is skipped for the TUS flow; we mitigate session-poisoning (cross-site POST registering
# bogus upload IDs) by requiring Origin/Referer to match the request host when present.
class TusUploadsController < ApplicationController
  include TusActiveUploadSession

  skip_before_action :verify_authenticity_token, only: %i[create update destroy]
  before_action :require_tus_enabled
  before_action :authenticate_user!
  before_action :reject_cross_origin_tus_requests

  # POST /uploads
  def create
    upload_length = request.headers["Upload-Length"]&.to_i
    if upload_length.blank? || upload_length <= 0
      return head :bad_request
    end

    max_size = helpers.max_tus_upload_size_bytes
    if max_size.positive? && upload_length > max_size
      return head :payload_too_large
    end

    filename, content_type = parse_upload_metadata(request.headers["Upload-Metadata"])

    id = TusUploadStore.generate_id
    store = TusUploadStore.new(id)
    store.create!(upload_length: upload_length, filename: filename, content_type: content_type)

    register_tus_upload_in_session!(id)

    # Use relative URL so the client (browser) sends PATCH to the same origin
    response.headers["Location"] = upload_path(id)
    response.headers["Upload-Offset"] = "0"
    response.headers["Upload-Length"] = upload_length.to_s
    head :created
  end

  # PATCH /uploads/:id  — append chunk
  # HEAD /uploads/:id   — status
  def update
    id = params[:id]
    unless TusUploadStore.valid_id?(id)
      return head :not_found
    end
    store = TusUploadStore.new(id)

    if request.head?
      return head :not_found unless store.exist?
      response.headers["Upload-Offset"] = store.upload_offset.to_s
      response.headers["Upload-Length"] = store.upload_length.to_s
      return head :no_content
    end

    # PATCH
    unless request.patch?
      return head :method_not_allowed
    end

    content_length = request.content_length
    max_chunk = helpers.tus_chunk_size_bytes
    if content_length.present?
      if max_chunk.positive? && content_length > max_chunk
        return head :payload_too_large
      end
    end
    # When Content-Length is absent (e.g. chunked encoding), we still enforce max_chunk
    # in the store by limiting how many bytes we read from the body.

    unless store.exist?
      # Retry of final PATCH after we already finalized: return success so client gets X-Signed-Id
      finalized = finalized_upload_cache_read(id)
      if finalized
        response.headers["Upload-Offset"] = finalized["upload_offset"].to_s
        response.headers["Upload-Length"] = finalized["upload_length"].to_s
        response.headers["X-Signed-Id"] = finalized["signed_id"]
        return head :no_content
      end
      return head :not_found
    end
    return head :gone if store.complete?

    raw_offset = request.headers["Upload-Offset"]
    if raw_offset.blank? || !raw_offset.to_s.strip.match?(/\A\d+\z/)
      return head :bad_request
    end
    expected_offset = raw_offset.to_s.strip.to_i

    begin
      new_offset = store.append_chunk!(
        offset: expected_offset,
        io: request.body,
        max_bytes: max_chunk.positive? ? max_chunk : nil
      )
    rescue TusUploadStore::OffsetMismatch => e
      response.headers["Upload-Offset"] = e.current_offset.to_s
      return head :conflict
    rescue TusUploadStore::NotFound
      return head :not_found
    end

    if store.complete?
      begin
        upload_length = store.upload_length
        blob = store.finalize_to_blob!
        release_tus_upload_from_session!(id)
        finalized_upload_cache_write(id, signed_id: blob.signed_id, upload_length: upload_length, upload_offset: new_offset)
        response.headers["Upload-Offset"] = new_offset.to_s
        response.headers["Upload-Length"] = upload_length.to_s
        response.headers["X-Signed-Id"] = blob.signed_id
        return head :no_content
      rescue TusUploadStore::NotFound
        return head :not_found
      rescue ArgumentError => e
        return head :gone if e.message&.include?("upload not complete")
        raise
      end
    end

    response.headers["Upload-Offset"] = new_offset.to_s
    head :no_content
  end

  # DELETE /uploads/:id — abandon in-progress upload; drops temp files and clears session tracking.
  def destroy
    id = params[:id].to_s
    unless TusUploadStore.valid_id?(id)
      return head :not_found
    end
    unless tus_upload_session_tracked?(id)
      return head :not_found
    end

    store = TusUploadStore.new(id)
    store.destroy! if store.exist?
    release_tus_upload_from_session!(id)
    head :no_content
  end

  private

  def reject_cross_origin_tus_requests
    origin = request.headers["Origin"].presence
    referer = request.headers["Referer"].presence
    return if origin.blank? && referer.blank? # Allow when neither sent (e.g. same-origin no Origin)

    allowed_host = request.host

    if origin.present?
      return head :forbidden unless header_origin_host_allowed?(origin, allowed_host)
    end
    if referer.present?
      head :forbidden unless header_origin_host_allowed?(referer, allowed_host)
    end
  end

  def header_origin_host_allowed?(header_value, allowed_host)
    uri = URI.parse(header_value)
    uri.host&.downcase == allowed_host.downcase
  rescue URI::InvalidURIError
    false
  end

  def require_tus_enabled
    return if helpers.tus_uploads_enabled?
    head :not_found
  end

  def finalized_upload_cache_read(upload_id)
    Rails.cache.read("tus_finalized/#{upload_id}")
  end

  def finalized_upload_cache_write(upload_id, signed_id:, upload_length:, upload_offset:)
    Rails.cache.write(
      "tus_finalized/#{upload_id}",
      {"signed_id" => signed_id, "upload_length" => upload_length, "upload_offset" => upload_offset},
      expires_in: 2.minutes
    )
  end

  # TUS Upload-Metadata: comma-separated "key base64value" pairs
  def parse_upload_metadata(header)
    filename = nil
    content_type = nil
    return [filename, content_type] if header.blank?
    header.split(",").each do |part|
      key, value = part.strip.split(/\s+/, 2)
      next if value.blank?
      decoded = begin
        Base64.strict_decode64(value)
      rescue ArgumentError
        nil
      end
      next unless decoded
      case key&.downcase
      when "filename" then filename = sanitize_upload_filename(decoded)
      when "filetype" then content_type = sanitize_upload_content_type(decoded)
      end
    end
    [filename.presence, content_type.presence]
  end

  TUS_CONTENT_TYPE_BLOCKLIST = %w[
    text/html text/javascript application/javascript application/x-javascript
    application/ecmascript text/vbscript
  ].freeze

  def sanitize_upload_content_type(value)
    return nil if value.blank?
    type = value.to_s.strip.downcase.split(/\s*;\s*/).first
    return nil if type.blank?
    return nil if TUS_CONTENT_TYPE_BLOCKLIST.include?(type)
    type.presence
  end

  def sanitize_upload_filename(name)
    return if name.blank?
    # Strip surrounding whitespace
    sanitized = name.strip
    # Remove any path components (handles both Unix and Windows-style paths)
    sanitized = File.basename(sanitized)
    # Replace any characters that are not alphanumeric, dot, dash, plus, or underscore
    sanitized = sanitized.gsub(/[^a-zA-Z0-9.\-+_]/, "_")
    sanitized.presence
  end
end
