# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Rails.application.secrets.secret_key_base = ENV['SECRET_KEY_BASE'] || 'b7efd5d3d967b3b669d439c371329cc990616b9dd47bf02c42dedb3c74a9d54e30dfd52323480623acc92fdec88b79d2cf9e211b1fd8a946d008c4e1f3162b28'
