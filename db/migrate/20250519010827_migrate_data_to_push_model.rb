class MigrateDataToPushModel < ActiveRecord::Migration[7.2]
  def up
    # Migrate data from Password model to Push model
    migrate_passwords
    
    # Migrate data from FilePush model to Push model
    migrate_file_pushes
    
    # Migrate data from Url model to Push model
    migrate_urls
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
    
    Password.where(expired: false).find_each do |password|
      begin
        push = create_push_from_password(password)
        
        if push.save(validate: false)
          create_audit_log_for_push(password, push)
          migrate_views(password, push)
          puts "Migrated password #{password.id} to push #{push.id}"
        else
          puts "Failed to migrate password #{password.id}: #{push.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "Error migrating password #{password.id}: #{e.message}"
      end
    end
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
    
    FilePush.where(expired: false).find_each do |file_push|
      begin
        push = create_push_from_file_push(file_push)
        
        if push.save(validate: false)
          create_audit_log_for_push(file_push, push)
          migrate_file_attachments(file_push, push)
          migrate_views(file_push, push)
          puts "Migrated file push #{file_push.id} to push #{push.id}"
        else
          puts "Failed to migrate file push #{file_push.id}: #{push.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "Error migrating file push #{file_push.id}: #{e.message}"
      end
    end
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
    
    Url.where(expired: false).find_each do |url|
      begin
        push = create_push_from_url(url)
        
        if push.save(validate: false)
          create_audit_log_for_push(url, push)
          migrate_views(url, push)
          puts "Migrated url #{url.id} to push #{push.id}"
        else
          puts "Failed to migrate url #{url.id}: #{push.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "Error migrating url #{url.id}: #{e.message}"
      end
    end
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
  def create_audit_log_for_push(old_push_record, new_push_record)
    AuditLog.create!(
      kind: :creation,
      push: new_push_record,
      user_id: old_push_record.user_id,
      created_at: old_push_record.created_at,
      updated_at: old_push_record.updated_at,
      referrer: "",
      user_agent: ""
    )
  end
  
  # View migration methods
  def migrate_views(old_push_record, new_push_record)
    puts "Migrating views to audit logs..."
    
    old_push_record.views.find_each do |view|
      create_audit_log_from_view(view, new_push_record.id)
    end
  end
  

  def create_audit_log_from_view(view, push_id)
    audit_log_kind = determine_audit_log_kind(view)
    
    audit_log = AuditLog.new(
      kind: audit_log_kind,
      push_id: push_id,
      user_id: view.user_id,
      ip: view.ip,
      user_agent: view.user_agent || "",
      referrer: view.referrer || "",
      created_at: view.created_at,
      updated_at: view.updated_at
    )
    
    if audit_log.save
      puts "Migrated view #{view.id} to audit log #{audit_log.id}"
    else
      puts "Failed to migrate view #{view.id}: #{audit_log.errors.full_messages.join(', ')}"
    end
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
