PasswordPusher::Application.configure do
  config.cache_classes = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.serve_static_files = true
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.assets.digest = true
  config.force_ssl = ENV.key?('PWPUSH_COM') ? true : false
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.eager_load = true
  config.log_level = :info
end
