# Decision Log

## 2026-04-09 - Playwright replaces Selenium for browser-based test coverage
- Decision: Use Playwright as the browser testing baseline for `plangoreminisce` and remove Selenium as the primary path.
- Why:
  - It matches the newer projects better.
  - The previous Selenium setup was not the direction you want to continue with.
  - A shared testing approach across projects lowers maintenance friction.
- Consequence:
  - Rails system tests now run via Playwright.
  - Future browser-critical flows should prefer Playwright-backed coverage.

## 2026-04-09 - Documentation hierarchy is reduced to a small active core
- Decision: Make a small set of operational documents the source of truth and remove outdated planning artifacts.
- Why:
  - The repository had accumulated conflicting or obsolete documents.
  - Active work needs a stable, low-noise documentation baseline.
- Consequence:
  - Active references are now `stabilization_plan`, `status_quo`, `priorities`, `testing`, `delivery_standards`, and this `decision_log`.
  - Older restructure/proposal documents were removed.

## 2026-04-09 - Full product scope remains relevant for the first real-world test
- Decision: The first friend test is not limited to planning; `Plans`, `Memories`, and `Expenses` are all relevant.
- Why:
  - Real trips use different combinations of features.
  - The app should be evaluated as a flexible trip companion, not just a planner.
- Consequence:
  - Stabilization and test coverage cannot focus on planning alone.
  - Beta readiness must include cross-area core flows.

## 2026-04-09 - Mobile-first is a release criterion, not only a design preference
- Decision: Treat mobile behavior as a hard quality gate, with special attention to iPhone photo upload.
- Why:
  - A known historical MVP failure was photo upload on iPhone.
  - The product is expected to be used in everyday mobile contexts.
- Consequence:
  - Mobile-critical flows must be explicitly tested and reviewed.
  - Desktop-only confidence is insufficient for release decisions.

## 2026-04-09 - SQLite remains the production database for the current stabilization path
- Decision: Stay on SQLite for now and do not introduce PostgreSQL as part of stabilization.
- Why:
  - SQLite is considered production-safe for the intended deployment model.
  - Switching the database now would expand scope without helping the immediate friend-test goal.
- Consequence:
  - Stabilization work stays focused on product quality and flow reliability.
  - Migration planning is deferred.

## 2026-04-09 - Legacy recipe-selection shopping logic is being retired
- Decision: Remove `selected_for_shopping` and align shopping generation with the meal-planning direction.
- Why:
  - The old recipe-selection model conflicts with the newer meal-plan-oriented approach.
  - Keeping both concepts in parallel increases ambiguity and maintenance cost.
- Consequence:
  - Code, tests, routes, and wording around shopping generation need consolidation.
  - Meal planning becomes the intended source of truth for future shopping flows.
