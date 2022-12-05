# frozen_string_literal: true

# A task that should be run periodically (daily/weekly) to run through all unexpired
# pushes and run .validate! which will determine if a push has expired or not.
#
# Note: .validate! is also run on each attempt to view an unexpired secret URL so this task is
# a preemptive measure to expire pushes periodically.  It saves some CPU and DB calls
# on live requests.
#
desc 'Run through, validate and conditionally expire passwords.'
task daily_expiration: :environment do
  counter = 0
  expiration_count = 0

  Password.where(expired: false).find_each do |push|
    counter += 1

    push.validate!
    if push.expired
      puts "#{counter}: Push #{push.url_token} created on #{push.created_at.to_s(:long)} by user #{push.user_id} has expired."
      expiration_count += 1
    # else
    #   puts "#{counter}: Push #{push.url_token} created on #{push.created_at.to_s(:long)} by user #{push.user_id} is still active."
    end
  end

  puts "#{expiration_count} total pushes expired."

  puts ''
  puts 'All done.  Bye!  (っ＾▿＾)۶🍸🌟🍺٩(˘◡˘ )'
  puts ''
end

# When a Password expires, the payload is deleted but the metadata record still exists.  This
# includes information such as creation date, views, duration etc..  When the record
# was created by an anonymous user, this data is no longer needed (and we don't want it).
#
# If a user attempts to retrieve a secret link that doesn't exist, we still show the standard
# "This secret link has expired" message.  This strategy provides two benefits:
#
# 1. It hides the fact that if a secret ever exists or not (more secure)
# 2. It allows us to delete data that we don't want
#
# This task will run through all expired and anonymous records and delete them entirely.
#
# Because of the above, expired and anonymous secret URLs still will show the same
# expiration message
#
# Note: This applies to anonymous pushes.  For logged-in user records, we don't do this
# to maintain user audit logs.
#
desc 'Delete expired and anonymous pushes.'
task delete_expired_and_anonymous: :environment do
  counter = 0

  Password.includes(:views)
          .where(expired: true)
          .where(user_id: nil)
          .find_each do |push|
    counter += 1
    puts "#{counter}: Deleting expired and anonymous push #{push.url_token} created on " \
         "#{push.created_at.to_s(:long)} with #{push.views.size} views."
    push.destroy
  end

  puts "#{counter} total pushes deleted."

  puts ''
  puts 'All done.  Bye!  (っ＾▿＾)۶🍸🌟🍺٩(˘◡˘ )'
  puts ''
end

desc 'Generate robots.txt.'
task generate_robots_txt: :environment do
  contents = "User-Agent: *\nDisallow: /p/\n"

  I18n.available_locales.each do |lang|
    contents += "Disallow: /#{lang}/p/\n"
  end

  File.open('./public/robots.txt', 'w') { |file| file.write(contents) }

  puts ''
  puts 'All done.  Bye!  (っ＾▿＾)۶🍸🌟🍺٩(˘◡˘ )'
  puts ''
end
