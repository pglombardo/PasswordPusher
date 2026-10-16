# frozen_string_literal: true

Warden::Manager.after_authentication do |user, _auth, _options|
  Pwpush::Metrics.increment(
    :authentication_events,
    labels: {event: "login_success", mfa: user.respond_to?(:otp_required_for_login?) && user.otp_required_for_login?}
  )
end

Warden::Manager.before_failure do |_env, options|
  next unless options[:attempted_path].to_s.start_with?("/users/sign_in")

  Pwpush::Metrics.increment(
    :authentication_events,
    labels: {event: "login_failure", mfa: false}
  )
end

Warden::Manager.before_logout do |user, _auth, _scope|
  Pwpush::Metrics.increment(
    :authentication_events,
    labels: {event: "logout", mfa: user.respond_to?(:otp_required_for_login?) && user.otp_required_for_login?}
  )
end
