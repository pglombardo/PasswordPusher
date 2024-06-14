class AddIndexesToView < ActiveRecord::Migration[7.1]
  def change
    add_index :views, :file_push_id
    add_index :views, :url_id
    add_index :views, :password_id
    add_index :views, :successful
    add_index :views, :kind
  end
end
