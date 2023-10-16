# frozen_string_literal: true

class RemoveFirstViewFromPassword < ActiveRecord::Migration[6.1]
  def change
    remove_column :passwords, :first_view
  end
end
