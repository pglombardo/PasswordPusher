web: DEBUG=true ACME_DIRECTORY=https://acme-staging-v02.api.letsencrypt.org/directory TARGET_PORT=5100 bin/thrust bundle exec puma -C config/puma.rb
# https://letsencrypt.org/docs/staging-environment/
# `ACME_DIRECTORY=https://acme-staging-v02.api.letsencrypt.org/directory` for testing
# TLS_DOMAIN=sub_domain.example.com to use HTTPS requests
# `bin/thrust bundle exec puma -C config/puma.rb` is possible to use instead of `bin/thrust bin/rails server`
# `TARGET_PORT=5100`` is the port that Puma will listen on
# `DEBUG=true` enables debug mode, which is useful for development and debugging
# Production ready one:
# web: TLS_DOMAIN=sub_domain.example.com TARGET_PORT=5100 ./bin/thrust bundle exec puma -C config/puma.rb
worker: bundle exec rake solid_queue:start
release: bundle exec rails db:migrate
console: bundle exec rails console
