# frozen_string_literal: true

require "test_helper"

class ThemeModeTest < ActionDispatch::IntegrationTest
  teardown do
    Settings.reload!
  end

  test "root includes theme toggle when theme_mode is auto" do
    Settings.theme_mode = "auto"

    get root_path

    assert_response :success
    assert_select "html[data-theme-mode=auto]"
    assert_select "html[data-controller=theme]"
    assert_select "#theme-mode-toggle"
    assert_select "html[data-bs-theme]", count: 0
  end

  test "login includes theme toggle when theme_mode is auto" do
    Settings.theme_mode = "auto"

    get new_user_session_path

    assert_response :success
    assert_select "#theme-mode-toggle"
  end

  test "theme toggle is hidden when theme_mode is light" do
    Settings.theme_mode = "light"

    get root_path

    assert_response :success
    assert_select "html[data-theme-mode=light]"
    assert_select "html[data-bs-theme=light]"
    assert_select "#theme-mode-toggle", count: 0
  end

  test "theme toggle is hidden when theme_mode is dark" do
    Settings.theme_mode = "dark"

    get root_path

    assert_response :success
    assert_select "html[data-theme-mode=dark]"
    assert_select "html[data-bs-theme=dark]"
    assert_select "#theme-mode-toggle", count: 0
  end

  test "login locks data-bs-theme when theme_mode is dark" do
    Settings.theme_mode = "dark"

    get new_user_session_path

    assert_response :success
    assert_select "html[data-bs-theme=dark]"
    assert_select "#theme-mode-toggle", count: 0
  end

  test "invalid theme_mode falls back to auto" do
    Settings.theme_mode = "neon"

    assert_equal "auto", Settings.theme_mode
    assert_not Settings.theme_mode_locked?

    get root_path

    assert_response :success
    assert_select "html[data-theme-mode=auto]"
    assert_select "#theme-mode-toggle"
  end

  test "brand logos use data-bs-theme classes not picture sources" do
    Settings.theme_mode = "auto"

    get root_path

    assert_response :success
    assert_select ".brand-logo img.logo-light"
    assert_select ".brand-logo img.logo-dark"
    assert_select "header picture", count: 0
  end

  test "theme boot script is present in head" do
    get root_path

    assert_response :success
    assert_match(/localStorage\.getItem\("theme"\)/, response.body)
    assert_match(/data-bs-theme/, response.body)
  end
end
