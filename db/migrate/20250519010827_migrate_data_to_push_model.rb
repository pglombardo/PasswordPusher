class MigrateDataToPushModel < ActiveRecord::Migration[7.2]
  def up
    MigrateDataToPushModelJob.perform_later
  end

  def down
    attach_files_to_old_records
    remove_all_audit_logs
    remove_all_pushes
  end

  private

  def remove_all_pushes
    Push.delete_all
  end

  def remove_all_audit_logs
    AuditLog.delete_all
  end

  def attach_files_to_old_records
    Push.where(kind: Push.kinds[:file]).find_each do |push|
      file_push = FilePush.find_by(url_token: push.url_token)
      if file_push
        push.files.attachments.each do |attachment|
          attachment.update!(record_type: FilePush.name, record: file_push)
        end
      else
        puts "Warning: FilePush not found for push #{push.id} (url_token: #{push.url_token}) during rollback. Cannot reattach files."
      end
    rescue => e
      # Consider if this error should halt the rollback. Currently, it logs and continues.
      puts "Error reverting attachments for push #{push.id} (url_token: #{push.url_token}): #{e.message}"
    end
  end
end
