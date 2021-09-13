module ApplicationHelper
  def title(content)
    content_for(:html_title) { "#{APPLICATION_SHORT_NAME} | #{content}" }
  end
end
