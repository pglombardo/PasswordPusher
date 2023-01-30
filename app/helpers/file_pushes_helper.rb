module FilePushesHelper
  def filesize(size)
      units = %w[B KiB MiB GiB TiB Pib EiB ZiB]

      return '0.0 B' if size == 0
      exp = (Math.log(size) / Math.log(1024)).to_i
      exp += 1 if (size.to_f / 1024 ** exp >= 1024 - 0.05)
      exp = units.size - 1 if exp > units.size - 1

      '%.1f %s' % [size.to_f / 1024 ** exp, units[exp]]
  end
end
  