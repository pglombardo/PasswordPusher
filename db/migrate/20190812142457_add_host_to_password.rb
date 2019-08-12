class AddHostToPassword < ActiveRecord::Migration[5.0]
  def change
    add_column :passwords, :host, :string, :default => ""
  end
end

