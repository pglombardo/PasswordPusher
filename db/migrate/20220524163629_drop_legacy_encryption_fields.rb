# frozen_string_literal: true

class DropLegacyEncryptionFields < ActiveRecord::Migration[6.1]
  def change
    remove_column :passwords, :payload_legacy
    remove_column :passwords, :note_legacy
  end
end
