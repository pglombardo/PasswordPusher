class MigrateDataToPushModel < ActiveRecord::Migration[7.2]
  def up
    # Migrate data from Password model to Push model
    migrate_passwords

    # Migrate data from FilePush model to Push model
    migrate_file_pushes

    # Migrate data from Url model to Push model
    migrate_urls

    # Migrate views to audit logs
    migrate_views
  end

  def down
    attach_files_to_old_records
    remove_all_audit_logs
    remove_all_pushes
  end

  private

  def remove_all_pushes
    Push.delete_all
  end

  def remove_all_audit_logs
    AuditLog.delete_all
  end

  def attach_files_to_old_records
    Push.where(kind: Push.kinds[:file]).find_each do |push|
      file_push = FilePush.find_by(url_token: push.url_token)
      if file_push
        push.files.attachments.each do |attachment|
          attachment.update!(record_type: FilePush.name, record: file_push)
        end
      else
        puts "Warning: FilePush not found for push #{push.id} (url_token: #{push.url_token}) during rollback. Cannot reattach files."
      end
    rescue => e
      # Consider if this error should halt the rollback. Currently, it logs and continues.
      puts "Error reverting attachments for push #{push.id} (url_token: #{push.url_token}): #{e.message}"
    end
  end

  # Password migration methods
  def migrate_passwords
    successful_password_count = 0
    failed_password_count = 0
    total_count = Password.count
    batch_size = 1000

    puts "Migrating #{total_count} passwords to pushes..."

    Password.find_each(batch_size: batch_size) do |password|
      push = create_push_from_password(password)

      if push.save(validate: false)
        create_audit_log_for(push)
        successful_password_count += 1
      else
        puts "Failed to migrate password #{password.id}: #{push.errors.full_messages.join(", ")}"
        failed_password_count += 1
      end

      # Print progress after each batch
      if (successful_password_count + failed_password_count) % batch_size == 0
        current_batch = (successful_password_count + failed_password_count) / batch_size
        total_batches = (total_count.to_f / batch_size).ceil
        puts "Batch #{current_batch}/#{total_batches} (#{successful_password_count + failed_password_count}/#{total_count})"
      end
    rescue => e
      puts "Error migrating password #{password.id}: #{e.message}"
      failed_password_count += 1
    end

    puts "\nSuccessfully migrated #{successful_password_count} passwords to pushes."
    puts "Failed to migrate #{failed_password_count} passwords to pushes." if failed_password_count > 0
  end

  def create_push_from_password(password)
    Push.new(
      kind: :text,
      expire_after_days: password.expire_after_days,
      expire_after_views: password.expire_after_views,
      expired: password.expired,
      url_token: password.url_token,
      deletable_by_viewer: password.deletable_by_viewer,
      retrieval_step: password.retrieval_step,
      expired_on: password.expired_on,
      payload: password.payload,
      note: password.note,
      passphrase: password.passphrase,
      name: password.name,
      user: password.user,
      created_at: password.created_at,
      updated_at: password.updated_at
    )
  end

  # FilePush migration methods
  def migrate_file_pushes
    successful_file_push_count = 0
    failed_file_push_count = 0
    total_count = FilePush.count
    batch_size = 1000

    puts "Migrating #{total_count} file pushes to pushes..."

    FilePush.find_each(batch_size: batch_size) do |file_push|
      push = create_push_from_file_push(file_push)

      if push.save(validate: false)
        create_audit_log_for(push)
        migrate_file_attachments(file_push, push)
        successful_file_push_count += 1
      else
        puts "Failed to migrate file push #{file_push.id}: #{push.errors.full_messages.join(", ")}"
        failed_file_push_count += 1
      end

      # Print progress after each batch
      if (successful_file_push_count + failed_file_push_count) % batch_size == 0
        current_batch = (successful_file_push_count + failed_file_push_count) / batch_size
        total_batches = (total_count.to_f / batch_size).ceil
        puts "Batch #{current_batch}/#{total_batches} (#{successful_file_push_count + failed_file_push_count}/#{total_count})"
      end
    rescue => e
      puts "Error migrating file push #{file_push.id}: #{e.message}"
      failed_file_push_count += 1
    end

    puts "\nSuccessfully migrated #{successful_file_push_count} file pushes to pushes."
    puts "Failed to migrate #{failed_file_push_count} file pushes to pushes." if failed_file_push_count > 0
  end

  def create_push_from_file_push(file_push)
    Push.new(
      kind: :file,
      expire_after_days: file_push.expire_after_days,
      expire_after_views: file_push.expire_after_views,
      expired: file_push.expired,
      url_token: file_push.url_token,
      deletable_by_viewer: file_push.deletable_by_viewer,
      retrieval_step: file_push.retrieval_step,
      expired_on: file_push.expired_on,
      payload: file_push.payload,
      note: file_push.note,
      passphrase: file_push.passphrase,
      name: file_push.name,
      user: file_push.user,
      created_at: file_push.created_at,
      updated_at: file_push.updated_at
    )
  end

  def migrate_file_attachments(file_push, push)
    file_push.files.attachments.each do |attachment|
      attachment.update!(
        record_type: Push.name,
        record: push
      )
    end
  end

  # URL migration methods
  def migrate_urls
    successful_url_count = 0
    failed_url_count = 0
    total_count = Url.count
    batch_size = 1000

    puts "Migrating #{total_count} urls to pushes..."

    Url.find_each(batch_size: batch_size) do |url|
      push = create_push_from_url(url)

      if push.save(validate: false)
        create_audit_log_for(push)
        successful_url_count += 1
      else
        puts "Failed to migrate url #{url.id}: #{push.errors.full_messages.join(", ")}"
        failed_url_count += 1
      end

      # Print progress after each batch
      if (successful_url_count + failed_url_count) % batch_size == 0
        current_batch = (successful_url_count + failed_url_count) / batch_size
        total_batches = (total_count.to_f / batch_size).ceil
        puts "Batch #{current_batch}/#{total_batches} (#{successful_url_count + failed_url_count}/#{total_count})"
      end
    rescue => e
      puts "Error migrating url #{url.id}: #{e.message}"
      failed_url_count += 1
    end

    puts "\nSuccessfully migrated #{successful_url_count} urls to pushes."
    puts "Failed to migrate #{failed_url_count} urls to pushes." if failed_url_count > 0
  end

  def create_push_from_url(url)
    Push.new(
      kind: :url,
      expire_after_days: url.expire_after_days,
      expire_after_views: url.expire_after_views,
      expired: url.expired,
      url_token: url.url_token,
      deletable_by_viewer: nil, # URLs cannot be preemptively deleted by end users ever
      retrieval_step: url.retrieval_step,
      expired_on: url.expired_on,
      payload: url.payload,
      note: url.note,
      passphrase: url.passphrase,
      name: url.name,
      user: url.user,
      created_at: url.created_at,
      updated_at: url.updated_at
    )
  end

  # Common method for creating audit logs
  def create_audit_log_for(new_push_record)
    AuditLog.create!(
      kind: :creation,
      push: new_push_record,
      user: new_push_record.user,
      created_at: new_push_record.created_at,
      updated_at: new_push_record.updated_at,
      referrer: "",
      user_agent: ""
    )
  end

  # Views migration method
  def migrate_views
    successful_view_count = 0
    failed_view_count = 0
    total_count = View.count
    batch_size = 1000

    puts "Migrating #{total_count} views to audit logs..."

    View.find_each(batch_size: batch_size) do |view|
      original_push = nil
      if view.file_push_id
        original_push = view.file_push
      elsif view.password_id
        original_push = view.password
      elsif view.url_id
        original_push = view.url
      end

      unless original_push
        raise ActiveRecord::RecordNotFound, "Original record (Password/FilePush/Url) not found for View##{view.id}. Skipping audit log creation."
      end

      # Find the newly created Push record using the url_token from the original record
      push = Push.find_by(url_token: original_push.url_token)

      unless push
        raise "Corresponding Push record not found for original #{original_push.class.name}##{original_push.id} (url_token: #{original_push.url_token}). Skipping audit log creation."
      end

      create_audit_log_from_view(view, push)
      successful_view_count += 1

      # Print progress after each batch
      if (successful_view_count + failed_view_count) % batch_size == 0
        current_batch = (successful_view_count + failed_view_count) / batch_size
        total_batches = (total_count.to_f / batch_size).ceil
        puts "Batch #{current_batch}/#{total_batches} (#{successful_view_count + failed_view_count}/#{total_count})"
      end
    rescue => e
      failed_view_count += 1
      puts "Failed to migrate view #{view.id} to audit log: #{e.message}"
    end

    puts "\nSuccessfully migrated #{successful_view_count} views to audit logs."
    puts "Failed to migrate #{failed_view_count} views to audit logs." if failed_view_count > 0
  end

  # Create audit logs from views
  def create_audit_log_from_view(view, push)
    audit_log_kind = determine_audit_log_kind(view)

    audit_log = AuditLog.new(
      kind: audit_log_kind,
      push: push,
      user: view.user,
      ip: view.ip,
      user_agent: view.user_agent || "",
      referrer: view.referrer || "",
      created_at: view.created_at,
      updated_at: view.updated_at
    )

    audit_log.save!
  end

  # Determine the appropriate audit log kind based on view kind and successful status
  def determine_audit_log_kind(view)
    if view.kind == 0
      view.successful ? :view : :failed_view
    elsif view.kind == 1
      :expire
    else
      puts "Warning: Unknown view kind: #{view.kind} for View##{view.id}. Defaulting audit log kind to :unknown_event."
      :unknown_event # Or raise an error, depending on desired strictness
    end
  end
end
