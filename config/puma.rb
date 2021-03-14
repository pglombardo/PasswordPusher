workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup DefaultRackup

if ENV.key?('PORT')
  port ENV['PORT']
else
  port 5000
end

if ENV.key?('RACK_ENV')
  environment ENV['RACK_ENV']
else
  environment 'development'
end

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
