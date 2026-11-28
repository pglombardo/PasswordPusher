# frozen_string_literal: true

module AdminHelper
  def release_banner_visible?(result = @release_check)
    return false unless ReleaseCheck.enabled?
    return false unless result&.update_available?
    return true if result.security_available?

    cookies[ReleaseCheck::DISMISS_COOKIE].to_s != result.latest.to_s
  end

  def release_update_headline(result)
    if result.stable_channel?
      _("Password Pusher v%{version} is now available on the stable channel (you're running v%{current}).") % {
        version: result.latest,
        current: result.running_version
      }
    else
      _("Password Pusher v%{latest} is available (you're running v%{current})") % {
        latest: result.latest,
        current: result.running_version
      }
    end
  end

  def release_up_to_date_message(result)
    if result&.stable_channel?
      _("You're running the current stable version.")
    else
      _("You're running the latest version.")
    end
  end
end
