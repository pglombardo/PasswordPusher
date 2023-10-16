# frozen_string_literal: true

class AddExpiredOnToPassword < ActiveRecord::Migration[6.1]
  def change
    add_column :passwords, :expired_on, :datetime, default: nil
  end
end
