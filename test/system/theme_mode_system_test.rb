# frozen_string_literal: true

require "application_system_test_case"

class ThemeModeSystemTest < ApplicationSystemTestCase
  teardown do
    Settings.reload!
    clear_theme_storage
  end

  test "theme toggle cycles light dark and system" do
    Settings.theme_mode = "auto"

    visit root_path
    clear_theme_storage

    # Start from a known preference and reload so the boot script + controller apply it
    page.execute_script("localStorage.setItem('theme', 'light')")
    visit root_path

    assert_selector "#theme-mode-toggle"
    assert_equal "light", page.evaluate_script("localStorage.getItem('theme')")
    assert_equal "light", page.evaluate_script("document.documentElement.getAttribute('data-bs-theme')")

    find("#theme-mode-toggle").click
    assert_equal "dark", page.evaluate_script("localStorage.getItem('theme')")
    assert_equal "dark", page.evaluate_script("document.documentElement.getAttribute('data-bs-theme')")

    find("#theme-mode-toggle").click
    assert_equal "system", page.evaluate_script("localStorage.getItem('theme')")
    resolved = page.evaluate_script("document.documentElement.getAttribute('data-bs-theme')")
    assert_includes %w[light dark], resolved

    find("#theme-mode-toggle").click
    assert_equal "light", page.evaluate_script("localStorage.getItem('theme')")
    assert_equal "light", page.evaluate_script("document.documentElement.getAttribute('data-bs-theme')")
  end

  test "locked theme_mode hides toggle and forces dark" do
    Settings.theme_mode = "dark"

    visit root_path

    assert_no_selector "#theme-mode-toggle"
    assert_equal "dark", page.evaluate_script("document.documentElement.getAttribute('data-bs-theme')")
  end

  test "theme preference applies on admin dashboard" do
    Settings.theme_mode = "auto"
    login_as(users(:mr_admin), scope: :user)

    visit root_path
    page.execute_script("localStorage.setItem('theme', 'dark')")

    visit admin_root_path

    assert_selector "#theme-mode-toggle"
    assert_equal "dark", page.evaluate_script("document.documentElement.getAttribute('data-bs-theme')")

    find("#theme-mode-toggle").click
    assert_equal "system", page.evaluate_script("localStorage.getItem('theme')")
  end

  test "theme preference applies on background jobs" do
    Settings.theme_mode = "auto"
    login_as(users(:mr_admin), scope: :user)

    visit root_path
    page.execute_script("localStorage.setItem('theme', 'dark')")

    visit "/admin/jobs"

    assert_selector "#theme-mode-toggle"
    assert_equal "dark", page.evaluate_script("document.documentElement.getAttribute('data-bs-theme')")

    find("#theme-mode-toggle").click
    assert_equal "system", page.evaluate_script("localStorage.getItem('theme')")
  end

  private

  def clear_theme_storage
    return unless page.current_url.present? && page.current_url.start_with?("http")

    page.execute_script("try { localStorage.removeItem('theme') } catch (e) {}")
  rescue Selenium::WebDriver::Error::WebDriverError,
    Selenium::WebDriver::Error::InvalidSessionIdError,
    Selenium::WebDriver::Error::NoSuchWindowError,
    Selenium::WebDriver::Error::JavascriptError
    # Browser already closed or on a non-http page
  end
end
