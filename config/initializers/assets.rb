# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules/bootstrap-icons/font")
# flag-icons SVGs (logical paths flags/4x3/*.svg and flags/1x1/*.svg) so Propshaft
# can fingerprint url("/flags/...") in compiled theme CSS.
Rails.application.config.assets.paths << Rails.root.join("node_modules/flag-icons")
