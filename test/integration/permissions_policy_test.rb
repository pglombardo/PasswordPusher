# frozen_string_literal: true

require "test_helper"

class PermissionsPolicyTest < ActionDispatch::IntegrationTest
  test "responses include permissions policy headers" do
    get root_path

    assert_response :success
    assert response.headers["Permissions-Policy"].present?
    assert_includes response.headers["Permissions-Policy"], "camera=()"
    assert_includes response.headers["Permissions-Policy"], "clipboard-write=(self)"
    assert_includes response.headers["Feature-Policy"], "camera 'none'"
  end
end
