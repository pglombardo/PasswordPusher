# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

if Settings.secure_cookies
  PasswordPusher::Application.config.session_store :cookie_store,
    key: "_PasswordPusher_session",
    secure: true,                    # Only send the cookie over HTTPS
    httponly: true,                  # Prevent JavaScript access to the cookie
    same_site: :strict               # Restrict the cookie to same-site requests
else
  PasswordPusher::Application.config.session_store :cookie_store, key: "_PasswordPusher_session"
end

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# PasswordPusher::Application.config.session_store :active_record_store
