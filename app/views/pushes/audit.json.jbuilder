json.logs @audit_logs do |audit_log|
  json.ip audit_log.ip
  json.user_agent audit_log.user_agent
  json.referrer audit_log.referrer
  json.kind audit_log.kind

  if audit_log.kind == "creation_email_send"
    json.notify_by_email_locale audit_log.notify_by_email.locale
    json.notify_by_email_recipients audit_log.notify_by_email.recipients
    json.notify_by_email_status audit_log.notify_by_email.status
    json.notify_by_email_successful_sends audit_log.notify_by_email.successful_sends
    json.notify_by_email_proceed_at audit_log.notify_by_email.proceed_at
  end

  json.created_at audit_log.created_at
  json.updated_at audit_log.updated_at
end
