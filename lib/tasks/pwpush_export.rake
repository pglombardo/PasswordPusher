# frozen_string_literal: true

namespace :pwpush do
  desc "Export all data for migration to Password Pusher Pro"
  task export: :environment do
    puts ""
    puts "=" * 60
    puts "Password Pusher OSS -> Pro Migration Export"
    puts "=" * 60
    puts ""

    export_path = Rails.root.join("tmp", "pwpush_export_#{Time.current.strftime("%Y%m%d_%H%M%S")}.json")

    puts "Gathering data..."
    puts ""

    data = {
      meta: {
        exported_from: Settings.version,
        exported_at: Time.current.iso8601,
        schema_version: 1,
        storage_backend: Settings.files.storage,
        record_counts: {
          users: User.count,
          pushes: Push.count,
          audit_logs: AuditLog.count,
          active_storage_blobs: ActiveStorage::Blob.count,
          active_storage_attachments: ActiveStorage::Attachment.count
        }
      },
      users: [],
      pushes: [],
      audit_logs: [],
      active_storage_blobs: [],
      active_storage_attachments: []
    }

    # Export Users (exclude authentication_token; API tokens are not migrated)
    puts "Exporting #{User.count} users..."
    User.find_each do |user|
      data[:users] << user.attributes.except("authentication_token")
    end

    # Export Pushes (includes ciphertext fields)
    puts "Exporting #{Push.count} pushes..."
    Push.find_each do |push|
      data[:pushes] << push.attributes
    end

    # Export Audit Logs
    puts "Exporting #{AuditLog.count} audit logs..."
    AuditLog.find_each do |audit_log|
      data[:audit_logs] << audit_log.attributes
    end

    # Export Active Storage Blobs
    puts "Exporting #{ActiveStorage::Blob.count} active storage blobs..."
    ActiveStorage::Blob.find_each do |blob|
      data[:active_storage_blobs] << blob.attributes
    end

    # Export Active Storage Attachments
    puts "Exporting #{ActiveStorage::Attachment.count} active storage attachments..."
    ActiveStorage::Attachment.find_each do |attachment|
      data[:active_storage_attachments] << attachment.attributes
    end

    # Write JSON file
    File.write(export_path, JSON.pretty_generate(data))

    puts ""
    puts "=" * 60
    puts "Export Complete!"
    puts "=" * 60
    puts ""
    puts "Export file: #{export_path}"
    puts "Storage backend: #{data[:meta][:storage_backend]}"
    puts ""
    puts "Record counts:"
    data[:meta][:record_counts].each do |key, count|
      puts "  - #{key}: #{count}"
    end
    puts ""
    puts "NEXT STEPS:"
    puts "-" * 60
    puts "1. Copy this JSON file to your Pro instance"
    puts ""
    puts "2. Ensure Pro is configured with the same storage backend:"
    puts "   Storage backend: #{data[:meta][:storage_backend]}"
    case data[:meta][:storage_backend]
    when "local"
      puts "   -> Mount your OSS storage volume to the Pro container"
      puts "      (e.g., same path as /rails/storage)"
    when "amazon", "minio", "backblaze_b2", "cloudflare_r2", "digitalocean_spaces", "linode_object_storage", "wasabi"
      puts "   -> Configure Pro with the same S3-compatible credentials and bucket"
    when "google"
      puts "   -> Configure Pro with the same Google Cloud Storage credentials and bucket"
    when "microsoft"
      puts "   -> Configure Pro with the same Azure Blob Storage credentials and container"
    end
    puts ""
    puts "3. Run the import task in Password Pusher Pro:"
    puts "   bin/rails 'pwpush:import[/path/to/export.json,YOUR-OSS-MASTER-KEY]'"
    puts ""
    puts "   Your OSS master (encryption) key for this instance:"
    puts "   #{Lockbox.master_key}"
    puts ""
    puts "   Use this value as YOUR-OSS-MASTER-KEY (decrypts and re-encrypts push payloads)."
    puts ""
    puts "Documentation: https://docs.pwpush.com/docs/migrate-oss-to-pro/"
    puts ""
    puts "=" * 60
  end
end
