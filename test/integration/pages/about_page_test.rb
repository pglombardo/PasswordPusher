# frozen_string_literal: true

require "test_helper"

class AboutPageTest < ActionDispatch::IntegrationTest
  def test_about_page_renders_ok
    get page_path("about")
    assert_response :success
  end
end
