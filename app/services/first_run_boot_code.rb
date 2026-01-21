# frozen_string_literal: true

module FirstRunBootCode
  BOOT_CODE_FILE = Rails.root.join("storage", "first_run_boot_code.txt")

  class << self
    # Generate a new boot code if no users exist
    def generate_if_needed
      return if User.any?

      FileUtils.mkdir_p(File.dirname(BOOT_CODE_FILE))

      begin
        code = SecureRandom.hex(16) # 32 character hex string
        File.open(BOOT_CODE_FILE, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
          file.write(code.to_s)
        end
        code
      rescue Errno::EEXIST
        read_code_from_file
      end
    end

    # Get the current boot code
    def code
      generate_if_needed
      return nil unless File.exist?(BOOT_CODE_FILE)

      read_code_from_file
    end

    # Validate the provided code
    def valid?(provided_code)
      return false if provided_code.blank?

      boot_code = begin
        code
      rescue Errno::ENOENT, Errno::EACCES, IOError
        nil
      end

      return false if boot_code.blank?

      ActiveSupport::SecurityUtils.secure_compare(boot_code.to_s, provided_code.to_s)
    end

    # Clear the boot code (called after successful first run setup)
    def clear!
      File.delete(BOOT_CODE_FILE) if File.exist?(BOOT_CODE_FILE)
    end

    # Check if first run is needed
    def needed?
      User.none?
    end

    private

    def read_code_from_file
      File.chmod(0o600, BOOT_CODE_FILE) if File.exist?(BOOT_CODE_FILE)
      raw = File.read(BOOT_CODE_FILE).to_s.strip
      return nil if raw.blank?

      # Support both plain code and legacy "code|timestamp" format.
      if raw.include?("|")
        raw.split("|", 2).first.to_s.strip.presence
      else
        raw
      end
    rescue Errno::ENOENT, Errno::EACCES
      nil
    end
  end
end
