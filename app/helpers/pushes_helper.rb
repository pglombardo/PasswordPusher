# frozen_string_literal: true

module PushesHelper
  include ShareMessageHelper

  PUSH_PAYLOAD_AUTO_REBLUR_SECONDS = 20

  # Hard ceiling for per-value slider labels so a misconfigured
  # expire_after_*_max cannot dump tens of thousands of strings into the page.
  # The configured max is still included when it exceeds this cap.
  KNOBS_EXPIRATION_LABEL_HARD_MAX = 1_000

  def push_payload_auto_reblur_seconds
    PUSH_PAYLOAD_AUTO_REBLUR_SECONDS
  end

  # Label for a single expiration count, e.g. "1 Day" / "5 Days".
  # Uses the capitalized Day/Days (and View/Views) gettext pair, not the
  # lowercase day/days strings used in sentence context.
  def knobs_expiration_count_label(singular, plural, count)
    n = count.to_i
    "#{n} #{n_(singular, plural, n)}"
  end

  # JSON object mapping slider values to n_()-pluralized labels for the knobs
  # Stimulus controller. Keys are integers so to_json emits string keys that
  # match input.value in JS.
  def knobs_expiration_count_labels(singular, plural, min:, max:)
    start = min.to_i
    stop = max.to_i
    stop = start if stop < start

    upper = [stop, KNOBS_EXPIRATION_LABEL_HARD_MAX].min
    range_end = (start > KNOBS_EXPIRATION_LABEL_HARD_MAX) ? start : upper

    labels = (start..range_end).to_h { |n| [n, knobs_expiration_count_label(singular, plural, n)] }
    labels[stop] ||= knobs_expiration_count_label(singular, plural, stop)
    labels
  end

  def knobs_day_labels_json(settings)
    knobs_expiration_count_labels(
      "Day",
      "Days",
      min: settings.expire_after_days_min,
      max: settings.expire_after_days_max
    ).to_json
  end

  def knobs_view_labels_json(settings)
    knobs_expiration_count_labels(
      "View",
      "Views",
      min: settings.expire_after_views_min,
      max: settings.expire_after_views_max
    ).to_json
  end

  # Returns a human-readable string for push expiration (days only), e.g. "5 days" or "1 day".
  def format_days_remaining(push)
    days = push.days_remaining
    "#{days} #{n_("day", "days", days)}"
  end

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
