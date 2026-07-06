module Pwpush::AssignNotifiableByEmailFields
  extend ActiveSupport::Concern

  def assign_notify_by_email_fields(record, required:)
    record.notify_by_email_creator = current_user if user_signed_in?
    record.notify_emails_to_required = required
  end
end
