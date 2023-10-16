# frozen_string_literal: true

class RemoveDeletableFromUrls < ActiveRecord::Migration[7.0]
  def change
    remove_column :urls, :deletable_by_viewer, :boolean, default: true
  end
end
