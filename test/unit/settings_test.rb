# frozen_string_literal: true

require "test_helper"

class SettingsTest < Minitest::Test
  def teardown
    Settings.reload!
  end

  def test_defaults_same_as_settings
    # Make sure these two files are always the same.
    # If a user overlays config/settings.yml with an older version of the settings file
    # the prepended defaults will fill in the missing bits.  See also config/initializers/settings-defaults.rb
    settings = File.binread(Rails.root.join("config/settings.yml").to_s)
    settings_defaults = File.binread(Rails.root.join("config/defaults/settings.yml").to_s)

    assert settings.length == settings_defaults.length
    assert settings == settings_defaults
  end

  # Example:
  # def test_legacy_expire_after_days_default
  #   legacy_env_var = 'EXPIRE_AFTER_DAYS_DEFAULT'
  #
  #   Settings.reload!
  #   assert Settings.pw.method(legacy_env_var.downcase).call == 7
  #
  #   ENV[legacy_env_var] = '9'
  #   Settings.reload!
  #   load_legacy_environment_variables
  #   assert Settings.pw.method(legacy_env_var.downcase).call == 9
  #
  #   ENV.delete(legacy_env_var)
  # end
end
