class MigrateDataToPushModel < ActiveRecord::Migration[7.2]
  def up
    # Migrate data from Password model to Push model
    migrate_passwords
    
    # Migrate data from FilePush model to Push model
    migrate_file_pushes
    
    # Migrate data from Url model to Push model
    migrate_urls
    
    # Migrate views to audit_logs
    migrate_views
  end
  
  def down
    # It is not necessary to make this migration reversible
  end
  
  private
  
  # Password migration methods
  def migrate_passwords
    puts "Migrating passwords to pushes..."
    
    Password.where(expired: false).find_each do |password|
      begin
        push = create_push_from_password(password)
        
        if push.save(validate: false)
          create_audit_log_for_push(push, password.user_id, password.created_at)
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
          create_audit_log_for_push(push, file_push.user_id, file_push.created_at)
          migrate_file_attachments(file_push, push)
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
    file_push.files.each do |file|
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
          create_audit_log_for_push(push, url.user_id, url.created_at)
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
  def create_audit_log_for_push(push, user_id, created_at)
    AuditLog.create!(
      kind: :creation,
      push: push,
      user_id: user_id,
      created_at: created_at,
      updated_at: created_at,
      referrer: "",
      user_agent: ""
    )
  end
  
  # View migration methods
  def migrate_views
    puts "Migrating views to audit logs..."
    
    View.find_each do |view|
      push_id = find_push_id_for_view(view)
      
      if push_id.present?
        create_audit_log_from_view(view, push_id)
      else
        puts "Could not find corresponding push for view #{view.id}"
      end
    end
  end
  
  def find_push_id_for_view(view)
    if view.password_id.present?
      find_push_id_by_source_record(Password, view.password_id)
    elsif view.file_push_id.present?
      find_push_id_by_source_record(FilePush, view.file_push_id)
    elsif view.url_id.present?
      find_push_id_by_source_record(Url, view.url_id)
    end
  end
  
  def find_push_id_by_source_record(model_class, record_id)
    source_record = model_class.find_by(id: record_id)
    return nil unless source_record
    
    push = Push.find_by(url_token: source_record.url_token)
    push&.id
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
