ActionView::Base.field_error_proc = proc do |html_tag, instance|
  # Parse the tag safely
  fragment = Nokogiri::HTML::DocumentFragment.parse(html_tag)
  element = fragment.children.first

  # Only add class if it's a form field
  if element && %w[input textarea select].include?(element.name)
    existing_classes = element["class"].to_s.split
    element["class"] = (existing_classes + ["is-invalid"]).uniq.join(" ")
    fragment.to_html.html_safe
  else
    html_tag
  end
end
