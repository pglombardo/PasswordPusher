# frozen_string_literal: true

class AddNoteCiphertextToPassword < ActiveRecord::Migration[6.1]
  def change
    # Column for new lockbox encryption
    add_column :passwords, :note_ciphertext, :text
    # Rename legacy encryption column
    rename_column :passwords, :note, :note_legacy
  end
end
