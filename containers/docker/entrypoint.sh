#!/bin/bash
set -e

export RAILS_ENV=production

# If arguments are passed, execute them directly (e.g., "bundle exec rails secret")
# This allows running utility commands without starting the full application
if [ $# -gt 0 ]; then
    exec "$@"
fi

# Validate or generate SECRET_KEY_BASE
if [ -z "$SECRET_KEY_BASE" ]; then
    echo "⚠️  WARNING: SECRET_KEY_BASE not set!"
    echo "   SECRET_KEY_BASE is used to encrypt and sign session cookies."
    echo "   Generating a random secret_key_base for this session."
    echo "   ⚠️  This will break sessions after container restart.  Users will need to login again."
    echo "   If you want to avoid this:"
    echo ""
    echo "   Generate a secret_key_base with:"
    echo "     docker run --rm pglombardo/pwpush bundle exec rails secret"
    echo ""
    echo "   Set it when running the container to persist it:"
    echo "     docker run -e SECRET_KEY_BASE=<your-secret> pglombardo/pwpush"
    echo ""
    export SECRET_KEY_BASE=$(ruby -e "require 'securerandom'; puts SecureRandom.hex(64)")
else
    echo "✓ SECRET_KEY_BASE is set"
fi

echo ""
if [ -z "$DATABASE_URL" ]
then
    # Check if old database path exists, otherwise use new path based on RAILS_ENV
    if [ -f "/opt/PasswordPusher/db/db.sqlite3" ]
    then
        echo "⚠️ Using deprecated database path: /opt/PasswordPusher/db/db.sqlite3"
        echo ""
        echo "EPHEMERAL (no action): Database will be recreated on restart."
        echo ""
        echo "PERSISTENT (migration advised):"
        echo "  1. Inside container:"
        echo "     mkdir -p /opt/PasswordPusher/storage/db"
        echo "     mv /opt/PasswordPusher/db/db.sqlite3 /opt/PasswordPusher/storage/db/production.sqlite3"
        echo "     [ -f /opt/PasswordPusher/db/db.sqlite3-wal ] && mv /opt/PasswordPusher/db/db.sqlite3-wal /opt/PasswordPusher/storage/db/production.sqlite3-wal || true"
        echo "     [ -f /opt/PasswordPusher/db/db.sqlite3-shm ] && mv /opt/PasswordPusher/db/db.sqlite3-shm /opt/PasswordPusher/storage/db/production.sqlite3-shm || true"
        echo "  2. Make sure that storage is a persistent volume: -v pwpush-storage:/opt/PasswordPusher/storage"
        echo ""
        export DATABASE_URL=sqlite3:db/db.sqlite3
    else
        export DATABASE_URL=sqlite3:storage/db/production.sqlite3
    fi
else
    echo "According to DATABASE_URL database backend is set to $(echo $DATABASE_URL|cut -d ":" -f 1):..."
fi
echo ""

# Persist DATABASE_URL and RAILS_ENV for shell access
echo "export DATABASE_URL=\"${DATABASE_URL}\"" >> /opt/PasswordPusher/.env.production
echo "export RAILS_ENV=\"${RAILS_ENV}\"" >> /opt/PasswordPusher/.env.production
echo "export SECRET_KEY_BASE=\"${SECRET_KEY_BASE}\"" >> /opt/PasswordPusher/.env.production

echo "Password Pusher: migrating database to latest..."
bundle exec rake db:migrate

if [ -n "$PWP__THEME" ] || [ -n "$PWP_PRECOMPILE" ]; then
    echo "Password Pusher: precompiling assets for THEME=${PWP__THEME} customization..."
    bundle exec rails assets:precompile
fi

# Set the default port if not specified
if [ -n "$PORT" ]; then
    export TARGET_PORT=$PORT
else
    export TARGET_PORT=5100
fi

echo "Password Pusher: starting foreman..."
if [ -n "$PWP__NO_WORKER" ] || [ -n "$PWP_PUBLIC_GATEWAY" ]; then
    exec bundle exec foreman start -m web=1
else
    exec bundle exec foreman start -m web=1,worker=1
fi
