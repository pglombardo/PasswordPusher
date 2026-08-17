# frozen_string_literal: true

require "test_helper"

class ThemeModeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

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

  test "brand logos use stock assets when neither custom logo is set" do
    Settings.brand.light_logo = nil
    Settings.brand.dark_logo = nil

    get root_path

    assert_response :success
    assert_select "header .brand-logo img.logo-light[src*='logo-transparent-sm-bare']"
    assert_select "header .brand-logo img.logo-dark[src*='logo-transparent-sm-dark-bare']"
  end

  test "brand logos use light logo for both modes when only light is set" do
    Settings.brand.light_logo = "/logos/acme.png"
    Settings.brand.dark_logo = nil

    get root_path

    assert_response :success
    assert_select "header .brand-logo img.logo-light[src=?]", "/logos/acme.png"
    assert_select "header .brand-logo img.logo-dark[src=?]", "/logos/acme.png"
  end

  test "brand logos use dark logo for both modes when only dark is set" do
    Settings.brand.light_logo = nil
    Settings.brand.dark_logo = "/logos/acme-dark.png"

    get root_path

    assert_response :success
    assert_select "header .brand-logo img.logo-light[src=?]", "/logos/acme-dark.png"
    assert_select "header .brand-logo img.logo-dark[src=?]", "/logos/acme-dark.png"
  end

  test "brand logos use each custom logo when both are set" do
    Settings.brand.light_logo = "/logos/acme.png"
    Settings.brand.dark_logo = "/logos/acme-dark.png"

    get root_path

    assert_response :success
    assert_select "header .brand-logo img.logo-light[src=?]", "/logos/acme.png"
    assert_select "header .brand-logo img.logo-dark[src=?]", "/logos/acme-dark.png"
  end

  test "theme boot script is present in head" do
    get root_path

    assert_response :success
    assert_match(/localStorage\.getItem\("theme"\)/, response.body)
    assert_match(/data-bs-theme/, response.body)
  end

  test "admin includes theme toggle and boot script when theme_mode is auto" do
    Settings.theme_mode = "auto"
    sign_in users(:mr_admin)

    get admin_root_path

    assert_response :success
    assert_select "html[data-controller=theme]"
    assert_select "html[data-theme-mode=auto]"
    assert_select "#theme-mode-toggle"
    assert_select "html[data-bs-theme]", count: 0
    assert_match(/localStorage\.getItem\("theme"\)/, response.body)
    assert_match(/html\[data-bs-theme="dark"\]/, response.body)
  end

  test "admin locks data-bs-theme and hides toggle when theme_mode is dark" do
    Settings.theme_mode = "dark"
    sign_in users(:mr_admin)

    get admin_root_path

    assert_response :success
    assert_select "html[data-theme-mode=dark]"
    assert_select "html[data-bs-theme=dark]"
    assert_select "#theme-mode-toggle", count: 0
  end

  test "data explorer includes theme toggle when theme_mode is auto" do
    Settings.theme_mode = "auto"
    sign_in users(:mr_admin)

    get madmin_root_path

    assert_response :success
    assert_select "html[data-controller=theme]"
    assert_select "html[data-theme-mode=auto]"
    assert_select "#theme-mode-toggle"
    assert_match(/localStorage\.getItem\("theme"\)/, response.body)
    assert_match(/html\[data-bs-theme="dark"\]/, response.body)
  end

  test "background jobs includes theme toggle and boot script when theme_mode is auto" do
    Settings.theme_mode = "auto"
    sign_in users(:mr_admin)

    get "/admin/jobs"

    assert_response :success
    assert_select "html[data-theme-mode=auto]"
    assert_select "#theme-mode-toggle"
    assert_select "html[data-bs-theme]", count: 0
    assert_match(/localStorage\.getItem\("theme"\)/, response.body)
    assert_match(/html\[data-bs-theme="dark"\]/, response.body)
    assert_match(/min-height:\s*100vh/, response.body)
  end

  test "background jobs locks data-bs-theme and hides toggle when theme_mode is dark" do
    Settings.theme_mode = "dark"
    sign_in users(:mr_admin)

    get "/admin/jobs"

    assert_response :success
    assert_select "html[data-theme-mode=dark]"
    assert_select "html[data-bs-theme=dark]"
    assert_select "#theme-mode-toggle", count: 0
  end
end
