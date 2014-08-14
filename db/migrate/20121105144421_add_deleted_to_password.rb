class AddDeletedToPassword < ActiveRecord::Migration
  def change
    add_column :passwords, :deleted, :boolean, :default => false
  end
end
