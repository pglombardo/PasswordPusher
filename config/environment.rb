# Load the rails application
require_relative 'application'

PAYLOAD_INITIAL_TEXT = ENV.fetch('PAYLOAD_INITIAL_TEXT', 'Enter the Secret to be Shared')

# If deploying PasswordPusher yourself, you should change these CRYPT values.
if !Rails.env.production?
  CRYPT_KEY = ENV.fetch('KEY', '}s-#2R0^/+2wEXc47\$9Eb')
  CRYPT_SALT = ENV.fetch('SALT', ',2_%4?[+:3774>f')
else
  CRYPT_KEY = ENV.fetch('CRYPT_KEY', Rails.application.credentials.pwp[:KEY])
  CRYPT_SALT = ENV.fetch('CRYPT_SALT', Rails.application.credentials.pwp[:SALT])
end
# Controls the "Expire After Days" form settings in Password#new
EXPIRE_AFTER_TIME_DEFAULT = Integer(ENV.fetch('EXPIRE_AFTER_TIME_DEFAULT', 1))
EXPIRE_AFTER_TIME_ALLOWED = [1,6,12,24,48,72,96,120]

# Controls the "Expire After Views" form settings in Password#new
EXPIRE_AFTER_VIEWS_DEFAULT = Integer(ENV.fetch('EXPIRE_AFTER_VIEWS_DEFAULT', 1))
EXPIRE_AFTER_VIEWS_ALLOWED = Array (1..25)

# DELETABLE_BY_VIEWER_PASSWORDS
# Can passwords be deleted by viewers?
#
# When true, passwords will have a link to optionally delete
# the password being viewed.
# When pushing a new password, this option will also add a
# checkbox to conditionally enable/disable this feature on
# a per-password basis.
DELETABLE_BY_VIEWER_PASSWORDS = ENV.fetch('DELETABLE_BY_VIEWER_PASSWORDS', 'true') == 'true'

# DELETABLE_BY_VIEWER_DEFAULT
#
# When the above option (DELETABLE_BY_VIEWER_PASSWORDS) is set to
# true, this option does two things:
#   1. Sets the default check state for the "Allow viewers to
#       optionally delete password before expiration" checkbox
#   2. Sets the default value for newly pushed passwords if
#       if unspecified (such as with a json request)
#
DELETABLE_BY_VIEWER_DEFAULT = ENV.fetch('DELETABLE_BY_VIEWER_DEFAULT', 'true') == 'true'

# ALLOWED_DOMAINS
#
# Only this domains are allowed to run. 
# Other domains get a 500 Error
# In development and test mode is this not active.
ALLOWED_DOMAINS = ["secpush.adesso-service.com", "secpush.smarthouse.de"]


# Initialize the rails application
Rails.application.initialize!
