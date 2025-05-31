class MigrateDataToPushModelJob < ApplicationJob
  queue_as :default

  def perform
    # Migrate data from Password model to Push model
    migrate_passwords

    # Migrate data from FilePush model to Push model
    migrate_file_pushes

    # Migrate data from Url model to Push model
    migrate_urls
  end

  private

  def migrate_passwords
    successful_password_count = 0
    failed_password_count = 0
    total_count = Password.count
    batch_size = 1000

    Rails.logger.info "Migrating #{total_count} passwords to pushes..."

    Password.includes(:views, :user).find_each(batch_size: batch_size) do |password|
      push = create_push_from_password(password)

      if push.save(validate: false)
        create_creation_audit_log_for(push)
        password.views.each do |view|
          create_audit_log_from_view(view, push)
        end
        successful_password_count += 1
      else
        Rails.logger.error "Failed to migrate password #{password.id}: #{push.errors.full_messages.join(", ")}"
        failed_password_count += 1
      end

      # Log progress after each batch
      if (successful_password_count + failed_password_count) % batch_size == 0
        current_batch = (successful_password_count + failed_password_count) / batch_size
        total_batches = (total_count.to_f / batch_size).ceil
        Rails.logger.info "Batch #{current_batch}/#{total_batches} (#{successful_password_count + failed_password_count}/#{total_count})"
      end
    rescue => e
      Rails.logger.error "Error migrating password #{password.id}: #{e.message}"
      failed_password_count += 1
    end

    Rails.logger.info "Successfully migrated #{successful_password_count} passwords to pushes."
    Rails.logger.info "Failed to migrate #{failed_password_count} passwords to pushes." if failed_password_count > 0
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

  def migrate_file_pushes
    successful_file_push_count = 0
    failed_file_push_count = 0
    total_count = FilePush.count
    batch_size = 1000

    Rails.logger.info "Migrating #{total_count} file pushes to pushes..."

    FilePush.includes(:views, :user).find_each(batch_size: batch_size) do |file_push|
      push = create_push_from_file_push(file_push)

      if push.save(validate: false)
        create_creation_audit_log_for(push)
        migrate_file_attachments(file_push, push)
        file_push.views.each do |view|
          create_audit_log_from_view(view, push)
        end
        successful_file_push_count += 1
      else
        Rails.logger.error "Failed to migrate file push #{file_push.id}: #{push.errors.full_messages.join(", ")}"
        failed_file_push_count += 1
      end

      # Log progress after each batch
      if (successful_file_push_count + failed_file_push_count) % batch_size == 0
        current_batch = (successful_file_push_count + failed_file_push_count) / batch_size
        total_batches = (total_count.to_f / batch_size).ceil
        Rails.logger.info "Batch #{current_batch}/#{total_batches} (#{successful_file_push_count + failed_file_push_count}/#{total_count})"
      end
    rescue => e
      Rails.logger.error "Error migrating file push #{file_push.id}: #{e.message}"
      failed_file_push_count += 1
    end

    Rails.logger.info "Successfully migrated #{successful_file_push_count} file pushes to pushes."
    Rails.logger.info "Failed to migrate #{failed_file_push_count} file pushes to pushes." if failed_file_push_count > 0
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

  def migrate_urls
    successful_url_count = 0
    failed_url_count = 0
    total_count = Url.count
    batch_size = 1000

    Rails.logger.info "Migrating #{total_count} urls to pushes..."

    Url.includes(:views, :user).find_each(batch_size: batch_size) do |url|
      push = create_push_from_url(url)

      if push.save(validate: false)
        create_creation_audit_log_for(push)
        url.views.each do |view|
          create_audit_log_from_view(view, push)
        end
        successful_url_count += 1
      else
        Rails.logger.error "Failed to migrate url #{url.id}: #{push.errors.full_messages.join(", ")}"
        failed_url_count += 1
      end

      # Log progress after each batch
      if (successful_url_count + failed_url_count) % batch_size == 0
        current_batch = (successful_url_count + failed_url_count) / batch_size
        total_batches = (total_count.to_f / batch_size).ceil
        Rails.logger.info "Batch #{current_batch}/#{total_batches} (#{successful_url_count + failed_url_count}/#{total_count})"
      end
    rescue => e
      Rails.logger.error "Error migrating url #{url.id}: #{e.message}"
      failed_url_count += 1
    end

    Rails.logger.info "Successfully migrated #{successful_url_count} urls to pushes."
    Rails.logger.info "Failed to migrate #{failed_url_count} urls to pushes." if failed_url_count > 0
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

  def create_creation_audit_log_for(new_push_record)
    AuditLog.create!(
      kind: :creation,
      push: new_push_record,
      user: new_push_record.user,
      created_at: new_push_record.created_at,
      updated_at: new_push_record.updated_at,
      ip: "127.0.0.1",
      referrer: "None",
      user_agent: "None"
    )
  end

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

  def determine_audit_log_kind(view)
    if view.kind == 0
      view.successful ? :view : :failed_view
    elsif view.kind == 1
      :expire
    else
      Rails.logger.warn "Unknown view kind: #{view.kind} for View##{view.id}. Defaulting audit log kind to :unknown_event."
      :unknown_event
    end
  end
end
