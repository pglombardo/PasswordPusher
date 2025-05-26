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
  end
  
  private

  def attach_files_to_old_records
    Push.where(kind: "file", expired: false).find_each do |push|
      begin 
        file_push = FilePush.find_by(url_token: push.url_token)
        if file_push
          push.files.attachments.each do |attachment|
            attachment.update!(record_type: "FilePush", record_id: file_push.id)
          end
        else
          puts "FilePush not found for push #{push.id} and url_token #{push.url_token}"
        end
      rescue => e
        puts "Error migrating attachments of push #{file_push.id} having 'file' kind: #{e.message}"
      end
    end
  end
  
  # Password migration methods
  def migrate_passwords
    puts "Migrating passwords to pushes..."
    successful_password_count = 0
    failed_password_count = 0
    Password.where(expired: false).find_each do |password|
      begin
        push = create_push_from_password(password)
        
        if push.save(validate: false)
          create_audit_log_for(push)
          successful_password_count += 1
        else
          puts "Failed to migrate password #{password.id}: #{push.errors.full_messages.join(', ')}"
          failed_password_count += 1
        end
      rescue => e
        puts "Error migrating password #{password.id}: #{e.message}"
        failed_password_count += 1
      end
    end
    puts "Successfully migrated #{successful_password_count} passwords to pushes."
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
      user_id: password.user_id,
      created_at: password.created_at,
      updated_at: password.updated_at
    )
  end
  
  # FilePush migration methods
  def migrate_file_pushes
    puts "Migrating file pushes to pushes..."
    successful_file_push_count = 0
    failed_file_push_count = 0

    FilePush.where(expired: false).find_each do |file_push|
      begin
        push = create_push_from_file_push(file_push)
        
        if push.save(validate: false)
          create_audit_log_for(push)
          migrate_file_attachments(file_push, push)
          successful_file_push_count += 1
        else
          puts "Failed to migrate file push #{file_push.id}: #{push.errors.full_messages.join(', ')}"
          failed_file_push_count += 1
        end
      rescue => e
        puts "Error migrating file push #{file_push.id}: #{e.message}"
        failed_file_push_count += 1
      end
    end
    puts "Successfully migrated #{successful_file_push_count} file pushes to pushes."
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
      user_id: file_push.user_id,
      created_at: file_push.created_at,
      updated_at: file_push.updated_at
    )
  end
  
  def migrate_file_attachments(file_push, push)
    # Migrate attached files by updating existing attachments
    file_push.files.each do |file|
      # Update the existing attachment record to point to the new Push
      file.update!(
        record_type: 'Push',
        record_id: push.id
      )
    end
  end
  
  # URL migration methods
  def migrate_urls
    puts "Migrating urls to pushes..."
    successful_url_count = 0
    failed_url_count = 0

    Url.where(expired: false).find_each do |url|
      begin
        push = create_push_from_url(url)
        
        if push.save(validate: false)
          create_audit_log_for(push)
          successful_url_count += 1
        else
          puts "Failed to migrate url #{url.id}: #{push.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "Error migrating url #{url.id}: #{e.message}"
        failed_url_count += 1
      end
    end
    puts "Successfully migrated #{successful_url_count} urls to pushes."
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
      user_id: url.user_id,
      created_at: url.created_at,
      updated_at: url.updated_at
    )
  end
  
  # Common method for creating audit logs
  def create_audit_log_for(new_push_record)
    AuditLog.create!(
      kind: :creation,
      push: new_push_record,
      user_id: new_push_record.user_id,
      created_at: new_push_record.created_at,
      updated_at: new_push_record.updated_at,
      referrer: "",
      user_agent: ""
    )
  end
  
  # Views migration method
  def migrate_views
    puts "Migrating views to audit logs..."
    successful_view_count = 0
    failed_view_count = 0

    View.find_each do |view|
      begin
        if view.file_push_id
          push = view.file_push
        elsif view.password_id
          push = view.password
        elsif view.url_id
          push = view.url
        else
          raise ActiveRecord::RecordNotFound
        end
        
        create_audit_log_from_view(view, push)
        successful_view_count += 1
      rescue => exception
        failed_view_count += 1
        puts "Failed to migrate view #{view.id}: #{exception.message}"
      end
    end
    
    puts "Successfully migrated #{successful_view_count} views to audit logs."
    puts "Failed to migrate #{failed_view_count} views to audit logs." if failed_view_count > 0
  end
  
  # Create audit logs from views
  def create_audit_log_from_view(view, push)
    audit_log_kind = determine_audit_log_kind(view)
    
    audit_log = AuditLog.new(
      kind: audit_log_kind,
      push_id: push.id,
      user_id: view.user_id,
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
    end
  end
end
