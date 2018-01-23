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
    frame_ancestors: %w('none')
   # report_uri: ["/csp_report?report_only=#{Rails.env.production?}“] # violation reports will be sent here
  }

  config.referrer_policy = %w(same-origin)

  config.hsts = "max-age=#{6.month.to_i}"
end
