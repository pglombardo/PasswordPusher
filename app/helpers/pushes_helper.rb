# frozen_string_literal: true

module PushesHelper
  def filesize(size)
    units = %w[B KiB MiB GiB TiB Pib EiB ZiB]

    return "0.0 B" if size.zero?

    exp = (Math.log(size) / Math.log(1024)).to_i
    exp += 1 if size.to_f / (1024**exp) >= 1024 - 0.05
    exp = units.size - 1 if exp > units.size - 1

    format("%.1f #{units[exp]}", size.to_f / (1024**exp))
  end

  # Returns HTML options hash for checkbox form controls with cookie persistence support
  # For new pushes (not persisted), includes x-default attribute to enable cookie loading
  # For existing pushes, omits x-default so server values are preserved
  def checkbox_options_for_push(push, target_name, default_value)
    base_options = {
      :class => "form-check-input flex-shrink-0",
      "data-knobs-target" => "#{target_name}Checkbox"
    }

    if push.persisted?
      base_options
    else
      base_options.merge("x-default" => default_value)
    end
  end
end
