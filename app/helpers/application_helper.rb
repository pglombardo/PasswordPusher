module ApplicationHelper
  def title(content)
    content_for(:html_title) { "#{content} | Password Pusher" }
  end
end
