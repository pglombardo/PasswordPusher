release: bundle exec rails db:prepare
web: env PWP_PROCESS_TYPE=web bin/web
worker: env PWP_PROCESS_TYPE=worker bundle exec rake solid_queue:start
metrics: bin/prometheus_exporter
