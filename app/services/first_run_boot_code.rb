# frozen_string_literal: true

module FirstRunBootCode
  BOOT_CODE_FILE = Rails.root.join("tmp", "first_run_boot_code.txt")

  class << self
    # Generate a new boot code if no users exist
    def generate_if_needed
      return if User.any?
      return if File.exist?(BOOT_CODE_FILE)

      code = SecureRandom.hex(16) # 32 character hex string
      save_code(code)
      code
    end

    # Get the current boot code
    def code
      generate_if_needed

      stored_data = File.read(BOOT_CODE_FILE).strip.split("|")
      stored_data[0]
    end

    # Validate the provided code
    def valid?(provided_code)
      return false if provided_code.blank?
      return false if code.blank?

      ActiveSupport::SecurityUtils.secure_compare(code.to_s, provided_code.to_s)
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
