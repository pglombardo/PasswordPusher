# frozen_string_literal: true

module AdminHelper
  def release_banner_visible?(result = @release_check)
    return false unless ReleaseCheck.enabled?
    return false unless result&.update_available?
    return true if result.security_available?

    cookies[ReleaseCheck::DISMISS_COOKIE].to_s != result.latest.to_s
  end
end
