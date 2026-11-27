# frozen_string_literal: true

class CheckForUpdatesJob < ApplicationJob
  queue_as :default

  def perform
    return unless ReleaseCheck.enabled?

    ReleaseCheck.refresh
  end
end
