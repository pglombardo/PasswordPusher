#!/bin/bash
set -e

export RAILS_ENV=production

echo "Password Pusher: migrating database to latest..."
bundle exec rake db:migrate

if [ "$PWP_PRECOMPILE" == "true" ]
then
    echo "Password Pusher: precompiling assets..."
    bundle exec rails assets:precompile
fi

echo "Password Pusher: starting puma webserver..."
bundle exec puma -C config/puma.rb

exec "$@"
