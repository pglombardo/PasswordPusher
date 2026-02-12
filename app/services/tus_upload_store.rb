# frozen_string_literal: true

# Manages temporary TUS upload state and chunk storage under tmp/uploads/<id>/.
# No user-defined paths; id is server-generated only.
class TusUploadStore
  class NotFound < StandardError; end

  class OffsetMismatch < StandardError
    attr_reader :current_offset
    def initialize(current_offset)
      @current_offset = current_offset
      super("Upload-Offset mismatch")
    end
  end

  TMP_ROOT = "tmp/uploads"

  def self.root
    Rails.root.join(TMP_ROOT)
  end

  def self.generate_id
    SecureRandom.urlsafe_base64(24)
  end

  def initialize(id)
    @id = id
    @base = self.class.root.join(@id)
  end

  def path
    @base
  end

  def data_path
    @base.join("data")
  end

  def meta_path
    @base.join("meta.json")
  end

  def create!(upload_length:, filename: nil, content_type: nil)
    raise ArgumentError, "upload_length required" if upload_length.blank?

    FileUtils.mkdir_p(@base)
    meta = {
      "upload_length" => upload_length.to_i,
      "upload_offset" => 0,
      "filename" => filename.presence,
      "content_type" => content_type.presence,
      "created_at" => Time.current.utc.iso8601
    }
    File.write(meta_path, meta.to_json)
    self
  end

  def exist?
    File.file?(meta_path)
  end

  def meta
    raise NotFound unless exist?
    JSON.parse(File.read(meta_path))
  end

  def upload_length
    meta["upload_length"].to_i
  end

  def upload_offset
    meta["upload_offset"].to_i
  end

  def append_chunk!(offset:, io:)
    current = upload_offset
    raise OffsetMismatch, current if offset != current

    mode = current.zero? ? "wb" : "ab"
    File.open(data_path, mode) { |f| IO.copy_stream(io, f) }
    new_offset = File.size(data_path)
    update_offset!(new_offset)
    new_offset
  end

  def complete?
    exist? && upload_offset >= upload_length
  end

  def finalize_to_blob!
    raise NotFound unless exist?
    raise ArgumentError, "upload not complete" unless complete?

    m = meta
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(data_path, "rb"),
      filename: m["filename"].presence || "upload",
      content_type: m["content_type"].presence || "application/octet-stream"
    )
    destroy!
    blob
  end

  def destroy!
    FileUtils.rm_rf(@base) if @base.exist?
  end

  def self.cleanup_stale!(ttl_seconds:)
    root = Rails.root.join(TMP_ROOT)
    return unless root.exist?

    cutoff = Time.current - ttl_seconds
    Dir.each_child(root) do |id|
      dir = root.join(id)
      next unless dir.directory?
      meta_file = dir.join("meta.json")
      next unless File.file?(meta_file)
      begin
        m = JSON.parse(File.read(meta_file))
        created = Time.zone.parse(m["created_at"])
        if created && created < cutoff
          FileUtils.rm_rf(dir)
          Rails.logger.info "[TUS] Cleaned up stale upload #{id}"
        end
      rescue => e
        Rails.logger.warn "[TUS] Cleanup error for #{id}: #{e.message}"
      end
    end
  end

  private

  def update_offset!(new_offset)
    m = meta
    m["upload_offset"] = new_offset
    File.write(meta_path, m.to_json)
  end
end
