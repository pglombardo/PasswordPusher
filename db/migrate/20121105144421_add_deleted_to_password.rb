# frozen_string_literal: true

class AddDeletedToPassword < ActiveRecord::Migration[4.2]
  def change
    add_column :passwords, :deleted, :boolean, default: false
  end
end
