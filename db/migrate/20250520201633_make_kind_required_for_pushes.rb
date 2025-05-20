class MakeKindRequiredForPushes < ActiveRecord::Migration[7.2]
  def change
    # Make kind required for pushes
    change_column_null :pushes, :kind, false
  end
end
