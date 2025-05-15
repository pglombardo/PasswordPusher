# frozen_string_literal: true

# This file contains tasks that are used to migrate data.  It should be removed after the migration is stable
# and proven to be without issue.

namespace :pwpush do
  desc "Run through and validate imported users."
  task migrate_users: :environment do
    User.find_each do |user|
      puts "Processing user: #{user.id}/#{user.email}"

      if user.name.blank?
        # puts "  -> Setting first_name to email for user: #{user.email}"
        user.first_name = user.email

        # Saving this record also creates the default personal account
        raise "Failed to save user: #{user.email}/#{user.errors.full_messages}" unless user.save!
      end

      puts "  -> Creating default account."
      account = user.owned_accounts.create!(name: user.name, personal: false)
      account.account_users.create!(user: user, admin: true)

      if user.authentication_token.present?
        puts "  -> Migrating authentication_token to API token"
        user.api_tokens.create!(name: "Token 1", token: user.authentication_token)
      end
    end
  end

  desc "Migrate Active Passwords to Pushes."
  task migrate_active_passwords_to_pushes: :environment do
    require_relative "../pwpush/migration_tasks"
    include Pwpush::MigrationTasks

    Password.where(expired: false).find_each do |p|
      migrate_to_push(p)
    end
  end

  desc "Migrate Expired Passwords to Pushes."
  task migrate_expired_passwords_to_pushes: :environment do
    require_relative "../pwpush/migration_tasks"
    include Pwpush::MigrationTasks

    Password.where(expired: true).find_each do |p|
      migrate_to_push(p)
    end
  end

  desc "Migrate File Pushes to Pushes."
  task migrate_file_pushes_to_pushes: :environment do
    require_relative "../pwpush/migration_tasks"
    include Pwpush::MigrationTasks

    FilePush.where(expired: true).find_each do |fpush|
      migrate_to_push(fpush)
    end
  end

  desc "Migrate URLs to Pushes."
  task migrate_urls_to_pushes: :environment do
    require_relative "../pwpush/migration_tasks"
    include Pwpush::MigrationTasks

    Url.find_each do |url|
      migrate_to_push(url)
    end
  end
end
