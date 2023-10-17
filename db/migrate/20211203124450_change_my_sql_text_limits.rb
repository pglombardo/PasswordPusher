# frozen_string_literal: true

class ChangeMySqlTextLimits < ActiveRecord::Migration[6.1]
  def change
    # MySQL defaults to the smallest test field type.  Set a limit of about ~16MB so MEDIUMTEXT is used
    change_column :passwords, :payload_ciphertext, :text, limit: 16.megabytes - 1
  end
end
