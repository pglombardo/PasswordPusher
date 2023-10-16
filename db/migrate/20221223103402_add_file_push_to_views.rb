# frozen_string_literal: true

class AddFilePushToViews < ActiveRecord::Migration[7.0]
  def change
    add_column :views, :file_push_id, :integer, default: nil, index: true
  end
end
