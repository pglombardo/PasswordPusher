class MakeKindRequiredForAuditLogs < ActiveRecord::Migration[7.2]
  def change
    # Make kind required for audit logs
    change_column_null :audit_logs, :kind, false
  end
end
