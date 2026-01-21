# frozen_string_literal: true

module FirstRunBootCode
  BOOT_CODE_FILE = Rails.root.join("tmp", "first_run_boot_code.txt")

  class << self
    # Generate a new boot code if no users exist
    def generate_if_needed
      return if User.any?

      FileUtils.mkdir_p(File.dirname(BOOT_CODE_FILE))

      begin
        code = SecureRandom.hex(16) # 32 character hex string
        File.open(BOOT_CODE_FILE, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
          file.write("#{code}|#{Time.now.to_i}")
        end
        code
      rescue Errno::EEXIST
        stored_data = File.read(BOOT_CODE_FILE).strip.split("|")
        stored_data[0]
      end
    end

    # Get the current boot code
    def code
      generate_if_needed
      return nil unless File.exist?(BOOT_CODE_FILE)

      stored_data = File.read(BOOT_CODE_FILE).strip.split("|")
      stored_data[0]
    end

    # Validate the provided code
    def valid?(provided_code)
      return false if provided_code.blank?

      begin
        boot_code = code
      rescue
        return false
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

    def save_code(code)
      FileUtils.mkdir_p(File.dirname(BOOT_CODE_FILE))
      File.write(BOOT_CODE_FILE, "#{code}|#{Time.now.to_i}")
      File.chmod(0o600, BOOT_CODE_FILE) # Make it readable only by owner
    end
  end
end
