# Load the rails application
require File.expand_path('../application', __FILE__)

PAYLOAD_INITIAL_TEXT = 'Enter the Password to be Shared'
CRYPT_KEY = '}s-#2R0^/+2wEXc47\$9Eb'
CRYPT_SALT = ',2_%4?[+:3774>f'

# Initialize the rails application
PasswordPusher::Application.initialize!
