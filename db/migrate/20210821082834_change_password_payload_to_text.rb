# frozen_string_literal: true

class ChangePasswordPayloadToText < ActiveRecord::Migration[6.1]
  def change
    # https://sqlines.com/postgresql/datatypes/text
    # CHAR(n)	    Fixed-length	  1 ⇐ n < 1 Gb	Default is 1
    # VARCHAR(n)	Variable-length	1 ⇐ n < 1 Gb	Default is 1 Gb

    # Both TEXT and VARCHAR have the upper limit at 1 Gb, and there is no performance
    # difference among them (according to the PostgreSQL documentation).
    change_column :passwords, :payload, :text
  end
end
