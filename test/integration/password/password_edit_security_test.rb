require "test_helper"

class PasswordEditSecurityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @luca = users(:luca)
    sign_in @luca
  end

  test "handles XSS attempts in payload" do
    push = Push.create!(kind: "text", payload: "Safe", user: @luca)

    xss_payload = "<script>alert('XSS')</script>"
    patch push_path(push), params: {
      push: {payload: xss_payload}
    }

    push.reload
    # Payload should be stored as-is (encryption handles it)
    assert_equal xss_payload, push.payload

    # But rendering should escape it
    get push_path(push)
    assert_no_match(/<script>/, response.body)
    assert_match(/&lt;script&gt;/, response.body)
  end

  test "handles SQL injection attempts in name" do
    push = Push.create!(kind: "text", payload: "Safe", user: @luca)

    sql_injection = "'; DROP TABLE pushes; --"
    patch push_path(push), params: {
      push: {
        payload: "Password",
        name: sql_injection
      }
    }

    push.reload
    assert_equal sql_injection, push.name
    # Verify table still exists
    assert Push.count > 0
  end
end
