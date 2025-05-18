class RemoveDeletedFromPushes < ActiveRecord::Migration[7.2]
  def change
    remove_column :pushes, :deleted, :boolean
  end
end
