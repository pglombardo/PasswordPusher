def load_legacy_environment_variables
    # Check for Legacy Environment Variables (to be deprecated)
    deprecations_detected = false

    legacy_options = [ :expire_after_days_default, :expire_after_days_min, :expire_after_days_max, :expire_after_views_default,
                       :expire_after_views_min, :expire_after_views_max, :enable_retrieval_step, :retrieval_step_default,
                       :enable_deletable_pushes, :deletable_pushes_default ]

    for option in legacy_options do
        if !Settings.send(option).nil?
            Rails.logger.warn("The setting (#{option}) has been moved to the 'pw' section of the settings.yml file.\n" +
                              "Please update your settings.yml file or if using environment variables, change the variable name 'PWP__#{option.to_s.upcase}' to 'PWP__PW__#{option.to_s.upcase}'.\n")
            Settings.pw.__send__("#{option}=", Settings.send(option))                   
            deprecations_detected = true
        end
    end

    # Legacy environment variable: EXPIRE_AFTER_DAYS_DEFAULT
    # Deprecated in October 2022
    if ENV.key?('EXPIRE_AFTER_DAYS_DEFAULT')
        Rails.logger.warn("The environment variable EXPIRE_AFTER_DAYS_DEFAULT has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__EXPIRE_AFTER_DAYS_DEFAULT or switch to a custom settings.yml entirely.")
        Settings.pw.expire_after_days_default = ENV['EXPIRE_AFTER_DAYS_DEFAULT'].to_i
        deprecations_detected = true
    end

    # Legacy environment variable: EXPIRE_AFTER_DAYS_MIN
    # Deprecated in October 2022
    if ENV.key?('EXPIRE_AFTER_DAYS_MIN')
        Rails.logger.warn("The environment variable EXPIRE_AFTER_DAYS_MIN has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__EXPIRE_AFTER_DAYS_MIN or switch to a custom settings.yml entirely.")
        Settings.pw.expire_after_days_min = ENV['EXPIRE_AFTER_DAYS_MIN'].to_i
        deprecations_detected = true
    end

    # Legacy environment variable: EXPIRE_AFTER_DAYS_MAX
    # Deprecated in October 2022
    if ENV.key?('EXPIRE_AFTER_DAYS_MAX')
        Rails.logger.warn("The environment variable EXPIRE_AFTER_DAYS_MAX has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__EXPIRE_AFTER_DAYS_MAX or switch to a custom settings.yml entirely.")
        Settings.pw.expire_after_days_max = ENV['EXPIRE_AFTER_DAYS_MAX'].to_i
        deprecations_detected = true
    end

    # Legacy environment variable: EXPIRE_AFTER_VIEWS_DEFAULT
    # Deprecated in October 2022
    if ENV.key?('EXPIRE_AFTER_VIEWS_DEFAULT')
        Rails.logger.warn("The environment variable EXPIRE_AFTER_VIEWS_DEFAULT has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__EXPIRE_AFTER_VIEWS_DEFAULT or switch to a custom settings.yml entirely.")
        Settings.pw.expire_after_views_default = ENV['EXPIRE_AFTER_VIEWS_DEFAULT'].to_i
        deprecations_detected = true
    end

    # Legacy environment variable: EXPIRE_AFTER_VIEWS_MIN
    # Deprecated in October 2022
    if ENV.key?('EXPIRE_AFTER_VIEWS_MIN')
        Rails.logger.warn("The environment variable EXPIRE_AFTER_VIEWS_MIN has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__EXPIRE_AFTER_VIEWS_MIN or switch to a custom settings.yml entirely.")
        Settings.pw.expire_after_views_min = ENV['EXPIRE_AFTER_VIEWS_MIN'].to_i
        deprecations_detected = true
    end

    # Legacy environment variable: EXPIRE_AFTER_VIEWS_MAX
    # Deprecated in October 2022
    if ENV.key?('EXPIRE_AFTER_VIEWS_MAX')
        Rails.logger.warn("The environment variable EXPIRE_AFTER_VIEWS_MAX has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__EXPIRE_AFTER_VIEWS_MAX or switch to a custom settings.yml entirely.")
        Settings.pw.expire_after_views_max = ENV['EXPIRE_AFTER_VIEWS_MAX'].to_i
        deprecations_detected = true
    end

    # Legacy environment variable: RETRIEVAL_STEP_ENABLED
    # Deprecated in October 2022
    if ENV.key?('RETRIEVAL_STEP_ENABLED')
        Rails.logger.warn("The environment variable RETRIEVAL_STEP_ENABLED has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__ENABLE_RETRIEVAL_STEP or switch to a custom settings.yml entirely.")
        Settings.pw.enable_retrieval_step = ENV['RETRIEVAL_STEP_ENABLED'].downcase == 'true'
        deprecations_detected = true
    end

    # Legacy environment variable: RETRIEVAL_STEP_DEFAULT
    # Deprecated in October 2022
    if ENV.key?('RETRIEVAL_STEP_DEFAULT')
        Rails.logger.warn("The environment variable RETRIEVAL_STEP_DEFAULT has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__RETRIEVAL_STEP_DEFAULT or switch to a custom settings.yml entirely.")
        Settings.pw.retrieval_step_default = ENV['RETRIEVAL_STEP_DEFAULT'].downcase == 'true'
        deprecations_detected = true
    end

    # Legacy environment variable: DELETABLE_PASSWORDS_ENABLED
    # Deprecated in October 2022
    if ENV.key?('DELETABLE_PASSWORDS_ENABLED')
        Rails.logger.warn("The environment variable DELETABLE_PASSWORDS_ENABLED has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__ENABLE_DELETABLE_PUSHES or switch to a custom settings.yml entirely.")
        Settings.pw.enable_deletable_pushes = ENV['DELETABLE_PASSWORDS_ENABLED'].downcase == 'true'
        deprecations_detected = true
    end

    # Legacy environment variable: DELETABLE_BY_VIEWER_PASSWORDS
    # Deprecated in October 2022
    if ENV.key?('DELETABLE_BY_VIEWER_PASSWORDS')
        Rails.logger.warn("The environment variable DELETABLE_BY_VIEWER_PASSWORDS has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__ENABLE_DELETABLE_PUSHES or switch to a custom settings.yml entirely.")
        Settings.pw.enable_deletable_pushes = ENV['DELETABLE_BY_VIEWER_PASSWORDS'].downcase == 'true'
        deprecations_detected = true
    end

    # Legacy environment variable: DELETABLE_BY_VIEWER_DEFAULT
    # Deprecated in October 2022
    if ENV.key?('DELETABLE_BY_VIEWER_DEFAULT')
        Rails.logger.warn("The environment variable DELETABLE_BY_VIEWER_DEFAULT has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__DELETABLE_PUSHES_DEFAULT or switch to a custom settings.yml entirely.")
        Settings.pw.deletable_pushes_default = ENV['DELETABLE_BY_VIEWER_DEFAULT'].downcase == 'true'
        deprecations_detected = true
    end

    # Legacy environment variable: DELETABLE_PASSWORDS_DEFAULT
    # Deprecated in October 2022
    if ENV.key?('DELETABLE_PASSWORDS_DEFAULT')
        Rails.logger.warn("The environment variable DELETABLE_PASSWORDS_DEFAULT has been deprecated and will be removed in a future version.\n" +
                          "Please change this environment variable to PWP__DELETABLE_PUSHES_DEFAULT or switch to a custom settings.yml entirely.")
        Settings.pw.deletable_pushes_default = ENV['DELETABLE_PASSWORDS_DEFAULT'].downcase == 'true'
        deprecations_detected = true
    end

    if deprecations_detected
        Rails.logger.warn("Deprecations detected: Please see the configuration documentation for the latest updates: https://github.com/pglombardo/PasswordPusher/blob/master/Configuration.md")
    end
end

# Prepend defaults to the Settings object in case users are missing some of the latest settings
Settings.prepend_source!("#{Rails.root}/config/settings-defaults.yml")
Settings.reload!
load_legacy_environment_variables