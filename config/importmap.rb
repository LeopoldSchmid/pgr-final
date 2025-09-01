# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"



# Leaflet.js for maps
pin "leaflet", to: "https://esm.sh/leaflet@1.9.4"

# Flatpickr for date pickers
pin "flatpickr", to: "https://ga.jspm.io/npm:flatpickr@4.6.13/dist/flatpickr.min.js"
pin "flatpickr/dist/l10n/fr", to: "https://ga.jspm.io/npm:flatpickr@4.6.13/dist/l10n/fr.js"

# FullCalendar for rich calendar functionality
pin "@fullcalendar/core", to: "https://cdn.skypack.dev/@fullcalendar/core"
pin "@fullcalendar/daygrid", to: "https://cdn.skypack.dev/@fullcalendar/daygrid"
pin "@fullcalendar/timegrid", to: "https://cdn.skypack.dev/@fullcalendar/timegrid"
pin "@fullcalendar/interaction", to: "https://cdn.skypack.dev/@fullcalendar/interaction"
