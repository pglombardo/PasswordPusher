class FixPassphraseDefault < ActiveRecord::Migration[7.0]
  def change
    begin
      # Add ability to set null values
      change_column_null(:passwords,   :passphrase_ciphertext, true)
      change_column_null(:file_pushes, :passphrase_ciphertext, true)
      change_column_null(:urls,        :passphrase_ciphertext, true)
    rescue ActiveRecord::StatementInvalid => e
      # This will fail because of the problems in the previous migration re: MySQL
      # Failure here is okay
      Rails.logger.warn("Failed to set null values for passphrase_ciphertext: #{e}")
      Rails.logger.warn("This is expected if you are using MySQL")
    end

    begin
      # Remove default values
      change_column_default(:passwords,   :passphrase_ciphertext, nil)
      change_column_default(:file_pushes, :passphrase_ciphertext, nil)
      change_column_default(:urls,        :passphrase_ciphertext, nil)
    rescue ActiveRecord::StatementInvalid => e
      # This will fail because of the problems in the previous migration re: MySQL
      # Failure here is okay
      Rails.logger.warn("Failed to remove default values for passphrase_ciphertext: #{e}")
      Rails.logger.warn("This is expected if you are using MySQL")
    end
  end
end
