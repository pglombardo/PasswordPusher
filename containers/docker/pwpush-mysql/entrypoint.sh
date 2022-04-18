#!/bin/bash
set -e

RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec puma -C config/puma.rb

exec "$@"
