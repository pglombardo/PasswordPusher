# frozen_string_literal: true

require "test_helper"

class PushKindTest < ActiveSupport::TestCase
  test "does not save a push with an unknown kind" do
    push = Push.new(kind: "not-a-kind", payload: "secret")

    assert_not push.save
    assert push.errors[:kind].any?
  end

  test "does not save a push with a blank kind" do
    push = Push.new(payload: "secret")

    assert_not push.save
    assert push.errors[:kind].any?
  end
end
