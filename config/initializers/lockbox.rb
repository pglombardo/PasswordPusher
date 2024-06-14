# frozen_string_literal: true

# Application Encryption Key
#
# Set the environment variable PWPUSH_MASTER_KEY to set your encryption key.
#
# Example:
#   export PWPUSH_MASTER_KEY=749b1022e1cb83fb04f3022eacaf3bfef60c6d47f83e6fb41f534a05fc69929f
#
# If this environment variable is not set, a default encryption key will be used.
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
#   > Lockbox.gnerate_key
#
# or go to https://pwpush.com/pages/generate_key
#
Lockbox.master_key = ENV.fetch("PWPUSH_MASTER_KEY", "749b1022e1cb83fb04f3022eacaf3bfef60c6d47f83e6fb41f534a05fc69929f")
