# frozen_string_literal: true

# Hash API tokens at rest (HMAC-SHA256) and clear the plaintext column.
#
# Upgrade: Docker runs `db:migrate` on boot, so existing tokens keep working with
# no operator or user action. All app processes should be upgraded together:
# older code looks up `authentication_token` and would miss nulled rows.
#
# HMAC key: `PWPUSH_API_TOKEN_HMAC_KEY` / `PWPUSH_API_TOKEN_HMAC_KEY_FILE` when set,
# otherwise a key derived from `secret_key_base`. Rotating `SECRET_KEY_BASE` without
# a dedicated HMAC key invalidates every API token (users regenerate from the UI).
# Set a dedicated key *before* this migration if you want tokens to survive
# `SECRET_KEY_BASE` rotation later; it cannot be introduced after plaintext is cleared.
#
# This migration nulls plaintext in the same release. Leaving plaintext until a
# follow-up would not address the finding (a database dump would still contain
# working tokens). The unused `authentication_token` column is kept so the schema
# change stays additive aside from the unique index move.
#
# Down: drops digest/hint/legacy columns and restores the unique index on
# `authentication_token`. Plaintext cannot be restored from the digest; rolling
# back without a pre-migration backup leaves API tokens unusable.
class HashUserAuthenticationTokens < ActiveRecord::Migration[8.1]
  class UserToken < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    add_column :users, :authentication_token_digest, :string, limit: 64
    add_column :users, :authentication_token_hint, :string, limit: 4
    add_column :users, :authentication_token_legacy, :boolean, default: false, null: false

    UserToken.reset_column_information

    say_with_time "backfilling authentication token digests" do
      UserToken.unscoped
        .where("authentication_token IS NOT NULL AND authentication_token != ''")
        .find_in_batches(batch_size: 500) do |batch|
          Pwpush::AuthenticationTokenDigest.backfill!(batch)
        end
    end

    add_index :users, :authentication_token_digest,
      unique: true,
      name: "index_users_on_authentication_token_digest"
    remove_index :users, :authentication_token if index_exists?(:users, :authentication_token)
  end

  def down
    add_index :users, :authentication_token, unique: true unless index_exists?(:users, :authentication_token)
    if index_exists?(:users, :authentication_token_digest)
      remove_index :users, :authentication_token_digest
    end
    remove_column :users, :authentication_token_legacy
    remove_column :users, :authentication_token_hint
    remove_column :users, :authentication_token_digest
  end
end
