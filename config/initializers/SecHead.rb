SecureHeaders::Configuration.default do |config|
  config.csp = {
    preserve_schemes: true, # default: false.
    default_src: %w('none'), # all allowed in the beginning
    script_src: %w('self'), # scripts only allowed in external files from the same origin
    img_src: %w('self'),
    connect_src: %w('self'), # Ajax may connect only to the same origin
    #This is dirty. But this is a modernizr issue
    style_src: %w('self' https://fonts.googleapis.com/ ), 
    font_src: %w('self' https://fonts.googleapis.com/ https://fonts.gstatic.com/),
    form_action: %w('self'),
    base_uri: %w('self'),
    frame_ancestors: %w('none'),
    upgrade_insecure_requests: true
   # report_uri: ["/csp_report?report_only=#{Rails.env.production?}“] # violation reports will be sent here
  }

  config.referrer_policy = %w(same-origin)

<<<<<<< HEAD
  config.hsts = "max-age=#{6.month.to_i};includeSubDomains"
=======
  config.hsts = "max-age=#{6.month.to_i}; includeSubdomains"
>>>>>>> f68f9a83c0d1d5dc396aeebef05db9d3782c8b87
  config.cookies = {
    secure: true, # mark all cookies as "Secure"
    samesite: {
      lax: true # mark all cookies as SameSite=lax
    }
  }
end
