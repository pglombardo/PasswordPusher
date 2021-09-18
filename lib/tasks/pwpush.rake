# frozen_string_literal: true

desc 'Run through and expire passwords.'
task :daily_expiration, [:batch_size] => :environment do |_, args|
  unless args.key?(:batch_size)
    puts 'Please specify the batch size. e.g. rails daily_expiration[100]'
    exit
  end

  expiration_count = 0
  unexpired = Password.where(expired: false).order(:created_at).limit(args[:batch_size])

  unexpired.each do |push|
    push.validate!
    if push.expired
      puts "Push #{push.url_token} created on #{push.created_at.to_s(:long)} has expired."
      expiration_count += 1
    else
      puts "Push #{push.url_token} created on #{push.created_at.to_s(:long)} is still active."
    end
  end

  puts "Batch of #{args[:batch_size]}: #{expiration_count} total pushes expired."
end
