class AddDeletableToPassword < ActiveRecord::Migration
  def change
    add_column :passwords, :deletable_by_viewer, :boolean, :default => true
  end
end
