module ApplicationHelper
  # Set the HTML title for the page with a trailing site identifier.
  def title(content)
    content_for(:html_title) { "#{content} | #{Settings.brand.title}" }
  end

  # Set the HTML title for the page _without_ the trailing site identifier.
  # Used in Password#show/show_expired to hide Password Pusher branding
  def plain_title(content)
    content_for(:html_title) { content }
  end

  # Used in the topname to set the active tab
  def current_controller?(names)
    names.include?(params[:controller])
  end

  # Used to construct the fully qualified secret URL for a push.
  # raw == This is done without the preliminary step (Click here to proceed).
  def raw_secret_url(password)
    push_locale = params['push_locale'] || I18n.locale

    if Settings.override_base_url
      raw_url = I18n.with_locale(push_locale) do
        Settings.override_base_url + password_path(password)
      end
    else
      raw_url = I18n.with_locale(push_locale) do
        if (password.is_a?(Password))
          password_url(password)
        elsif password.is_a?(Url)
          url_url(password)
        elsif password.is_a?(FilePush)
          file_push_url(password)
        else
          raise "Unknown push type: #{password.class}"
        end
      end

      # Support forced https links with FORCE_SSL env var
      raw_url.gsub(/http/i, 'https') if ENV.key?('FORCE_SSL') && !request.ssl?
    end

    raw_url
  end

  # Constructs a fully qualified secret URL for a push.
  def secret_url(password)
    url = raw_secret_url(password)
    url += '/r' if password.retrieval_step
    url
  end
end
