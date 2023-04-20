class AddPassphraseToModels < ActiveRecord::Migration[7.0]
  def change
    # This migration breaks on MySQL Server so we need to check what we are using
    # See: https://github.com/pglombardo/PasswordPusher/issues/1002
    #
    # Between this migration and the next, we will remove the default values entirely
    # and both groups of MySQL servers (MySQL server & MariaDB) will be happy.

    using_mysql_server = false
    if ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
      results = ActiveRecord::Base.connection.execute('show variables like "version_comment%";')
      using_mysql_server = (results.first[1] =~ /mariadb/i) == nil
    end

    if using_mysql_server
      # MySQL Server (not MariaDB)
      add_column :passwords,   :passphrase_ciphertext, :text, :limit => 2048
      add_column :file_pushes, :passphrase_ciphertext, :text, :limit => 2048
      add_column :urls,        :passphrase_ciphertext, :text, :limit => 2048
    else
      # Every database except MySQL Server
      add_column :passwords,   :passphrase_ciphertext, :text, :null => false, :default => '', :limit => 2048
      add_column :file_pushes, :passphrase_ciphertext, :text, :null => false, :default => '', :limit => 2048
      add_column :urls,        :passphrase_ciphertext, :text, :null => false, :default => '', :limit => 2048
    end
  end
end
