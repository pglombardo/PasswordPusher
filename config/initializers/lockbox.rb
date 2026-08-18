# frozen_string_literal: true

require "password_pusher/env_or_file"

# Application Encryption Key
#
# Set the environment variable PWPUSH_MASTER_KEY to set your encryption key.
# Alternatively, set PWPUSH_MASTER_KEY_FILE to a path whose contents are the key
# (Docker Compose/Swarm secrets convention). The env var wins if both are set.
#
# Example:
#   export PWPUSH_MASTER_KEY=749b1022e1cb83fb04f3022eacaf3bfef60c6d47f83e6fb41f534a05fc69929f
#   export PWPUSH_MASTER_KEY_FILE=/run/secrets/pwpush_master_key
#
# If neither is set, a default encryption key will be used.
# For key rotation, put old encryption key(s) in PWPUSH_MASTER_KEY_PREVIOUS
# (comma-separated), or PWPUSH_MASTER_KEY_PREVIOUS_FILE pointing at such a file.
#
# Changing an encryption key where old pushes already exist will make those older pushes
# unreadable.  In other words, the payloads will be garbled.  New pushes going forward
# will work fine.
#
# The best security is to use your own custom encryption key.  Any risk in using the default
# key is lessened if you keep your instance secure and limit your push expirations versus
# longer living pushes.  e.g.  1 day/1 view versus 100 days/100 views.
#
# To generate a new encryption key, run the following:
#   > rails c
#   > Lockbox.generate_key
#
# or go to https://pwpush.com/pages/generate_key
#
Lockbox.master_key = PasswordPusher::EnvOrFile.read("PWPUSH_MASTER_KEY") ||
  "749b1022e1cb83fb04f3022eacaf3bfef60c6d47f83e6fb41f534a05fc69929f"

previous = PasswordPusher::EnvOrFile.read("PWPUSH_MASTER_KEY_PREVIOUS")
if previous
  Lockbox.default_options[:previous_versions] = previous.split(",").map(&:strip).reject(&:empty?).map do |previous_key|
    {master_key: previous_key}
  end
end
