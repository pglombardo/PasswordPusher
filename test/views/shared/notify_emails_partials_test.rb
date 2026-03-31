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
    assert_match(/Auto Dispatch: Send This Secret Link To/i, rendered)
    assert_match(/Enter email\(s\) separated by commas/i, rendered)
  end

  test "_notify_emails_to includes locale dropdown and hidden notify_emails_to_locale" do
    render partial: "shared/notify_emails_to", locals: {f: @builder}
    assert_select "input[name=?][type=hidden]", "push[notify_emails_to_locale]", count: 1
    assert_match(/Send emails in the following language/i, rendered)
    assert_match(/Autodetect the recipient/i, rendered)
  end
end
