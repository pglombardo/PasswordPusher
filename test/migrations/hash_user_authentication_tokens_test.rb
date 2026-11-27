# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/migrate/20261127120000_hash_user_authentication_tokens.rb")

class HashUserAuthenticationTokensTest < ActiveSupport::TestCase
  test "backfill converts plaintext tokens into digests that still authenticate" do
    user = users(:two)
    plaintext = "pre-upgrade-token-value"

    User.where(id: user.id).update_all(
      authentication_token: plaintext,
      authentication_token_digest: nil,
      authentication_token_hint: nil,
      authentication_token_legacy: false
    )
    user.reload

    assert_equal plaintext, user.read_attribute(:authentication_token)

    Pwpush::AuthenticationTokenDigest.backfill!([user])
    user.reload

    assert_nil user.read_attribute(:authentication_token)
    assert_equal User.digest_authentication_token(plaintext), user.authentication_token_digest
    assert_equal "alue", user.authentication_token_hint
    assert user.authentication_token_legacy?
    assert_equal user, User.find_by_authentication_token(plaintext)
    assert_nil User.find_by(authentication_token: plaintext)
  end

  test "backfill omits hints for short tokens that would otherwise store the full credential" do
    user = users(:two)
    plaintext = "xyz1"

    User.where(id: user.id).update_all(
      authentication_token: plaintext,
      authentication_token_digest: nil,
      authentication_token_hint: nil,
      authentication_token_legacy: false
    )

    Pwpush::AuthenticationTokenDigest.backfill!([user.reload])
    user.reload

    assert_nil user.read_attribute(:authentication_token)
    assert_nil user.authentication_token_hint
    assert_equal User.digest_authentication_token(plaintext), user.authentication_token_digest
    assert user.authentication_token_legacy?
    assert_equal user, User.find_by_authentication_token(plaintext)
  end

  test "migration up hashes plaintext tokens and down cannot restore them" do
    previous_config = ActiveRecord::Base.connection_db_config

    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    conn = ActiveRecord::Base.connection
    conn.create_table :users do |t|
      t.string :email
      t.string :authentication_token, limit: 30
    end
    conn.add_index :users, :authentication_token, unique: true
    conn.execute("INSERT INTO users (email, authentication_token) VALUES ('legacy@example.com', 'keep-working-token')")
    conn.execute("INSERT INTO users (email, authentication_token) VALUES ('short@example.com', '2014')")

    migration = HashUserAuthenticationTokens.new
    HashUserAuthenticationTokens::UserToken.reset_column_information
    ActiveRecord::Migration.suppress_messages { migration.migrate(:up) }

    row = conn.select_one("SELECT * FROM users WHERE email = 'legacy@example.com'")
    assert_nil row["authentication_token"]
    assert_equal Pwpush::AuthenticationTokenDigest.hexdigest("keep-working-token"), row["authentication_token_digest"]
    assert_equal "oken", row["authentication_token_hint"]
    assert ActiveRecord::Type::Boolean.new.deserialize(row["authentication_token_legacy"])

    short = conn.select_one("SELECT * FROM users WHERE email = 'short@example.com'")
    assert_nil short["authentication_token"]
    assert_nil short["authentication_token_hint"]
    assert_equal Pwpush::AuthenticationTokenDigest.hexdigest("2014"), short["authentication_token_digest"]
    assert ActiveRecord::Type::Boolean.new.deserialize(short["authentication_token_legacy"])
    assert conn.index_exists?(:users, :authentication_token_digest, unique: true)
    assert_not conn.index_exists?(:users, :authentication_token)

    ActiveRecord::Migration.suppress_messages { migration.migrate(:down) }

    row = conn.select_one("SELECT * FROM users WHERE email = 'legacy@example.com'")
    assert_nil row["authentication_token"]
    assert_raises(ActiveRecord::StatementInvalid) do
      conn.select_value("SELECT authentication_token_digest FROM users")
    end
    assert conn.index_exists?(:users, :authentication_token, unique: true)
  ensure
    ActiveRecord::Base.establish_connection(previous_config)
    User.reset_column_information
    HashUserAuthenticationTokens::UserToken.reset_column_information
  end
end
