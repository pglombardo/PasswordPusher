# frozen_string_literal: true

class AddDeletableToPassword < ActiveRecord::Migration[4.2]
  def change
    add_column :passwords, :deletable_by_viewer, :boolean, default: true
  end
end
