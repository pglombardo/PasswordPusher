ActionView::Base.field_error_proc = proc do |html_tag, instance|
  # Parse the tag safely
  fragment = Nokogiri::HTML::DocumentFragment.parse(html_tag)
  element = fragment.children.first

  # Only add class if it's a form field
  if element && %w[input].include?(element.name)
    element["class"] += " is-invalid"
    # Since we're only adding a CSS class to a form element that was already in the HTML,
    # and not inserting any user-provided content, html_safe is acceptable here
    fragment.to_html.html_safe
  else
    html_tag
  end
end
