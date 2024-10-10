#!/bin/bash
set -e

export RAILS_ENV=production

echo ""
if [ -z "$DATABASE_URL" ]
then
  echo "DATABASE_URL not specified. This worker container only works with a PostgreSQL, MySQL or MariaDB database."
  echo "Please specify DATABASE_URL and use the same settings & environment variables as you do with other pwpush containers."
  echo ""
  echo "See https://docs.pwpush.com/docs/database_url/ for more information on DATABASE_URL."
  exit 1
elif [[ "$DATABASE_URL" == sqlite3://* ]]; then
  echo "Error: sqlite3 isn't supported for the pwpush-worker container."
  exit 1
else
  echo "According to DATABASE_URL database backend is set to $(echo $DATABASE_URL|cut -d ":" -f 1):..."
fi
echo ""

echo "Password Pusher: migrating database to latest..."
bundle exec rake db:migrate

echo "Password Pusher: starting background workers..."
bin/rails solid_queue:start

exec "$@"
