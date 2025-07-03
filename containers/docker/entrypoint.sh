#!/bin/bash
set -e

export RAILS_ENV=production

echo ""
if [ -z "$DATABASE_URL" ]
then
    echo "DATABASE_URL not specified. Assuming ephemeral backend. Database may be lost on container restart."
    echo "To set a database backend refer to https://docs.pwpush.com/docs/how-to-universal/#how-does-it-work"
    export DATABASE_URL=sqlite3:db/db.sqlite3
else
    echo "According to DATABASE_URL database backend is set to $(echo $DATABASE_URL|cut -d ":" -f 1):..."
fi
echo ""

echo "Password Pusher: migrating database to latest..."
bundle exec rake db:migrate

if [ -n "$PWP__THEME" ] || [ -n "$PWP_PRECOMPILE" ]; then
    echo "Password Pusher: precompiling assets for customizations..."
    bundle exec rails assets:precompile
fi

# Set the default port if not specified
#
# https://github.com/basecamp/thruster/blob/9a77a09fd256a4a8842a63808e11cc8ef3c77c52/internal/service.go#L63
# Thruster setting a PORT environment variable same as TARGET_PORT.
#
# https://github.com/basecamp/thruster/
# "Thruster's environment variables can optionally be prefixed with THRUSTER_".
# So, we set THRUSTER_TARGET_PORT to 5100 as default.
if [ -z "$THRUSTER_TARGET_PORT" ]; then
    export THRUSTER_TARGET_PORT=5100
fi

echo "Password Pusher: starting foreman..."
if [ -n "$PWP__NO_WORKER" ] || [ -n "$PWP_PUBLIC_GATEWAY" ]; then
    exec bundle exec foreman start -m web=1
else
    exec bundle exec foreman start -m web=1,worker=1
fi
