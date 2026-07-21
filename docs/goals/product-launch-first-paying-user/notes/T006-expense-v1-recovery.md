# T006 — Expense V1 recovery receipt

Status: complete

Date: 2026-07-21

## Outcome

The mixed Expense V1 worktree is now a coherent, repeatable local release candidate. No pre-existing staged, unstaged, or untracked work was discarded or reset.

The remaining Rails failures were stale calendar expectations, not a product regression. The Expense browser suite had drifted from the panel-based UI and exposed two real supported-flow defects: copied expenses did not reopen the entry panel, and the fixed desktop sidebar overlaid Expense controls. The mobile panel navigation also lacked accessible names.

Playwright used the Rails test database for its realistic seed data but left that state behind, causing later fixture loads to violate foreign keys. The Expense suite now purges and prepares only the test database in `afterAll`. A full Rails run after the complete browser suite proves the isolation fix.

## Product and test changes

- Updated calendar integration coverage to the current calendar API route and date-proposal redirect.
- Made copied expenses reopen the Add panel.
- Offset desktop main content for the fixed sidebar.
- Added accessible labels to icon-only mobile Expense navigation.
- Reconciled all 16 Expense browser scenarios with the panel UI, including offline reload, mutation failure/conflict, split modes, traveler/group management, balances, copy, and phone overflow.
- Added deterministic browser-suite test-database cleanup.

## Verification

- `RAILS_ENV=test bin/rails db:test:purge db:test:prepare` — pass
- `bin/rails test` — 234 runs, 675 assertions, 0 failures, 0 errors
- `npm test` — 2 tests, 2 pass
- `npx playwright test tests/expenses-quick-add.spec.ts --project=chromium --workers=1 --reporter=list` — 16 passed
- `bin/rails test` after Playwright — 234 runs, 675 assertions, 0 failures, 0 errors
- `git diff --check` — pass

Non-blocking warnings remain for the optional VIPS OpenSlide module, Node's deprecated `module.register()`, npm's esbuild install-script approval, and one low-severity npm advisory. None caused a failed gate.

## Preserved worktree reconciliation

The status remains intentionally dirty because Package 1 recovered an existing in-progress Expense branch rather than replacing it:

- Staged Expense/PWA foundation: dependency and Procfile changes; PWA controller/service worker; the Expense controller, TypeScript application, API/database/parser/render/split/store/type modules; Expense view; JavaScript tests; Playwright config/spec; and the older Expense goal/decision-log records.
- Additional unstaged Expense refinements: Docker/runtime work; Expense API/controllers/helper/model/view changes; TypeScript controller/render/store/type changes; related Rails tests; testing and release-readiness documentation.
- Package 1 additions within that tree: calendar expectation repair, copied-expense panel behavior, desktop sidebar offset, mobile navigation labels, current panel-aware E2E coverage, and E2E test-database cleanup.
- Preserved unrelated or previously existing state: `tailwind.config.js`; the older untracked Expense release-readiness goal and runbooks; and the current product-launch GoalBuddy board and notes.

No commit or index rewrite was performed.
