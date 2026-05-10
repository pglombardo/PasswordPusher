# frozen_string_literal: true

class RemoveNotifyEmailsToFromPushes < ActiveRecord::Migration[8.1]
  def change
    remove_column :pushes, :notify_emails_to_ciphertext, :text, if_exists: true
    remove_column :pushes, :notify_emails_to_locale_ciphertext, :string, if_exists: true
  end
end
