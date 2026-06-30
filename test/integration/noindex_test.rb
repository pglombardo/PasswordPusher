# frozen_string_literal: true

require "test_helper"

class NoindexTest < ActionDispatch::IntegrationTest
  teardown do
    Settings.reload!
  end

  test "robots meta tag is absent when noindex is false" do
    Settings.noindex = false

    get root_path
    assert_response :success
    assert_select "meta[name=robots][content=?]", "noindex, nofollow", count: 0
  end

  test "robots meta tag is present when noindex is true" do
    Settings.noindex = true

    get root_path
    assert_response :success
    assert_select "meta[name=robots][content=?]", "noindex, nofollow", count: 1
  end
end
