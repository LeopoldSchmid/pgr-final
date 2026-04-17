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

## 2026-04-09 - Meal planning and shopping are separate but connected domains
- Decision: Treat `Meal Planning` as coordination logic and `Shopping` as procurement logic.
- Why:
  - Real trips include needs that do not map cleanly to single meals, such as drinks, snacks, staples, and shared supplies.
  - Shopping must work manually, from meal plans, or as a mixture of both.
  - Cooperative shopping often needs partial completion, not only a boolean purchased state.
- Consequence:
  - Shopping must remain a first-class object, not only a derived report from meals.
  - Manual shopping items remain a supported path.
  - Partial purchase tracking becomes a valid target for future model evolution.

## 2026-04-10 - Shopping supports multiple lists and manual synchronization from meal planning
- Decision: Model shopping around a shared requirement layer plus multiple concrete shopping lists, with a manual sync step from meal planning.
- Why:
  - Real trips often split purchases across stores such as `Aldi` and `Wochenmarkt`.
  - A single derived shopping list is too rigid for actual trip logistics.
  - Recipe and portion changes must not silently overwrite manually organized shopping work.
- Consequence:
  - Shopping needs a maintenance/planning view and a separate in-store execution view.
  - Meal-plan-derived needs should become syncable requirements, not only final list rows.
  - Drift between current meal-plan state and shopping state must become visible.

## 2026-04-10 - The final shopping solution is UX-first and may replace the existing code entirely
- Decision: Treat the current shopping implementation as replaceable and design the final solution around the real user workflow, not around preserving existing code paths.
- Why:
  - A technically partial but UX-poor solution will not be used in practice.
  - The shopping domain now clearly requires multiple lists, synchronization, reuse, and later comments.
  - There are no migration constraints on this part of the codebase.
- Consequence:
  - Data model and screens may be redesigned fundamentally.
  - Reuse across trips and lessons learned become part of the intended long-term design.

## 2026-04-10 - Plans navigation should preserve the last selected secondary tab
- Decision: Treat the `Plans` area as a multi-step workspace and return users to the last selected plans tab when they come back from another primary section.
- Why:
  - Resetting to `Meal Plan` on every return breaks the actual workflow between `Meal Plan`, `Shopping Plan`, and `Shopping List`.
  - Mobile usage depends on resuming the current sub-task with minimal friction.
- Consequence:
  - `Plans` entry points should read and write a lightweight last-tab state.
  - Bottom navigation should not discard the active plans sub-context.

## 2026-04-17 - Shopping List uses a canonical plans URL and remembers the last selected list
- Decision: Route Shopping List navigation through `/plans/shopping-list` as canonical entry, with `list_id` selection and session-backed last-list memory.
- Why:
  - Mixed URLs (`/plans/...` vs `/trips/:id/shopping_lists/:id`) make the planning flow feel inconsistent.
  - Returning from another primary section should restore both the `Shopping List` tab and the previously selected concrete list.
- Consequence:
  - Controllers now redirect nested shopping-list page requests to the canonical plans URL.
  - `Shopping Plan` auto-creates a default list (`Trip Shopping List`) when none exists, so assignment flow never dead-ends.
  - Redirect targets from shopping item and assignment actions stay within the plans URL structure.
