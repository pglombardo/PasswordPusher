class AddNameToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :passwords, :name, :string
    add_column :file_pushes, :name, :string
    add_column :urls, :name, :string
  end
end
