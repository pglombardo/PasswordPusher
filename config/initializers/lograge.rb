# frozen_string_literal: true

if !Rails.env.development? && !Rails.env.test?
  Rails.application.configure do
    config.lograge.enabled = true

    # Do not log requests to the health check endpoint (e.g. monitoring / Pulsetic).
    config.lograge.ignore_custom = ->(event) { event.payload[:path] == "/up" }

    config.lograge.custom_payload do |controller|
      options = {}
      options[:user_id] = controller.current_user.try(:id)
      options[:ip] = controller.request.ip
      options[:forwarded_for] = controller.request.x_forwarded_for if controller.request.x_forwarded_for
      options
    end
  end
end
