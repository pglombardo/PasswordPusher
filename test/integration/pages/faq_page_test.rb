# frozen_string_literal: true

require "test_helper"

class FAQPageTest < ActionDispatch::IntegrationTest
  def test_faq_page_renders_ok
    get page_path("faq")
    assert_response :success
  end
end
