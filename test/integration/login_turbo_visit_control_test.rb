# frozen_string_literal: true

require "test_helper"

# Password managers (e.g. 1Password) scan forms on full page load. Turbo Drive
# navigation to Devise auth pages can leave them unable to autofill until refresh.
# The login layout forces a full reload; header auth links skip Turbo.
class LoginTurboVisitControlTest < ActionDispatch::IntegrationTest
  teardown do
    Settings.reload!
  end

  test "login layout includes turbo-visit-control reload meta" do
    get new_user_session_path

    assert_response :success
    assert_select 'meta[name="turbo-visit-control"][content="reload"]'
  end

  test "header Log In and Sign Up links disable Turbo" do
    Settings.disable_logins = false
    Settings.disable_signups = false

    get root_path

    assert_response :success
    assert_select "a[href='#{new_user_session_path}'][data-turbo=false]"
    assert_select "a[href='#{new_user_registration_path}'][data-turbo=false]"
  end
end
