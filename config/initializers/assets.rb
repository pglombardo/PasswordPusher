# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules/bootstrap-icons")
Rails.application.config.assets.paths << Rails.root.join("node_modules/bootstrap-icons/font")
Rails.application.config.assets.paths << Rails.root.join("node_modules/bootstrap-icons/font/fonts")
Rails.application.config.assets.paths << Rails.root.join("app/javascript")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w[application.js stimulus.js bootstrap.min.js popper.js spoiler_alert.js]
Rails.application.config.assets.precompile += %w[fonts/bootstrap-icons.woff fonts/bootstrap-icons.woff2]
