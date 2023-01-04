# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "popper", to: 'popper.js', preload: true
pin "bootstrap", to: 'bootstrap.min.js', preload: true
pin "js-cookie", to: "https://ga.jspm.io/npm:js-cookie@3.0.1/dist/js.cookie.mjs"
pin "omgopass", to: "https://ga.jspm.io/npm:omgopass@3.2.1/index.js"
pin "omgopass/random.js", to: "https://ga.jspm.io/npm:omgopass@3.2.1/random.browser.js"
pin "clipboard", to: "https://ga.jspm.io/npm:clipboard@2.0.11/dist/clipboard.js"
pin "spoiler-alert"