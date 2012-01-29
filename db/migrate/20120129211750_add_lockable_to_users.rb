class AddLockableToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
          t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
    end
    add_index :users, :unlock_token, :unique => true
  end
end
