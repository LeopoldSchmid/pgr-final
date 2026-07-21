# Testing

Stand: 2026-04-17

## Ziel
- Tests sollen lokal reproduzierbar laufen.
- Rails-Tests decken Businesslogik und Controller ab.
- Browser-nahe Flows werden mit Playwright abgesichert.
- Rails-Systemtests nutzen Playwright statt Selenium.

## Test-Arten im Projekt
- `bin/rails test`
  - Gesamte Rails-Test-Suite.
- `bin/rails test test/system`
  - Rails-Systemtests.
  - Laufen browserbasiert ueber `capybara-playwright-driver`.
- `npx playwright test`
  - Eigenstaendige End-to-End-Tests aus `tests/`.
  - Startet standardmaessig selbst einen lokalen Rails-Testserver.
  - Expense/PWA/Offline-Browser-Coverage liegt aktuell in `tests/expenses-quick-add.spec.ts`.

## Einmaliges Setup
```bash
bundle install
npm install
npx playwright install chromium
bin/rails db:prepare
```

Wenn `ruby` und `bundle` in deiner Shell auf verschiedene Installationen zeigen, nutze in diesem Projekt trotzdem die Binstubs:
```bash
bin/rails
bin/rake
bin/setup
```

Diese Binstubs laufen hier bewusst ueber `mise`, damit die Projekt-Ruby-Version konsistent ist.

## Haefige Test-Kommandos
```bash
bin/rails test
bin/rails test test/system
bin/rails test test/controllers/plans_controller_test.rb
npm run test:e2e
npm run test:e2e:local
PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1 npx playwright test --project=chromium
```

## Rails-Systemtests
- Konfiguration in `test/application_system_test_case.rb`
- Driver: `:playwright`
- Browser: Chromium
- Headless standardmaessig aktiv

Sichtbarer Browser lokal:
```bash
PLAYWRIGHT_HEADED=1 bin/rails test test/system
```

## Eigenstaendige Playwright-Tests
- Konfiguration in `playwright.config.ts`
- Testdateien liegen unter `tests/`
- Der Webserver laeuft standardmaessig unter `127.0.0.1:3200`
- Expense V1 nutzt hier bewusst eine eigenstaendige Playwright-Spec fuer Quick Add, Split Editor, Offline Queue, Konflikte, PWA-Shell und Mobile-Viewport-Proof.

Lokaler Audit gegen bereits laufende App:
```bash
npm run test:e2e:local
npm run test:e2e:local:headed
```

## Hinweise
- Auf Arch oder anderen nicht offiziell unterstuetzten Linux-Systemen kann `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1` notwendig sein.
- Die bisherigen Selenium-Systemtests wurden ersetzt und sollen nicht wieder eingefuehrt werden.
- Fuer neue UI-Tests stabile semantische Selektoren oder gezielte `data-testid`-Attribute bevorzugen.
- Committe niemals `node_modules/`, `playwright-report/` oder `test-results/`.
- Die operative manuelle Freigabe fuer Staging steht in [staging_smoke_checklist.md](/home/leo/dev/projects/plangoreminisce/documentation/staging_smoke_checklist.md).
- In restriktiven Sandboxes koennen Systemtests am lokalen Testserver-Bind scheitern (`socket(2) EPERM`); lokal/CI laufen sie regulär.
- `WickedPdf.config=` wurde auf `WickedPdf.configure` umgestellt; entsprechende Deprecation-Warnungen sollten nicht mehr auftreten.
- Die verbleibende `VIPS`-Warnung verweist auf ein fehlendes optionales Systemmodul (`libopenslide`). Das ist aktuell kein funktionaler Blocker fuer die App.
- Die verbleibende `marcel`-Warnung stammt aus der eingesetzten Gem-Version unter Ruby `3.4` und ist derzeit ein Upstream-/Dependency-Thema, kein bekannter App-Fehler.
