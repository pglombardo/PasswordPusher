class AddPassphraseToModels < ActiveRecord::Migration[7.0]
  def change
    add_column :passwords,   :passphrase_ciphertext, :text, :null => false, :default => '', :limit => 2048 
    add_column :file_pushes, :passphrase_ciphertext, :text, :null => false, :default => '', :limit => 2048
    add_column :urls,        :passphrase_ciphertext, :text, :null => false, :default => '', :limit => 2048
  end
end
