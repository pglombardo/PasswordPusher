# frozen_string_literal: true

max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

rails_env = ENV.fetch("RAILS_ENV", "development")
environment rails_env

case rails_env
when "production"
  workers Integer(ENV.fetch("WEB_CONCURRENCY") { 0 })

  preload_app!
when "development"
  worker_timeout 3600
end

port ENV.fetch("PORT", 5100)

# To restart: `bin/pwpush restart`
plugin :tmp_restart
