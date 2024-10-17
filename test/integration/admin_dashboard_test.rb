# frozen_string_literal: true

require "test_helper"

class AdminDashboardTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Rails.application.reload_routes!
  end

  teardown do
    Settings.enable_logins = false
    Rails.application.reload_routes!
  end

  def test_dashboard_not_available_by_default
    get admin_root_path
    assert_response :not_found
  end

  def test_dashboard_not_available_to_non_admins
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
    get admin_root_path
    assert_response :not_found
    sign_out @luca
  end

  def test_dashboard_available_to_admin_user
    @mr_admin = users(:mr_admin)
    sign_in @mr_admin
    get admin_root_path
    assert_response :success
    sign_out @mr_admin
  end
end
