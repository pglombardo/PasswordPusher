# frozen_string_literal: true

require "test_helper"

class NotifyEmailsPartialsViewTest < ActionView::TestCase
  include LanguageHelper

  setup do
    @push = Push.new(kind: "text")
    @builder = ActionView::Helpers::FormBuilder.new("push", @push, self, {})
    # Ensure action is not 'edit' so partials render (they use <% unless action_name == 'edit' %>)
    def controller.action_name
      "new"
    end
  end

  test "_notify_emails_to renders email recipients field and helper text" do
    render partial: "shared/notify_emails_to", locals: {f: @builder}
    assert_select "input[name=?]", "push[notify_emails_to]", count: 1
    assert_match(/Email notification recipients/i, rendered)
    assert_match(/Enter email addresses separated by commas/i, rendered)
  end

  test "_notify_emails_to_locale renders locale select and helper text" do
    render partial: "shared/notify_emails_to_locale", locals: {f: @builder}
    assert_select "select[name=?]", "push[notify_emails_to_locale]", count: 1
    assert_match(/Email notification language/i, rendered)
    assert_match(/Select the language of the email notification/i, rendered)
  end
end
