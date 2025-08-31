# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Leaflet.js for maps
pin "leaflet", to: "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"

# Flatpickr for date pickers
pin "flatpickr", to: "https://ga.jspm.io/npm:flatpickr@4.6.13/dist/flatpickr.min.js"
pin "flatpickr/dist/l10n/fr", to: "https://ga.jspm.io/npm:flatpickr@4.6.13/dist/l10n/fr.js"
