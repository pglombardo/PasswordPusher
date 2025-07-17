# frozen_string_literal: true

require "test_helper"

class ValidateSettingsTest < ActiveSupport::TestCase
  def setup
    # Store the original setting to restore it later
    @original_purge_after = Settings.purge_after
  end

  def teardown
    # Restore the original setting
    Settings.purge_after = @original_purge_after
    # Reload the initializer to restore the original configuration
    load Rails.root.join("config/initializers/validate_settings.rb")
  end

  test "validate_purge_after accepts valid duration format" do
    valid_durations = [
      "disabled",
      "3 months",
      "6 months",
      "1 year",
      "2 years",
      "3 years"
    ]

    valid_durations.each do |duration|
      Settings.purge_after = duration

      # This should not raise an error
      assert_nothing_raised do
        load Rails.root.join("config/initializers/validate_settings.rb")
      end
    end
  end

  test "validate_purge_after rejects invalid duration format" do
    invalid_durations = [
      "invalid",
      "1days",
      "day",
      "5 invalid_unit",
      "abc 123",
      "4 to_s",
      ""
    ]

    invalid_durations.each do |duration|
      Settings.purge_after = duration

      # This should raise an error
      assert_raises(StandardError) do
        load Rails.root.join("config/initializers/validate_settings.rb")
      end
    end
  end
end
