# frozen_string_literal: true

desc 'Run through and expire passwords.'
task daily_expiration: :environment do
  unexpired = Password.where(expired: false).order(:created_at).limit(500)
  expiration_count = 0

  unexpired.each do |push|
    push.validate!
    expiration_count += 1 if push.expired
  end

  puts "Batch of 500: #{expiration_count} pushes expired. #{unexpired.count} pushes are still active."
end
