# frozen_string_literal: true

# Validate Settings initializer
# This file validates application settings

module SettingsValidator
  class << self
    def validate_purge_after_setting
      return if Settings.purge_after == "disabled"

      begin
        duration = to_duration(Settings.purge_after)
        unless duration.is_a?(ActiveSupport::Duration)
          raise_invalid_setting
        end
      rescue
        raise_invalid_setting
      end
    end

    private

    def to_duration(str)
      str.to_s.strip.split(" ").then { |quantity, unit| quantity.to_i.send(unit.downcase.to_sym) }
    end

    def raise_invalid_setting
      message = "Invalid purge_after setting: #{Settings.purge_after}"

      Rails.logger.error(message)
      raise StandardError, message
    end
  end
end

# Run validation
SettingsValidator.validate_purge_after_setting
