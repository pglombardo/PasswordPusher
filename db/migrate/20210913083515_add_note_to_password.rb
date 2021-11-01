class AddNoteToPassword < ActiveRecord::Migration[6.1]
  def change
    add_column :passwords, :note, :text
  end
end
