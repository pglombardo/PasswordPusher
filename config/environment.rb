# Load the rails application
require File.expand_path('../application', __FILE__)

PAYLOAD_INITIAL_TEXT = 'Enter the Password to be Shared'

# If deploying PasswordPusher yourself, you should change these CRYPT values.
CRYPT_KEY = '}s-#2R0^/+2wEXc47\$9Eb'
CRYPT_SALT = ',2_%4?[+:3774>f'

# Controls the "Expire After Days" form settings in Password#new
EXPIRE_AFTER_DAYS_DEFAULT = 7
EXPIRE_AFTER_DAYS_MIN = 1
EXPIRE_AFTER_DAYS_MAX = 90

# Controls the "Expire After Views" form settings in Password#new
EXPIRE_AFTER_VIEWS_DEFAULT = 5
EXPIRE_AFTER_VIEWS_MIN = 1
EXPIRE_AFTER_VIEWS_MAX = 100

# DELETABLE_BY_VIEWER_PASSWORDS
# Can passwords be deleted by viewers?
#
# When true, passwords will have a link to optionally delete
# the password being viewed.
# When pushing a new password, this option will also add a
# checkbox to conditionally enable/disable this feature on
# a per-password basis.
DELETABLE_BY_VIEWER_PASSWORDS = true

# DELETABLE_BY_VIEWER_DEFAULT
#
# When the above option (DELETABLE_BY_VIEWER_PASSWORDS) is set to
# true, this option does two things:
#   1. Sets the default check state for the "Allow viewers to
#       optionally delete password before expiration" checkbox
#   2. Sets the default value for newly pushed passwords if
#       if unspecified (such as with a json request)
#
DELETABLE_BY_VIEWER_DEFAULT = false

# Initialize the rails application
PasswordPusher::Application.initialize!
