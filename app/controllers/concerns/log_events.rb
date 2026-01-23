module LogEvents
  ##
  # log_view
  #
  # Record that a view is being made for a push
  # If the viewer is the owner or an admin, it won't count towards view limits
  #
  def log_view(push)
    if push.expired
      log_event(push, :failed_view)
    elsif user_signed_in? && current_user.admin?
      # Admin views take precedence over owner views
      log_event(push, :admin_view)
    elsif user_signed_in? && push.user_id == current_user.id
      log_event(push, :owner_view)
    else
      log_event(push, :view)
    end
    push
  end

  def log_creation(push)
    log_event(push, :creation)
  end

  def log_update(push)
    log_event(push, :edit)
  end

  def log_failed_passphrase(push)
    log_event(push, :failed_passphrase)
  end

  def log_expire(push)
    log_event(push, :expire)
  end

  def log_event(push, kind)
    ip = request.env["HTTP_X_FORWARDED_FOR"].blank? ? request.env["REMOTE_ADDR"] : request.env["HTTP_X_FORWARDED_FOR"]

    # Limit retrieved values to 256 characters
    user_agent = request.env["HTTP_USER_AGENT"].to_s[0, 255]
    referrer = request.env["HTTP_REFERER"].to_s[0, 255]

    push.audit_logs.create(kind: kind, user: current_user, ip:, user_agent:, referrer:)
  end
end
