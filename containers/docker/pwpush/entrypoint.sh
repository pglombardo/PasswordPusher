#!/bin/bash
set -e

export RAILS_ENV=production

if [ -z "$DATABASE_URL" ]
then
    echo "DATABASE_URL not specified. Assuming ephemeral backend. Database may be lost on container restart."
    echo "To set a database backend refer to https://github.com/pglombardo/PasswordPusher/wiki/Switch-to-Another-Backend-Database#environment-variable"
    export DATABASE_URL=sqlite3:db/db.sqlite3
else 
    echo "According to DATABASE_URL database backend is set to $(echo $DATABASE_URL|cut -d ":" -f 1):..."
fi

echo "Password Pusher: migrating database to latest..."
bundle exec rake db:migrate

if [ "$PWP_PRECOMPILE" == "true" ]
then
    echo "Password Pusher: precompiling assets for customisations..."
    bundle exec rails assets:precompile
fi

echo "Password Pusher: starting puma webserver..."
bundle exec puma -C config/puma.rb

exec "$@"
