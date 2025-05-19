module Pwpush::MigrationTasks
  def migrate_to_push(lp)
    # Skip if we've already migrated this push
    if Push.where(url_token: lp.url_token).exists?
      puts "  -> Skipping already migrated password: #{lp.id}/#{lp.url_token}"
      return
    end

    puts "  -> Migrating #{lp.expired ? "expired" : "active"} #{lp.class.name}: #{lp.id}/#{lp.url_token}"

    # Create the new Push record
    push = Push.new(
      user: lp.user,
      url_token: lp.url_token,
      expire_after_views: lp.expire_after_views,
      expire_after_days: lp.expire_after_days,
      retrieval_step: lp.retrieval_step,
      expired: lp.expired,
      expired_on: lp.expired_on,
      payload: lp.payload,
      note: lp.note,
      passphrase: lp.passphrase,
      created_at: lp.created_at,
      updated_at: lp.updated_at
    )

    if lp.is_a?(Password)
      push.kind = "password"
    elsif lp.is_a?(FilePush)
      push.kind = "file"
    elsif lp.is_a?(Url)
      push.kind = "url"
    else
      raise "Unknown push kind: #{lp.id}/#{lp.class.name}"
    end

    if lp.respond_to?(:deletable_by_viewer)
      push.deletable_by_viewer = lp.deletable_by_viewer
    end

    push.update_expire_at
    raise "Failed to save push: #{push.url_token}/#{push.errors.full_messages}" unless push.save!

    migrate_views_for_push(push, lp.views, lp.user)
  end

  def migrate_views_for_push(push, views, user)
    # Make the creation Audit Log for this push
    log = AuditLog.new(push: push,
      user: user,
      kind: :creation,
      created_at: push.created_at,
      updated_at: push.updated_at)

    raise "Failed to save audit log: #{log.errors.full_messages}" unless log.save!

    # Migrate the views for this push
    views.each do |v|
      if v.kind == 0
        target_kind = v.successful ? :view : :failed_view
      elsif v.kind == 1
        target_kind = :expire
      else
        raise "Unknown source view kind: #{v.id}/#{v.kind}"
      end

      log = AuditLog.new(
        push: push,
        kind: target_kind,
        ip: v.ip,
        user_agent: v.user_agent,
        referrer: v.referrer,
        user_id: v.user_id,
        created_at: v.created_at,
        updated_at: v.updated_at
      )
      raise "Failed to save audit log: #{v.id}/#{log.errors.full_messages}" unless log.save!
    rescue ActiveRecord::InvalidForeignKey
      puts "  -> Skipping view with invalid user_id: #{v.id}/#{v.user_id}"
    end
  end
end
