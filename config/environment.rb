# Load the Rails application.
require_relative 'application'

PAYLOAD_INITIAL_TEXT = ENV.fetch('PAYLOAD_INITIAL_TEXT', 'Enter the Password to be Shared')

# If deploying PasswordPusher yourself, you should change these CRYPT values.
CRYPT_KEY = ENV.fetch('CRYPT_KEY', '}s-#2R0^/+2wEXc47\$9Eb')
CRYPT_SALT = ENV.fetch('CRYPT_SALT', ',2_%4?[+:3774>f')

# Controls the "Expire After Days" form settings in Password#new
EXPIRE_AFTER_DAYS_DEFAULT = Integer(ENV.fetch('EXPIRE_AFTER_DAYS_DEFAULT', 7))
EXPIRE_AFTER_DAYS_MIN = Integer(ENV.fetch('EXPIRE_AFTER_DAYS_MIN', 1))
EXPIRE_AFTER_DAYS_MAX = Integer(ENV.fetch('EXPIRE_AFTER_DAYS_MAX', 90))

# Controls the "Expire After Views" form settings in Password#new
EXPIRE_AFTER_VIEWS_DEFAULT = Integer(ENV.fetch('EXPIRE_AFTER_VIEWS_DEFAULT', 5))
EXPIRE_AFTER_VIEWS_MIN = Integer(ENV.fetch('EXPIRE_AFTER_VIEWS_MIN', 1))
EXPIRE_AFTER_VIEWS_MAX = Integer(ENV.fetch('EXPIRE_AFTER_VIEWS_MAX', 100))

# RETRIEVAL_STEP_ENABLED
# Is the option to offer a password retrieval step enabled?
RETRIEVAL_STEP_ENABLED = ENV.fetch('RETRIEVAL_STEP_ENABLED', 'true') == 'true'

# RETRIEVAL_STEP_REQUIRED_DEFAULT
# Will pushed passwords require an extra click through to get to the actual password?
#
# When true, secret URLs will be generated as /p/xxxxxxxx/r which will show a page
# requiring a click to view the page /p/xxxxxxxx
RETRIEVAL_STEP_DEFAULT = ENV.fetch('RETRIEVAL_STEP_REQUIRED_DEFAULT', 'false') == 'false'

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
#   2. JSON API: Sets the default value for newly pushed passwords if
#       unspecified
#
DELETABLE_BY_VIEWER_DEFAULT = ENV.fetch('DELETABLE_BY_VIEWER_DEFAULT', 'true') == 'true'

# SLACK_CLIENT_ID
#
# PasswordPusher is listed in the Slack application integration directory.
# This requires the app to be aware of a Slack client ID.  This is used
# in the Slack integration installation process (see /slack_direct_install).
#
# Users wishing to create their own Slack integrations that point to their
# own independently hosted versions of PasswordPusher can set this environment
# variable.  e.g. For slack integrations that don't use pwpush.com
SLACK_CLIENT_ID = ENV.fetch('SLACK_CLIENT_ID', "pwpush: NotSetInEnv")

# Initialize the Rails application.
Rails.application.initialize!
