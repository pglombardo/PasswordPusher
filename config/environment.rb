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

# Initialize the rails application
PasswordPusher::Application.initialize!
