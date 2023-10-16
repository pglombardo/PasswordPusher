# frozen_string_literal: true

class AddIndexToPasswordsUrlToken < ActiveRecord::Migration[6.1]
  def change
    add_index :passwords, :url_token, unique: true
  end
end
