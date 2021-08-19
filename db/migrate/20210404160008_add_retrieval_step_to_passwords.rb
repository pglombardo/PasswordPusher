class AddRetrievalStepToPasswords < ActiveRecord::Migration[5.2]
  def change
    add_column :passwords, :retrieval_step, :boolean, default: false
  end
end
