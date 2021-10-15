#!/bin/bash
set -e

RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec foreman start web

exec "$@"
