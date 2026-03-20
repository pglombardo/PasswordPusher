# frozen_string_literal: true

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

  # Constructs a fully qualified secret URL for a push.
  #
  # @param [Push] push - The push to generate a URL for
  # @param [Boolean] with_retrieval_step - Whether to include the retrieval step in the URL
  # @return [String] - The fully qualified URL
  def secret_url(push, with_retrieval_step: true, locale: nil)
    raw_url = if push.retrieval_step && with_retrieval_step
      Settings.override_base_url ? Settings.override_base_url + preliminary_push_path(push) : preliminary_push_url(push)
    else
      Settings.override_base_url ? Settings.override_base_url + push_path(push) : push_url(push)
    end

    # Delete any existing ?locale= query parameter
    raw_url = raw_url.split("?").first

    # Append the locale query parameter
    if params["push_locale"].present? && Settings.enabled_language_codes.include?(params["push_locale"])
      raw_url += "?locale=#{params["push_locale"]}"
    elsif locale.present? && Settings.enabled_language_codes.include?(locale)
      raw_url += "?locale=#{locale}"
    end

    # Support forced https links with FORCE_SSL env var
    raw_url.gsub!(/http/i, "https") if ENV.key?("FORCE_SSL") && !request.ssl?
    raw_url
  end

  # TUS resumable uploads: used for file pushes when logins and file pushes are enabled.
  def tus_uploads_enabled?
    !Settings.disable_logins && Settings.enable_file_pushes
  end

  def tus_uploads_url
    uploads_path
  end

  # Parses human-friendly size (e.g. "50 MB", "2 MB", "1 GB", "100 KB", "64 B") or a plain integer
  # byte count (e.g. "1048576") to bytes. Malformed strings return the 2 MB fallback.
  # Used for tus_chunk_size and max_tus_upload_size so config can use "50 MB" / "100 GB" instead of raw bytes.
  def parse_human_size(value)
    fallback = 2 * 1024 * 1024
    return fallback if value.blank?
    return value.to_i if value.is_a?(Numeric)
    s = value.to_s.strip
    return s.to_i if s.match?(/\A\d+\z/)

    m = s.match(/\A(\d+(?:\.\d+)?)\s*([KMGTP]B?|B)\z/i)
    return fallback unless m

    n = m[1].to_f
    u = m[2].to_s.upcase
    mult = case u
    when "B" then 1
    when "K", "KB" then 1024
    when "M", "MB" then 1024**2
    when "G", "GB" then 1024**3
    when "T", "TB" then 1024**4
    when "P", "PB" then 1024**5
    else return fallback
    end
    (n * mult).to_i
  end

  def tus_chunk_size_bytes
    parse_human_size(Settings.files.tus_chunk_size)
  end

  def max_tus_upload_size_bytes
    parse_human_size(Settings.files.max_tus_upload_size)
  end

  # qr_code
  #
  # Generates a QR code for the given URL
  #
  # @param [String] url - The URL to generate the QR code for
  # @return [String] - The SVG QR code
  def qr_code(url)
    RQRCode::QRCode.new(url).as_svg(
      offset: 0,
      color: :currentColor,
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true
    ).html_safe
  end
end
