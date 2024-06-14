# frozen_string_literal: true

require "test_helper"

class GenerateKeyPageTest < ActionDispatch::IntegrationTest
  def test_generate_key_page_renders_ok
    get page_path("generate_key")
    assert_response :success
  end
end
