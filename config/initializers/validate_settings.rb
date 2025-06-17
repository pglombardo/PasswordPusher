# frozen_string_literal: true

# Validate Settings initializer
# This file validates application settings

def validate_purge_after
  if Settings.purge_after != "disabled"
    to_duration(Settings.purge_after)
  end
rescue NoMethodError
  message = "Invalid purge_after setting: #{Settings.purge_after}"
  Rails.logger.error(message)

  raise StandardError.new(message)
end

# Run validation
validate_purge_after

private

def to_duration(str)
  str.to_s.strip.split(" ").then { |quantity, unit| quantity.to_i.send(unit.downcase.to_sym) }
end
