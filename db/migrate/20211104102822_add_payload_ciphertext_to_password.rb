# frozen_string_literal: true

class AddPayloadCiphertextToPassword < ActiveRecord::Migration[6.1]
  def change
    # Column for new lockbox encryption
    add_column :passwords, :payload_ciphertext, :text
    # Rename legacy encryption column
    rename_column :passwords, :payload, :payload_legacy
  end
end
