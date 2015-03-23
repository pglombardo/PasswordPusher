class AddFirstViewFlag < ActiveRecord::Migration
  def up
    add_column :passwords, :first_view, :boolean, :default => true
  end

  def down
    remove_column :passwords, :first_view
  end
end
