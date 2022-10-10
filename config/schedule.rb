# Learn more: http://github.com/javan/whenever

set :output, "~/pwpush_cron_log.log"

# https://blog.kurttomlinson.com/posts/how-to-run-cron-jobs-with-the-whenever-gem-in-a-docker-container
ENV.each_key do |key|
    env key.to_sym, ENV[key]
end
set :environment, ENV["RAILS_ENV"]

every 1.day, at: '4:30 am' do
    rake "daily_expiration"
    rake "delete_expired_and_anonymous"
end
