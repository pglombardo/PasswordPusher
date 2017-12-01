SecureHeaders::Configuration.default do |config|  
    config.csp = {
      report_only: Rails.env.production?, # default: false
      preserve_schemes: true, # default: false.
      default_src: %w('none'), # nothing allowed
      script_src: %w('self' https://ssl.google-analytics.com),
      connect_src: %w('self'),
      img_src: %w('self'),
      style_src: %w('unsafe-inline'),
    }
  end  