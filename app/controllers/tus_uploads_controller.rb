# frozen_string_literal: true

# Minimal TUS-inspired resumable upload endpoint.
# POST create, PATCH append, HEAD status. Finalize creates ActiveStorage::Blob and returns signed_id.
class TusUploadsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[create update]
  before_action :require_tus_enabled
  before_action :authenticate_user!

  # POST /uploads
  def create
    upload_length = request.headers["Upload-Length"]&.to_i
    if upload_length.blank? || upload_length <= 0
      return head :bad_request
    end

    max_size = Settings.files.max_tus_upload_size.to_i
    if max_size.positive? && upload_length > max_size
      return head :payload_too_large
    end

    filename, content_type = parse_upload_metadata(request.headers["Upload-Metadata"])

    id = TusUploadStore.generate_id
    store = TusUploadStore.new(id)
    store.create!(upload_length: upload_length, filename: filename, content_type: content_type)

    response.headers["Location"] = upload_url_for(id)
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

    return head :not_found unless store.exist?
    return head :gone if store.complete?

    expected_offset = request.headers["Upload-Offset"]&.to_i
    if expected_offset.nil?
      return head :bad_request
    end

    begin
      new_offset = store.append_chunk!(offset: expected_offset, io: request.body)
    rescue TusUploadStore::OffsetMismatch => e
      response.headers["Upload-Offset"] = e.current_offset.to_s
      return head :conflict
    end

    if store.complete?
      upload_length = store.upload_length
      blob = store.finalize_to_blob!
      response.headers["Upload-Offset"] = new_offset.to_s
      response.headers["Upload-Length"] = upload_length.to_s
      response.headers["X-Signed-Id"] = blob.signed_id
      return head :no_content
    end

    response.headers["Upload-Offset"] = new_offset.to_s
    head :no_content
  end

  private

  def require_tus_enabled
    return if tus_enabled?
    head :not_found
  end

  def tus_enabled?
    Settings.files.use_tus_uploads.to_s == "true"
  end

  def upload_url_for(id)
    url_helpers = Rails.application.routes.url_helpers
    base = "#{request.scheme}://#{request.host}"
    base += ":#{request.port}" if request.port != 80 && request.port != 443
    "#{base}#{url_helpers.upload_path(id)}"
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
      when "filename" then filename = decoded
      when "filetype" then content_type = decoded
      end
    end
    [filename.presence, content_type.presence]
  end
end
