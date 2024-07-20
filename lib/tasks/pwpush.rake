# frozen_string_literal: true

# A task that should be run periodically (daily/weekly) to iterate through all unexpired
# pushes and run .validate! which will determine if a push has expired or not.
#
# Note: .validate! is also run on each attempt to view an unexpired secret URL so this task is
# a preemptive measure to expire pushes periodically.  It saves some CPU and DB calls
# on live requests.
#
desc "Run through, validate and conditionally expire passwords."
task daily_expiration: :environment do
  counter = 0
  expiration_count = 0

  puts "--> Starting daily expiration on #{Time.zone.now}"

  Password.where(expired: false).find_each do |push|
    counter += 1
    push.validate!
    expiration_count += 1 if push.expired
  end

  puts "  -> Finished validating #{counter} unexpired password pushes.  #{expiration_count} total pushes expired..."

  if Settings.enable_file_pushes
    counter = 0
    expiration_count = 0
    FilePush.where(expired: false).find_each do |push|
      counter += 1
      push.validate!
      expiration_count += 1 if push.expired
    end
    puts "  -> Finished validating #{counter} unexpired File pushes.  #{expiration_count} total pushes expired..."
  end

  if Settings.enable_url_pushes
    counter = 0
    expiration_count = 0
    Url.where(expired: false).find_each do |push|
      counter += 1
      push.validate!
      expiration_count += 1 if push.expired
    end
    puts "  -> Finished validating #{counter} unexpired URL pushes.  #{expiration_count} total pushes expired..."
  end

  puts "  -> Finished daily expiration on #{Time.zone.now}"
end

# When a Password expires, the payload is deleted but the metadata record still exists.  This
# includes information such as creation date, views, duration etc..  When the record
# was created by an anonymous user, this data is no longer needed and we delete it (we
# don't want it).
#
# If a user attempts to retrieve a secret link that doesn't exist anymore, we still show
# the standard "This secret link has expired" message.  This strategy provides two benefits:
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
desc "Delete expired and anonymous pushes."
task delete_expired_and_anonymous: :environment do
  counter = 0

  puts "--> Starting delete_expired_and_anonymous on #{Time.zone.now}"

  Password.includes(:views)
    .where(expired: true)
    .where(user_id: nil)
    .find_each do |push|
    counter += 1
    push.destroy
  end

  if Settings.enable_file_pushes
    FilePush.includes(:views)
      .where(expired: true)
      .where(user_id: nil)
      .find_each do |push|
      counter += 1
      push.destroy
    end
  end

  if Settings.enable_url_pushes
    Url.includes(:views)
      .where(expired: true)
      .where(user_id: nil)
      .find_each do |push|
      counter += 1
      push.destroy
    end
  end

  puts "  -> #{counter} total anonymous and expired pushes deleted."
  puts "  -> Finished delete_expired_and_anonymous on #{Time.zone.now}"
end

desc "Generate robots.txt."
task generate_robots_txt: :environment do
  include Rails.application.routes.url_helpers
  contents = "User-agent: *\n"
  contents += "Disallow: /p/\n"
  contents += "Disallow: /f/\n"
  contents += "Disallow: /r/\n"
  contents += "Allow: /p/new\n"
  contents += "Allow: /f/new\n"
  contents += "Allow: /r/new\n"
  contents += "Allow: /pages/\n"

  File.write("./public/robots.txt", contents)

  puts ""
  puts "All done.  Bye!  (っ＾▿＾)۶🍸🌟🍺٩(˘◡˘ )"
  puts ""
end

namespace :active_storage do
  desc "Purges unattached Active Storage blobs. Run regularly."
  task purge_unattached: :environment do
    ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at > ?",
      2.days.ago).find_each(&:purge_later)
  end
end

desc "Pull updated themes from Bootswatch."
task update_themes: :environment do
  puts "Updating themes..."

  themes = %w[
    cerulean
    cosmo
    cyborg
    darkly
    flatly
    journal
    litera
    lumen
    lux
    materia
    minty
    morph
    pulse
    quartz
    sandstone
    simplex
    sketchy
    slate
    solar
    spacelab
    superhero
    united
    vapor
    yeti
    zephyr
  ]

  themes.each do |name|
    puts "Pulling #{name}...and sleeping 3 seconds..."
    `curl -s -o app/assets/stylesheets/themes/#{name}.css https://raw.githubusercontent.com/thomaspark/bootswatch/v5/dist/#{name}/bootstrap.css`
    # Be nice - don't hammer the server
    sleep 3
  end
end
