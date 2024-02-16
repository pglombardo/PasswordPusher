# frozen_string_literal: true

module FilePushesHelper
  def filesize(size)
    units = %w[B KiB MiB GiB TiB Pib EiB ZiB]

    return "0.0 B" if size.zero?

    exp = (Math.log(size) / Math.log(1024)).to_i
    exp += 1 if size.to_f / (1024**exp) >= 1024 - 0.05
    exp = units.size - 1 if exp > units.size - 1

    format("%.1f #{units[exp]}", size.to_f / (1024**exp))
  end
end
