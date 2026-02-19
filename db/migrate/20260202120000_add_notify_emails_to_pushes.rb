# frozen_string_literal: true

class AddNotifyEmailsToPushes < ActiveRecord::Migration[8.1]
  def change
    add_column :pushes, :notify_emails_to, :text
    add_column :pushes, :notify_emails_to_locale, :string
  end
end
