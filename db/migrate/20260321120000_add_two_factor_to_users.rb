# frozen_string_literal: true

class AddTwoFactorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_required_for_login, :boolean
    add_column :users, :otp_secret, :string
    add_column :users, :last_otp_timestep, :integer
    add_column :users, :otp_backup_codes, :text
  end
end
