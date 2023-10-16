# frozen_string_literal: true

require 'test_helper'

class SettingsTest < Minitest::Test
  def teardown
    Settings.reload!
  end

  def test_defaults_same_as_settings
    # Make sure these two files are always the same.
    # If a user overlays config/settings.yml with an older version of the settings file
    # the prepended defaults will fill in the missing bits.  See also config/initializers/settings-defaults.rb
    settings = File.binread("#{Rails.root}/config/settings.yml")
    settings_defaults = File.binread("#{Rails.root}/config/defaults/settings.yml")

    assert settings.length == settings_defaults.length
    assert settings == settings_defaults
  end

  def test_legacy_expire_after_days_default
    legacy_env_var = 'EXPIRE_AFTER_DAYS_DEFAULT'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 7

    ENV[legacy_env_var] = '9'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 9

    ENV.delete(legacy_env_var)
  end

  def test_legacy_expire_after_days_min
    legacy_env_var = 'EXPIRE_AFTER_DAYS_MIN'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 1

    ENV[legacy_env_var] = '3'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 3

    ENV.delete(legacy_env_var)
  end

  def test_legacy_expire_after_days_max
    legacy_env_var = 'EXPIRE_AFTER_DAYS_MAX'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 90

    ENV[legacy_env_var] = '5'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 5

    ENV.delete(legacy_env_var)
  end

  def test_legacy_expire_after_views_default
    legacy_env_var = 'EXPIRE_AFTER_VIEWS_DEFAULT'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 5

    ENV[legacy_env_var] = '9'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 9

    ENV.delete(legacy_env_var)
  end

  def test_legacy_expire_after_views_min
    legacy_env_var = 'EXPIRE_AFTER_VIEWS_MIN'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 1

    ENV[legacy_env_var] = '3'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 3

    ENV.delete(legacy_env_var)
  end

  def test_legacy_expire_after_views_max
    legacy_env_var = 'EXPIRE_AFTER_VIEWS_MAX'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 100

    ENV[legacy_env_var] = '100'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 100

    ENV.delete(legacy_env_var)
  end

  def test_legacy_retrieval_step_enabled
    Settings.reload!
    assert Settings.pw.enable_retrieval_step == true

    ENV['RETRIEVAL_STEP_ENABLED'] = 'false'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.enable_retrieval_step == false

    ENV['RETRIEVAL_STEP_ENABLED'] = 'true'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.enable_retrieval_step == true

    ENV.delete('RETRIEVAL_STEP_ENABLED')
  end

  def test_legacy_retrieval_step_default
    Settings.reload!
    assert Settings.pw.retrieval_step_default == false

    ENV['RETRIEVAL_STEP_DEFAULT'] = 'false'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.retrieval_step_default == false

    ENV['RETRIEVAL_STEP_DEFAULT'] = 'true'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.retrieval_step_default == true

    ENV.delete('RETRIEVAL_STEP_DEFAULT')
  end

  def test_legacy_deletable_passwords_enabled
    Settings.reload!
    assert Settings.pw.enable_deletable_pushes == true

    ENV['DELETABLE_PASSWORDS_ENABLED'] = 'false'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.enable_deletable_pushes == false

    ENV['DELETABLE_PASSWORDS_ENABLED'] = 'true'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.enable_deletable_pushes == true

    ENV.delete('DELETABLE_PASSWORDS_ENABLED')
  end

  def test_legacy_deletable_by_viewer_passwords
    Settings.reload!
    assert Settings.pw.enable_deletable_pushes == true

    ENV['DELETABLE_BY_VIEWER_PASSWORDS'] = 'false'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.enable_deletable_pushes == false

    ENV['DELETABLE_BY_VIEWER_PASSWORDS'] = 'true'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.enable_deletable_pushes == true

    ENV.delete('DELETABLE_BY_VIEWER_PASSWORDS')
  end

  def test_legacy_deletable_passwords_default
    Settings.reload!
    assert Settings.pw.deletable_pushes_default == true

    ENV['DELETABLE_PASSWORDS_DEFAULT'] = 'false'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.deletable_pushes_default == false

    ENV['DELETABLE_PASSWORDS_DEFAULT'] = 'true'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.deletable_pushes_default == true

    ENV.delete('DELETABLE_PASSWORDS_DEFAULT')
  end

  def test_legacy_deletable_by_viewer_default
    Settings.reload!
    assert Settings.pw.deletable_pushes_default == true

    ENV['DELETABLE_BY_VIEWER_DEFAULT'] = 'false'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.deletable_pushes_default == false

    ENV['DELETABLE_BY_VIEWER_DEFAULT'] = 'true'
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.deletable_pushes_default == true

    ENV.delete('DELETABLE_BY_VIEWER_DEFAULT')
  end
end
