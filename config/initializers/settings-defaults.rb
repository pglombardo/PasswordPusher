# Prepend defaults to the Settings object in case users are missing some of the latest settings
Settings.prepend_source!("#{Rails.root}/config/settings-defaults.yml")
Settings.reload!

