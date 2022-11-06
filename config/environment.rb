# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# SLACK_CLIENT_ID
#
# PasswordPusher is listed in the Slack application integration directory.
# This requires the app to be aware of a Slack client ID.  This is used
# in the Slack integration installation process (see /slack_direct_install).
#
# Users wishing to create their own Slack integrations that point to their
# own independently hosted versions of PasswordPusher can set this environment
# variable.  e.g. For slack integrations that don't use pwpush.com
SLACK_CLIENT_ID = ENV.fetch('SLACK_CLIENT_ID', 'pwpush: NotSetInEnv')

# Initialize the Rails application.
Rails.application.initialize!
