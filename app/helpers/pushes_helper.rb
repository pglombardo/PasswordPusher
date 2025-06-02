# frozen_string_literal: true

require "rqrcode"

module PushesHelper
  def filesize(size)
    units = %w[B KiB MiB GiB TiB Pib EiB ZiB]

    return "0.0 B" if size.zero?

    exp = (Math.log(size) / Math.log(1024)).to_i
    exp += 1 if size.to_f / (1024**exp) >= 1024 - 0.05
    exp = units.size - 1 if exp > units.size - 1

    format("%.1f #{units[exp]}", size.to_f / (1024**exp))
  end

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
