# frozen_string_literal: true

if !Rails.env.development? && !Rails.env.test?
  Rails.application.configure do
    config.lograge.enabled = true

    config.lograge.custom_payload do |controller|
      options = {}
      options[:user_id] = controller.current_user.id if controller.current_user
      options[:ip] = controller.request.ip
      options[:forwarded_for] = controller.request.x_forwarded_for if controller.request.x_forwarded_for
      options
    end
  end
end
