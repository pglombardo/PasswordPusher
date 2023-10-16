# frozen_string_literal: true

class AddUrlToViews < ActiveRecord::Migration[7.0]
  def change
    add_column :views, :url_id, :integer, default: nil, index: true
  end
end
