# frozen_string_literal: true

require "test_helper"

class ToolsPageTest < ActionDispatch::IntegrationTest
  def test_tools_page_renders_ok
    get page_path("tools")
    assert_response :success
  end
end
