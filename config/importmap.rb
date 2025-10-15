# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "@rails/activestorage", to: "@rails--activestorage.js" # @8.0.300
pin "bootstrap" # @5.3.8
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@fontsource/roboto", to: "@fontsource--roboto.js" # @5.2.8
pin "@fontsource/roboto-mono", to: "@fontsource--roboto-mono.js" # @5.2.8
pin "@fontsource/roboto-slab", to: "@fontsource--roboto-slab.js" # @5.2.8
pin "@rails/actioncable", to: "@rails--actioncable.js" # @8.0.300
pin "clipboard" # @2.0.11
pin "js-cookie" # @3.0.5
pin "omgopass" # @3.2.1
pin "omgopass/random.js", to: "omgopass--random.js.js" # @3.2.1
pin "local-time" # @3.0.3
pin "@popperjs/core", to: "https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/umd/popper.min.js"
