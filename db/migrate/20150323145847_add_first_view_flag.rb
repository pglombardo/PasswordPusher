# frozen_string_literal: true

class AddFirstViewFlag < ActiveRecord::Migration[4.2]
  def up
    add_column :passwords, :first_view, :boolean, default: false
  end

  def down
    remove_column :passwords, :first_view
  end
end
