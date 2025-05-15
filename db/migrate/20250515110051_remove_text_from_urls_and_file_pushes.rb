class RemoveTextFromUrlsAndFilePushes < ActiveRecord::Migration[7.2]
  def change
    remove_column :urls, :text, :text
    remove_column :file_pushes, :text, :text
  end
end
