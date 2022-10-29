require 'test_helper'

class SettingsTest < Minitest::Test
  def test_defaults_same_as_settings
    # Make sure these two files are always the same.
    # If a user overlays config/settings.yml with an older version of the settings file
    # the prepended defaults will fill in the missing bits.  See also config/initializers/settings-defaults.rb
    settings = File.open("#{Rails.root}/config/settings.yml",'rb', &:read)
    settings_defaults = File.open("#{Rails.root}/config/settings-defaults.yml",'rb', &:read)
    
    assert settings.length == settings_defaults.length
    assert settings == settings_defaults
  end
end