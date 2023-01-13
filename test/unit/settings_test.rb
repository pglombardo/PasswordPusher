require 'test_helper'

class SettingsTest < Minitest::Test
  def teardown
    Settings.reload!
  end

  def test_defaults_same_as_settings
    # Make sure these two files are always the same.
    # If a user overlays config/settings.yml with an older version of the settings file
    # the prepended defaults will fill in the missing bits.  See also config/initializers/settings-defaults.rb
    settings = File.open("#{Rails.root}/config/settings.yml",'rb', &:read)
    settings_defaults = File.open("#{Rails.root}/config/defaults/settings.yml",'rb', &:read)

    assert settings.length == settings_defaults.length
    assert settings == settings_defaults
  end

  def test_legacy_EXPIRE_AFTER_DAYS_DEFAULT
    legacy_env_var = 'EXPIRE_AFTER_DAYS_DEFAULT'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 7

    ENV[legacy_env_var] = "9"
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 9

    ENV.delete(legacy_env_var)
  end

  def test_legacy_EXPIRE_AFTER_DAYS_MIN
    legacy_env_var = 'EXPIRE_AFTER_DAYS_MIN'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 1

    ENV[legacy_env_var] = "3"
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 3

    ENV.delete(legacy_env_var)
  end

  def test_legacy_EXPIRE_AFTER_DAYS_MAX
    legacy_env_var = 'EXPIRE_AFTER_DAYS_MAX'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 90

    ENV[legacy_env_var] = "5"
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 5

    ENV.delete(legacy_env_var)
  end

  def test_legacy_EXPIRE_AFTER_VIEWS_DEFAULT
    legacy_env_var = 'EXPIRE_AFTER_VIEWS_DEFAULT'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 5

    ENV[legacy_env_var] = "9"
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 9

    ENV.delete(legacy_env_var)
  end

  def test_legacy_EXPIRE_AFTER_VIEWS_MIN
    legacy_env_var = 'EXPIRE_AFTER_VIEWS_MIN'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 1

    ENV[legacy_env_var] = "3"
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 3

    ENV.delete(legacy_env_var)
  end

  def test_legacy_EXPIRE_AFTER_VIEWS_MAX
    legacy_env_var = 'EXPIRE_AFTER_VIEWS_MAX'

    Settings.reload!
    assert Settings.pw.method(legacy_env_var.downcase).call == 100

    ENV[legacy_env_var] = "100"
    Settings.reload!
    load_legacy_environment_variables
    assert Settings.pw.method(legacy_env_var.downcase).call == 100

    ENV.delete(legacy_env_var)
  end

  def test_legacy_RETRIEVAL_STEP_ENABLED
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
  
  def test_legacy_RETRIEVAL_STEP_DEFAULT
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
  
  def test_legacy_DELETABLE_PASSWORDS_ENABLED
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
  
  def test_legacy_DELETABLE_BY_VIEWER_PASSWORDS
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

  def test_legacy_DELETABLE_PASSWORDS_DEFAULT
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
  
  def test_legacy_DELETABLE_BY_VIEWER_DEFAULT
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