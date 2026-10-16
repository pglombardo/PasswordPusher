# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules/bootstrap-icons/font")
# flag-icons SVGs (logical paths flags/4x3/*.svg and flags/1x1/*.svg) so Propshaft
# can fingerprint url("/flags/...") in compiled theme CSS.
Rails.application.config.assets.paths << Rails.root.join("node_modules/flag-icons")

# Latin woff2 files for Bootswatch themes. Each package's files/ directory is a load-path
# root so url("/inter-latin-400-normal.woff2") resolves and gets fingerprinted.
# See app/assets/stylesheets/themes/_bundled_fonts.scss.
%w[
  cabin-sketch
  inter
  lato
  montserrat
  neucha
  news-cycle
  nunito
  nunito-sans
  open-sans
  roboto
  source-sans-pro
  ubuntu
].each do |family|
  Rails.application.config.assets.paths << Rails.root.join("node_modules/@fontsource/#{family}/files")
end
