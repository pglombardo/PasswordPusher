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

  # Formats the time remaining for a push.
  #
  # Example: "2 days, 23 hours and 59 minutes"
  #
  # @param [Push] push - The push (or pull) to format the time remaining for
  # @return [String] - The formatted time remaining
  #
  def format_time_remaining(push)
    if push.minutes_remaining.zero?
      I18n._("Zero minutes")
    else
      format_minutes_duration(push.minutes_remaining)
    end
  end

  # Formats the minutes duration for a push.
  #
  # Takes an arbitrary number of minutes and formats it as a duration.
  #
  # Example: "2 days, 23 hours and 59 minutes"
  #
  # @param [Integer] minutes - The number of minutes to format as a duration
  # @return [String] - The formatted time remaining
  #
  def format_minutes_duration(minutes)
    duration = minutes * 60

    days = (duration / (24 * 3600)).to_i
    hours = ((duration % (24 * 3600)) / 3600).to_i
    calculated_minutes = ((duration % 3600) / 60).to_i

    if days.positive?
      I18n._("%{days} day(s), %{hours} hour(s) and %{minutes} minute(s)") % {days:, hours:, minutes: calculated_minutes}
    elsif hours.positive?
      if calculated_minutes.positive?
        I18n._("%{hours} hour(s) and %{minutes} minute(s)") % {hours:, minutes: calculated_minutes}
      else
        I18n._("%{count} hour(s)") % {count: hours}
      end
    else
      I18n._("%{count} minute(s)") % {count: calculated_minutes}
    end
  end
end
