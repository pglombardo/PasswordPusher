
SecureHeaders::Configuration.default do |config|

    if Rails.env.production?
      config.csp = {
        preserve_schemes: true, # default: false.
        default_src: %w('none'), # all allowed in the beginning
        script_src: %w('self'), # scripts only allowed in external files from the same origin

        img_src: %w('self'),
        connect_src: %w('self'), # Ajax may connect only to the same origin
        #This is dirty. But this is a modernizr issue
        style_src: %w('self'), 
        font_src: %w('self'),
        form_action: %w('self'),
        base_uri: %w('self'),
        frame_ancestors: %w('none'),
        upgrade_insecure_requests: true,
        report_uri: %w(https://d44c6675f6f03f85482859e657572968.report-uri.com/r/t/csp/enforce; report-to default) # violation reports will be sent here
      }
    config.hsts = "max-age=#{1.year.to_i}; includeSubdomains; preload"
  else
    config.csp = {
      preserve_schemes: true, # default: false.
      default_src: %w('none'), # all allowed in the beginning
      script_src: %w('self'), # scripts only allowed in external files from the same origin
      img_src: %w('self'),
      connect_src: %w('self'), # Ajax may connect only to the same origin
      #This is dirty. But this is a modernizr issue
      style_src: %w('self'), 
      font_src: %w('self'),
      form_action: %w('self'),
      base_uri: %w('self'),
      frame_ancestors: %w('none'),
      upgrade_insecure_requests: false,
      report_uri: %w(https://d44c6675f6f03f85482859e657572968.report-uri.com/r/t/csp/enforce; report-to default) # violation reports will be sent here
    }

  end
  config.cookies = {
    secure: true, # mark all cookies as "Secure"
    samesite: {
      lax: true # mark all cookies as SameSite=lax
    }
  }
  config.referrer_policy = %w(same-origin)
end
