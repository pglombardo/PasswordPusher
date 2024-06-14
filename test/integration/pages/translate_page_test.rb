# frozen_string_literal: true

require "test_helper"

class TranslatePageTest < ActionDispatch::IntegrationTest
  def test_translate_page_renders_ok
    get page_path("translate")
    assert_response :success
  end
end
