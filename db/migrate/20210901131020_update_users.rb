# frozen_string_literal: true

class UpdateUsers < ActiveRecord::Migration[6.1]
  def change
    # Destroy all previously existing records since this table
    # has never been used before (outside of testing)
    User.all.destroy_all
  end
end
