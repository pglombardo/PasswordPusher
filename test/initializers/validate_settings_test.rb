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

  test "to_duration correctly converts string to duration" do
    # Get access to the to_duration method
    to_duration_method = method(:to_duration)

    # Test various valid duration strings
    assert_equal 1.day, to_duration_method.call("1 day")
    assert_equal 5.days, to_duration_method.call("5 days")
    assert_equal 2.weeks, to_duration_method.call("2 weeks")
    assert_equal 1.month, to_duration_method.call("1 month")
    assert_equal 3.months, to_duration_method.call("3 months")
  end

  test "to_duration raises error for invalid duration strings" do
    # Get access to the to_duration method
    to_duration_method = method(:to_duration)

    # Test various invalid duration strings
    assert_raises(NoMethodError) { to_duration_method.call("invalid") }
    assert_raises(NoMethodError) { to_duration_method.call("") }
    assert_raises(NoMethodError) { to_duration_method.call("5 invalid_unit") }
  end
end
