# frozen_string_literal: true

class AddKindToView < ActiveRecord::Migration[6.1]
  def change
    add_column :views, :kind, :integer, default: 0
    add_column :views, :user_id, :integer, default: nil
  end
end
