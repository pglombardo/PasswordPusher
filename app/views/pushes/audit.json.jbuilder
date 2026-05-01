json.logs @audit_logs do |audit_log|
  json.ip audit_log.ip
  json.user_agent audit_log.user_agent
  json.referrer audit_log.referrer
  json.kind audit_log.kind
  json.created_at audit_log.created_at
  json.updated_at audit_log.updated_at

  if audit_log.kind == "creation_email_send"
    json.notify_by_email do
      json.recipients audit_log.notify_by_email.recipients
      json.locale audit_log.notify_by_email.locale
      json.status audit_log.notify_by_email.status
      json.successful_sends audit_log.notify_by_email.successful_sends
      json.proceed_at audit_log.notify_by_email.proceed_at
    end
  end
end
