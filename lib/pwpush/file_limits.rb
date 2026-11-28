# frozen_string_literal: true

module Pwpush
  # Parses and applies file-push size and signed-URL expiry settings.
  module FileLimits
    UNLIMITED_TOKENS = %w[0 false unlimited none].freeze

    SIZE_UNITS = {
      "b" => 1,
      "byte" => 1,
      "bytes" => 1,
      "k" => 1024,
      "kb" => 1024,
      "kib" => 1024,
      "m" => 1024**2,
      "mb" => 1024**2,
      "mib" => 1024**2,
      "g" => 1024**3,
      "gb" => 1024**3,
      "gib" => 1024**3,
      "t" => 1024**4,
      "tb" => 1024**4,
      "tib" => 1024**4
    }.freeze

    module_function

    # @return [Integer, nil] maximum bytes per file, or nil when unlimited
    def max_file_size_bytes
      parse_file_size(Settings.files&.max_file_size)
    end

    def limited?
      max_file_size_bytes.present?
    end

    def allowed_byte_size?(bytes)
      limit = max_file_size_bytes
      return true if limit.nil?
      return true if bytes.nil? || bytes == ""

      bytes.to_i <= limit
    end

    def human_max_file_size
      raw = Settings.files&.max_file_size
      return raw.to_s.strip if raw.to_s.match?(/[A-Za-z]/)

      limit = max_file_size_bytes
      return unless limit

      ActiveSupport::NumberHelper.number_to_human_size(limit)
    end

    def too_large_message(filename: nil)
      size = human_max_file_size
      if filename.present?
        I18n._("%{filename} is too large. Maximum size per file is %{size}.") % {filename: filename, size: size}
      else
        I18n._("This file is too large. Maximum size per file is %{size}.") % {size: size}
      end
    end

    def too_large_message_template
      I18n._("%{filename} is too large. Maximum size per file is %{size}.")
    end

    def blob_url_expires_in
      parse_duration(Settings.files&.blob_urls_expire_in) || 5.minutes
    end

    def direct_upload_url_expires_in
      parse_duration(Settings.files&.direct_upload_urls_expire_in) || blob_url_expires_in
    end

    def blob_url_expires_in_clock
      format_clock(blob_url_expires_in)
    end

    def format_clock(duration)
      total = duration.to_i
      minutes, seconds = total.divmod(60)
      format("%d:%02d", minutes, seconds)
    end

    def parse_file_size(value)
      return if unlimited?(value)

      parsed = extract_file_size(value)
      return parsed if parsed

      raise ArgumentError, invalid_max_file_size_message(value)
    end

    def extract_file_size(value)
      return value if value.is_a?(Integer) && value.positive?
      return value.to_i if value.is_a?(Numeric) && value.positive?

      str = value.to_s.strip
      return str.to_i if str.match?(/\A\d+\z/) && str.to_i.positive?

      match = str.match(/\A([0-9]*\.?[0-9]+)\s*([A-Za-z]+)\z/)
      return unless match

      quantity = match[1].to_f
      multiplier = SIZE_UNITS[match[2].downcase]
      return unless multiplier && quantity.positive?

      (quantity * multiplier).to_i
    end

    def invalid_max_file_size_message(value)
      "Invalid files.max_file_size #{value.inspect}. " \
        "Use a size such as 256MB or 100GB, or 0/unlimited to disable the cap."
    end

    def parse_duration(value)
      return value if value.is_a?(ActiveSupport::Duration)
      return value.seconds if value.is_a?(Numeric) && value.positive?

      str = value.to_s.strip
      return if str.blank?
      return str.to_i.seconds if str.match?(/\A\d+\z/) && str.to_i.positive?

      quantity, unit = str.split(" ", 2)
      return if quantity.blank? || unit.blank?

      quantity.to_i.public_send(unit.downcase.to_sym)
    rescue ArgumentError, NoMethodError
      nil
    end

    def unlimited?(value)
      return true if value.nil? || value == false
      return true if value.is_a?(Numeric) && !value.positive?

      str = value.to_s.strip
      return true if str.empty?

      UNLIMITED_TOKENS.include?(str.downcase)
    end

    # Byte size of an incoming attachable: blob, uploaded file, or signed blob id.
    def byte_size_for(upload)
      return upload.byte_size if upload.respond_to?(:byte_size)
      return upload.size if io_upload?(upload)
      return signed_blob(upload)&.byte_size if upload.is_a?(String)

      nil
    end

    def filename_for(upload)
      return upload.original_filename.to_s if upload.respond_to?(:original_filename)
      return upload.filename.to_s if upload.respond_to?(:filename)
      return signed_blob(upload)&.filename.to_s if upload.is_a?(String)

      nil
    end

    def io_upload?(upload)
      upload.respond_to?(:original_filename) && upload.respond_to?(:size) && !upload.is_a?(String)
    end

    def signed_blob(signed_id)
      return if signed_id.blank?

      ActiveStorage::Blob.find_signed(signed_id)
    end
  end
end
