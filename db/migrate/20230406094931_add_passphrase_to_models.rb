# frozen_string_literal: true

class AddPassphraseToModels < ActiveRecord::Migration[7.0]
  def change
    # The column defaults on this migration breaks on MySQL Server.
    # See: https://github.com/pglombardo/PasswordPusher/issues/1002

    add_column :passwords, :passphrase_ciphertext, :text, null: false, default: "", limit: 2048
    add_column :file_pushes, :passphrase_ciphertext, :text, null: false, default: "", limit: 2048
    add_column :urls, :passphrase_ciphertext, :text, null: false, default: "", limit: 2048
  rescue ActiveRecord::StatementInvalid
    # MySQL Server doesn't support column defaults for TEXT columns
    Rails.logger.warn("Failed to add passphrase_ciphertext columns with defaults")
    Rails.logger.warn("This is expected if you are using MySQL")
    add_column :passwords, :passphrase_ciphertext, :text, limit: 2048
    add_column :file_pushes, :passphrase_ciphertext, :text, limit: 2048
    add_column :urls, :passphrase_ciphertext, :text, limit: 2048
  end
end
