class FixPassphraseDefault < ActiveRecord::Migration[7.0]
  def change
    # The previous migration breaks on MySQL Server.  See previous migration for an explanation.

    using_mysql_server = false
    if ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
      results = ActiveRecord::Base.connection.execute('show variables like "version_comment%";')
      using_mysql_server = (results.first[1] =~ /mariadb/i) == nil
    end

    if !using_mysql_server
      # Every database except MySQL Server

      # Add ability to set null values
      change_column_null(:passwords,   :passphrase_ciphertext, true)
      change_column_null(:file_pushes, :passphrase_ciphertext, true)
      change_column_null(:urls,        :passphrase_ciphertext, true)

      # Remove default values
      change_column_default(:passwords,   :passphrase_ciphertext, nil)
      change_column_default(:file_pushes, :passphrase_ciphertext, nil)
      change_column_default(:urls,        :passphrase_ciphertext, nil)

      # Change all empty string passphrases to nulls
      Password.where(passphrase_ciphertext: '').update_all(passphrase_ciphertext: nil)
      FilePush.where(passphrase_ciphertext: '').update_all(passphrase_ciphertext: nil)
      Url.where(passphrase_ciphertext: '').update_all(passphrase_ciphertext: nil)
  end
end
