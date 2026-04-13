# frozen_string_literal: true

require "test_helper"

class MultipleEmailsValidatorTest < ActiveSupport::TestCase
  # Create a test model that uses the validator
  class TestModel
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :email_list, :custom_email_list

    validates :email_list, multiple_emails: true
    validates :custom_email_list, multiple_emails: {max_emails: 3}
  end

  def setup
    @model = TestModel.new
  end

  # Test valid cases
  test "accepts blank values" do
    @model.email_list = ""
    assert @model.valid?

    @model.email_list = nil
    assert @model.valid?
  end

  test "accepts single valid email" do
    @model.email_list = "test@example.com"
    assert @model.valid?
  end

  test "accepts multiple valid emails" do
    @model.email_list = "test@example.com,user@domain.org"
    assert @model.valid?
  end

  test "accepts emails with whitespace" do
    @model.email_list = " test@example.com , user@domain.org "
    assert @model.valid?
  end

  test "accepts emails with various valid formats" do
    valid_emails = [
      "simple@example.com",
      "very.common@example.com",
      "test+tag@example.com",
      "user.name+tag@example.co.uk",
      "x@example.com"
    ]

    @model.email_list = valid_emails.join(",")
    assert @model.valid?
  end

  # Test whitespace handling
  test "strips whitespace from individual emails" do
    @model.email_list = "  test@example.com  ,  user@domain.org  "
    assert @model.valid?
  end

  test "accepts up to default maximum of 5 emails" do
    emails = Array.new(5) { |i| "user#{i}@example.com" }
    @model.email_list = emails.join(",")
    assert @model.valid?
  end

  # Test invalid cases - email format
  test "rejects invalid email formats" do
    invalid_emails = [
      "plainaddress",
      "@missingdomain.com",
      "missing@.com",
      "missing@domain",
      "spaces in@email.com",
      "email@",
      "email@.com"
    ]

    invalid_emails.each do |invalid_email|
      @model.email_list = invalid_email
      assert_not @model.valid?, "Should reject invalid email: #{invalid_email}"
      assert_includes @model.errors[:email_list].first, "contains invalid email(s)"
    end
  end

  test "rejects mixed valid and invalid emails" do
    @model.email_list = "valid@example.com,invalid-email,another@valid.com"
    assert_not @model.valid?
    assert_includes @model.errors[:email_list].first, "contains invalid email(s)"
  end

  # Test email count limits
  test "rejects more than default maximum of 5 emails" do
    emails = Array.new(6) { |i| "user#{i}@example.com" }
    @model.email_list = emails.join(",")
    assert_not @model.valid?
    assert_includes @model.errors[:email_list].first, "contains more than 5 email(s)"
  end

  test "respects custom max_emails option" do
    # Should accept up to 3 emails
    emails = Array.new(3) { |i| "user#{i}@example.com" }
    @model.custom_email_list = emails.join(",")
    assert @model.valid?

    # Test custom max_emails - should reject more than 3 emails
    emails = Array.new(4) { |i| "user#{i}@example.com" }
    @model.custom_email_list = emails.join(",")
    assert_not @model.valid?
    assert_includes @model.errors[:custom_email_list].first, "contains more than 3 email(s)"
  end

  # Test edge cases with commas
  test "handles empty strings from comma splits" do
    @model.email_list = "test@example.com,,another@example.com"
    assert_not @model.valid?
    # Should fail because empty string doesn't match email regex
    assert_match(/has commas used in the wrong way/, @model.errors[:email_list].first)
  end

  test "rejects emails that are only whitespace" do
    @model.email_list = "test@example.com,   ,user@domain.org"
    assert_not @model.valid?
    # Should fail because whitespace-only string doesn't match email regex after strip
    assert_match(/has commas used in the wrong way/, @model.errors[:email_list].first)
  end

  # Test error message format
  test "includes the invalid email in error message" do
    @model.email_list = "valid@example.com,invalid-email-format"
    assert_not @model.valid?
    assert_includes @model.errors[:email_list].first, "contains invalid email(s)"
  end

  test "handles duplicate emails" do
    @model.email_list = "test@example.com, test@example.com"
    assert_not @model.valid?
    assert_includes @model.errors[:email_list].first, "contains duplicate emails"
  end

  test "handles trailing comma" do
    @model.email_list = "test@example.com,"
    assert_not @model.valid?
    # Should fail because commas are used in the wrong way
    assert_match(/has commas used in the wrong way/, @model.errors[:email_list].first)
  end

  test "handles leading comma" do
    @model.email_list = ",test@example.com"
    assert_not @model.valid?
    # Should fail because commas are used in the wrong way
    assert_match(/has commas used in the wrong way/, @model.errors[:email_list].first)
  end

  test "shows correct count in max emails error message" do
    emails = Array.new(6) { |i| "user#{i}@example.com" }
    @model.email_list = emails.join(",")
    assert_not @model.valid?
    assert_equal "contains more than 5 email(s)", @model.errors[:email_list].first

    # Test custom max_emails
    emails = Array.new(4) { |i| "user#{i}@example.com" }
    @model.custom_email_list = emails.join(",")
    assert_not @model.valid?
    assert_equal "contains more than 3 email(s)", @model.errors[:custom_email_list].first
  end
end
