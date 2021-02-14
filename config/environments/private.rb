PasswordPusher::Application.configure do
  config.cache_classes = false
  config.action_controller.perform_caching = false
  config.serve_static_files = true
  config.assets.js_compressor = :uglifier
  config.assets.compile = true
  config.assets.digest = true
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.eager_load = false
  config.force_ssl = ENV.key?('FORCE_SSL') ? true : false
end
