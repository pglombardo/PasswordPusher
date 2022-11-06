module ApplicationHelper
  # Set the HTML title for the page with a trailing site identifier.
  def title(content)
    if Settings.brand.title
      return content_for(:html_title) { "#{content} | #{Settings.brand.title}" }
    else
      return content_for(:html_title) { "#{content} | #{_('Password Pusher')}" }
    end
  end

  # Set the HTML title for the page _without_ the trailing site identifier.
  # Used in Password#show/show_expired to hide Password Pusher branding
  def plain_title(content)
    content_for(:html_title) { content }
  end
end
