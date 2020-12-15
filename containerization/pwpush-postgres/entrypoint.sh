#!/bin/bash
set -e

RAILS_ENV=production bundle exec rake db:migrate
bundle exec foreman start puma

exec "$@"
