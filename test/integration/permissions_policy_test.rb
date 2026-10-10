# frozen_string_literal: true

require "test_helper"

class PermissionsPolicyTest < ActionDispatch::IntegrationTest
  test "responses include permissions policy headers" do
    get root_path

    assert_response :success
    policy = response.headers["Permissions-Policy"]
    assert policy.present?
    assert_includes policy, "camera=()"
    assert_includes policy, "clipboard-write=(self)"
    assert_not_includes policy, "web-share"
    assert_not_includes policy, "ambient-light-sensor"
    assert_nil response.headers["Feature-Policy"]
  end
end
