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
  
  def migrate_passwords
    puts "Migrating passwords to pushes..."
    
    Password.find_each do |password|
      begin
        # Create a new Push record
        push = Push.new(
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
        
        # Skip validation that causes decryption
        # push.define_singleton_method(:check_payload_for_text) { true }
        
        if push.save(validate: false)
          # Create an audit log for the creation
          AuditLog.create!(
            kind: :creation,
            push: push,
            user_id: password.user_id,
            created_at: password.created_at,
            updated_at: password.created_at,
            referrer: "",
            user_agent: ""
          )
          
          puts "Migrated password #{password.id} to push #{push.id}"
        else
          puts "Failed to migrate password #{password.id}: #{push.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "Error migrating password #{password.id}: #{e.message}"
      end
    end
  end
  
  def migrate_file_pushes
    puts "Migrating file pushes to pushes..."
    
    FilePush.find_each do |file_push|
      begin
        # Create a new Push record
        push = Push.new(
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
        
        # Skip validation that causes decryption
        # push.define_singleton_method(:check_files_for_file) { true }
        
        if push.save(validate: false)
          # Create an audit log for the creation
          AuditLog.create!(
            kind: :creation,
            push: push,
            user_id: file_push.user_id,
            created_at: file_push.created_at,
            updated_at: file_push.created_at,
            referrer: "",
            user_agent: ""
          )
          
          # Migrate attached files by updating existing attachments
          file_push.files.each do |file|
            # Update the existing attachment record to point to the new Push
            file.update!(
              record_type: 'Push',
              record_id: push.id
            )
          end
          
          puts "Migrated file push #{file_push.id} to push #{push.id}"
        else
          puts "Failed to migrate file push #{file_push.id}: #{push.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "Error migrating file push #{file_push.id}: #{e.message}"
      end
    end
  end
  
  def migrate_urls
    puts "Migrating urls to pushes..."
    
    Url.find_each do |url|
      begin
        # Create a new Push record
        push = Push.new(
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
        
        # Skip validation that causes decryption
        # push.define_singleton_method(:check_payload_for_url) { true }
        
        if push.save(validate: false)
          # Create an audit log for the creation
          AuditLog.create!(
            kind: :creation,
            push: push,
            user_id: url.user_id,
            created_at: url.created_at,
            updated_at: url.created_at,
            referrer: "",
            user_agent: ""
          )
          
          puts "Migrated url #{url.id} to push #{push.id}"
        else
          puts "Failed to migrate url #{url.id}: #{push.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "Error migrating url #{url.id}: #{e.message}"
      end
    end
  end
  
  def migrate_views
    puts "Migrating views to audit logs..."
    
    View.find_each do |view|
      # Determine the associated push based on the view's associations
      push_id = nil
      if view.password_id.present?
        # Find the corresponding push by url_token
        password = Password.find_by(id: view.password_id)
        if password
          push = Push.find_by(url_token: password.url_token)
          push_id = push&.id
        end
      elsif view.file_push_id.present?
        # Find the corresponding push by url_token
        file_push = FilePush.find_by(id: view.file_push_id)
        if file_push
          push = Push.find_by(url_token: file_push.url_token)
          push_id = push&.id
        end
      elsif view.url_id.present?
        # Find the corresponding push by url_token
        url = Url.find_by(id: view.url_id)
        if url
          push = Push.find_by(url_token: url.url_token)
          push_id = push&.id
        end
      end
      
      if push_id.present?
        # Determine the kind of audit log based on the view's kind and successful attributes
        audit_log_kind = determine_audit_log_kind(view)
        
        # Create a new AuditLog record
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
      else
        puts "Could not find corresponding push for view #{view.id}"
      end
    end
  end
  
  # Determine the appropriate audit log kind based on view kind and successful status
  def determine_audit_log_kind(view)
    # Standard view (kind 0)
    if view.kind == 0
      view.successful ? :view : :failed_view
    # Admin view (kind 1) - these are typically just views, not failures
    elsif view.kind == 1
      :expire
    end
  end
end
