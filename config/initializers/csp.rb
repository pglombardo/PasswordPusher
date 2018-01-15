SecureHeaders::Configuration.default do |config|
  config.csp = {

    preserve_schemes: true, # default: false.

    default_src: %w('none'), # all allowed in the beginning
    script_src: %w('self'), # scripts only allowed in external files from the same origin
    img_src: %w('self'),
    connect_src: %w('self'), # Ajax may connect only to the same origin
    #This is dirty. But this is a modernizr issue
    style_src: %w('self' https://fonts.googleapis.com/ 'sha256-CwE3Bg0VYQOIdNAkbB/Btdkhul49qZuwgNCMPgNY5zw=' 'sha256-MZKTI0Eg1N13tshpFaVW65co/LeICXq4hyVx6GWVlK0=' 'sha256-LpfmXS+4ZtL2uPRZgkoR29Ghbxcfime/CsD/4w5VujE=' 'sha256-YJO/M9OgDKEBRKGqp4Zd07dzlagbB+qmKgThG52u/Mk='), # styles only allowed in external files from the same origin and in style attributes (for now)
    font_src: %w('self' https://fonts.googleapis.com/ https://fonts.gstatic.com/)
   # report_uri: ["/csp_report?report_only=#{Rails.env.production?}“] # violation reports will be sent here
  }
end
