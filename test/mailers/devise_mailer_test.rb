require "test_helper"

# These tests verify that Devise mailer templates render without errors.
# They require the User model to have :recoverable, :confirmable, and :lockable
# modules loaded (controlled by Settings.enable_user_account_emails).
#
# To run these tests: PWP__ENABLE_USER_ACCOUNT_EMAILS=true bin/rails test test/mailers/devise_mailer_test.rb
#
# When the feature is disabled, the tests are skipped.
class DeviseMailerTest < ActionMailer::TestCase
  setup do
    @email_enabled = User.respond_to?(:send_reset_password_instructions)
  end

  test "reset_password_instructions renders without error" do
    skip "User account emails not enabled (Settings.enable_user_account_emails)" unless @email_enabled

    user = users(:one)
    token = user.send_reset_password_instructions

    email = Devise::Mailer.reset_password_instructions(user, token)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email], email.to
    assert_match(/Password Change Request/i, email.subject)
    assert_match(/change your password/i, email.body.to_s)
  end

  test "confirmation_instructions renders without error" do
    skip "User account emails not enabled (Settings.enable_user_account_emails)" unless @email_enabled

    user = User.create!(email: "newuser@example.org", password: "password12345")
    token = user.send_confirmation_instructions

    email = Devise::Mailer.confirmation_instructions(user, token)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email], email.to
    assert_match(/Confirm your new account/i, email.subject)
    assert_match(/confirm your account/i, email.body.to_s)
  end

  test "email_changed renders without error for unconfirmed email" do
    skip "User account emails not enabled (Settings.enable_user_account_emails)" unless @email_enabled

    user = users(:one)
    user.unconfirmed_email = "newemail@example.org"
    user.send_confirmation_instructions

    email = Devise::Mailer.email_changed(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email], email.to
    assert_match(/Your email is being changed/i, email.subject)
    assert_match(/is being changed to/i, email.body.to_s)
  end

  test "email_changed renders without error for confirmed email" do
    skip "User account emails not enabled (Settings.enable_user_account_emails)" unless @email_enabled

    user = users(:one)
    user.update!(email: "changed@example.org")

    email = Devise::Mailer.email_changed(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["changed@example.org"], email.to
    assert_match(/Your email is being changed/i, email.subject)
    assert_match(/has been changed to/i, email.body.to_s)
  end

  test "password_change renders without error" do
    skip "User account emails not enabled (Settings.enable_user_account_emails)" unless @email_enabled

    user = users(:one)

    email = Devise::Mailer.password_change(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email], email.to
    assert_match(/Password Change/i, email.subject)
    assert_match(/password has been changed/i, email.body.to_s)
  end

  test "unlock_instructions renders without error" do
    skip "User account emails not enabled (Settings.enable_user_account_emails)" unless @email_enabled

    user = users(:one)
    token = user.send_unlock_instructions

    email = Devise::Mailer.unlock_instructions(user, token)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email], email.to
    assert_match(/Unlock Your Account/i, email.subject)
    assert_match(/account has been locked/i, email.body.to_s)
  end
end
