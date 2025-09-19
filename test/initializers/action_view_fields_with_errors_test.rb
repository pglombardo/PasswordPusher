# frozen_string_literal: true

require "test_helper"

class ActionViewFieldsWithErrorsTest < ActiveSupport::TestCase
  def setup
    # Load the initializer to get access to the field_error_proc
    load Rails.root.join("config/initializers/action_view_fields_with_errors.rb")
    @field_error_proc = ActionView::Base.field_error_proc
  end

  test "handles input with no class attribute" do
    html_tag = '<input type="text" name="user[email]" />'
    result = @field_error_proc.call(html_tag, nil)
    
    assert_includes result, 'class="is-invalid"'
    assert_includes result, 'name="user[email]"'
  end

  test "handles input with empty class attribute" do
    html_tag = '<input type="text" name="user[email]" class="" />'
    result = @field_error_proc.call(html_tag, nil)
    
    assert_includes result, 'class="is-invalid"'
    assert_includes result, 'name="user[email]"'
  end

  test "handles input with existing class attribute" do
    html_tag = '<input type="text" name="user[email]" class="form-control" />'
    result = @field_error_proc.call(html_tag, nil)
    
    assert_includes result, 'class="form-control is-invalid"'
    assert_includes result, 'name="user[email]"'
  end

  test "ignores non-input elements" do
    html_tag = '<label for="user_email">Email</label>'
    result = @field_error_proc.call(html_tag, nil)
    
    assert_equal html_tag, result
    assert_not_includes result, "is-invalid"
  end

  test "does not throw NoMethodError for nil class attribute" do
    html_tag = '<input type="password" name="user[password]" />'
    
    assert_nothing_raised do
      result = @field_error_proc.call(html_tag, nil)
      assert_includes result, 'class="is-invalid"'
    end
  end
end