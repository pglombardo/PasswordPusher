# frozen_string_literal: true

require "test_helper"

module Admin
  class CustomCssControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @mr_admin = users(:mr_admin)
      @luca = users(:luca)

      sign_in @mr_admin
    end

    teardown do
      sign_out @mr_admin if @mr_admin
    end

    test "admin can access edit custom css page" do
      get edit_admin_custom_css_path

      assert_response :success
      assert_select "h1", /Custom CSS/i
      assert_select "textarea#custom_css"
    end

    test "admin can update custom css" do
      custom_css = "body { background-color: #f5f5f5; }"

      patch admin_custom_css_path, params: {custom_css: custom_css}

      assert_redirected_to edit_admin_custom_css_path
      assert_equal custom_css, SiteSetting.custom_css
      assert_equal "Custom CSS updated successfully.", flash[:notice]
    end

    test "admin can clear custom css" do
      # First set some CSS
      SiteSetting.custom_css = "body { color: red; }"
      assert SiteSetting.custom_css.present?

      # Then clear it
      patch admin_custom_css_path, params: {custom_css: ""}

      assert_redirected_to edit_admin_custom_css_path
      assert_equal "", SiteSetting.custom_css
    end

    test "non-admin cannot access edit page" do
      sign_out @mr_admin
      sign_in @luca

      get edit_admin_custom_css_path

      assert_response 404
    end

    test "non-admin cannot update custom css" do
      sign_out @mr_admin
      sign_in @luca

      original_css = SiteSetting.custom_css

      patch admin_custom_css_path, params: {custom_css: "body { color: red; }"}

      assert_response 404
      assert_equal original_css, SiteSetting.custom_css
    end

    test "unauthenticated user cannot access custom css" do
      sign_out @mr_admin

      get edit_admin_custom_css_path
      assert_response 404

      patch admin_custom_css_path, params: {custom_css: "body { color: red; }"}
      assert_response 404
    end

    test "custom css is rendered in layout when set" do
      custom_css = ":root { --primary-color: #ff0000; }"
      SiteSetting.custom_css = custom_css

      get root_path

      assert_response :success
      assert_select "style", text: custom_css
    end

    test "custom css is not rendered in layout when blank" do
      SiteSetting.custom_css = ""

      get root_path

      assert_response :success
      assert_select "style", count: 0
    end
  end
end
