# frozen_string_literal: true

require "application_system_test_case"

class ExpirationSliderLabelsTest < ApplicationSystemTestCase
  setup do
    Settings.enable_password_pushes = true
    Rails.application.reload_routes!
    @user = users(:luca)
    login_as(@user, scope: :user)
  end

  teardown do
    Settings.reload!
    Rails.application.reload_routes!
  end

  test "password form uses singular Day and View after loadSettings when value is 1" do
    visit new_push_path(tab: "text", locale: "en")

    set_slider "#push_expire_after_days", 1
    set_slider "#push_expire_after_views", 1

    assert_selector "[data-knobs-target='daysRangeLabel']", text: "1 Day"
    assert_selector "[data-knobs-target='viewsRangeLabel']", text: "1 View"

    find("#cookie-save a").click
    assert_text "Saved!", wait: 5

    visit root_path
    visit new_push_path(tab: "text", locale: "en")

    assert_equal "1", find("#push_expire_after_days").value
    assert_equal "1", find("#push_expire_after_views").value
    assert_selector "[data-knobs-target='daysRangeLabel']", text: "1 Day"
    assert_selector "[data-knobs-target='viewsRangeLabel']", text: "1 View"
  end

  test "password form looks up pluralized labels when the slider moves" do
    visit new_push_path(tab: "text", locale: "en")

    assert_selector "[data-knobs-target='daysRangeLabel']", text: "7 Days"
    assert_selector "[data-knobs-target='viewsRangeLabel']", text: "5 Views"

    set_slider "#push_expire_after_days", 5
    set_slider "#push_expire_after_views", 5

    assert_selector "[data-knobs-target='daysRangeLabel']", text: "5 Days"
    assert_selector "[data-knobs-target='viewsRangeLabel']", text: "5 Views"
  end

  test "password form serves Russian plural forms in the knobs label maps" do
    visit new_push_path(tab: "text", locale: "ru")

    days = JSON.parse(find("div.container[data-controller*='knobs']")["data-knobs-day-labels-value"])
    views = JSON.parse(find("div.container[data-controller*='knobs']")["data-knobs-view-labels-value"])

    assert_equal "1 День", days["1"]
    assert_equal "2 Дня", days["2"]
    assert_equal "5 Дней", days["5"]
    assert_equal "21 День", days["21"]
    assert_equal "1 Просмотр", views["1"]
    assert_equal "2 Просмотра", views["2"]
    assert_equal "5 Просмотров", views["5"]

    set_slider "#push_expire_after_days", 21
    assert_selector "[data-knobs-target='daysRangeLabel']", text: "21 День"
  end

  private

  def set_slider(selector, value)
    execute_script(<<~JS)
      const el = document.querySelector(#{selector.to_json});
      el.value = #{value.to_i};
      el.dispatchEvent(new Event("input", {bubbles: true}));
      el.dispatchEvent(new Event("change", {bubbles: true}));
    JS
  end
end
