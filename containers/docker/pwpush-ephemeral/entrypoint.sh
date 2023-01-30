#!/bin/bash
set -e

export RAILS_ENV=private

echo "Password Pusher: migrating database to latest..."
bundle exec rake db:migrate
echo "Password Pusher: precompiling assets..."
bundle exec rails assets:precompile
echo "Password Pusher: starting puma webserver..."
bundle exec puma -C config/puma.rb -e private

exec "$@"
