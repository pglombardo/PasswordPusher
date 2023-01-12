# Pin npm packages by running ./bin/importmap

pin "application", preload: true

pin "@rails/actioncable/src", to: "@rails--actioncable--src.js" # @7.0.4
pin "@hotwired/turbo", to: "@hotwired--turbo.js" # @7.2.4
pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js" # @7.2.4
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.1
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "popper", to: 'popper.js', preload: true
pin "bootstrap", to: 'bootstrap.min.js', preload: true
pin "js-cookie" # @3.0.1
pin "omgopass" # @3.2.1
pin "omgopass/random.js", to: "omgopass--random.js.js" # @3.2.1
pin "clipboard" # @2.0.11
pin "spoiler-alert"
pin "@rails/activestorage", to: "@rails--activestorage.js" # @7.0.4
