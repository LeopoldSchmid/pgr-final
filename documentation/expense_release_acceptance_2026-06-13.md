# Expense System V1 Release Acceptance Evidence

Stand: 2026-06-13

## Scope

This document records the local release-readiness evidence for Expense System V1. It does not record a production deployment, production data reset, staging deployment, or real device PWA install because those remain owner/operator responsibilities.

Use this together with:

- `documentation/expense_goal_3_release_readiness_reset_operational_trust_2026-06-10.md`
- `documentation/expense_release_readiness_runbook_2026-06-13.md`
- `documentation/decision_log.md`
- `docs/goals/expense-domain-ledger-sync-api/state.yaml`
- `docs/goals/expense-frontend-offline-pwa/state.yaml`
- `docs/goals/expense-release-readiness-reset-operational-trust/state.yaml`

## Acceptance Matrix

| Criterion | Evidence | Status |
| --- | --- | --- |
| Goal 1 backend acceptance criteria pass | Goal 1 board status is `done`; receipts cover trip-person ledger domain, split math, settlement math, idempotent client mutations, conflict handling, API contracts, late joiner support, and final audit. | Ready |
| Goal 2 frontend/PWA acceptance criteria pass | Goal 2 board status is `done`; receipts cover the TypeScript expense app, quick add, unequal splits, pending people, offline create/edit/void, IndexedDB persistence, reconnect sync, duplicate retry protection, conflict states, service worker shell caching, and Playwright proof. | Ready |
| Old expense data reset/export decision is documented | `documentation/decision_log.md` records that old production expense data is test data, should be exported only if useful, and may otherwise be ignored/reset by the owner before rollout. The runbook contains non-destructive export steps. | Ready |
| Old expense routes are safe | Legacy create/edit/delete/duplicate/secondary expense flows redirect to `/expenses` with a release notice. Controller tests prove old write paths do not mutate expenses. | Ready |
| Trip navigation points to the new app | Expense secondary navigation exposes only `/expenses` in trip context. Helper tests cover this. | Ready |
| Kamal/Docker deploy path supports the expense bundle | Docker build installs Node/npm dependencies and runs `npm ci` before Rails asset precompile. The runbook documents the same-origin Rails/Kamal architecture and JS build expectations. | Ready |
| PWA/service worker release behavior is documented | The runbook documents service worker URL, cache behavior, cache versioning expectations, and the HTTPS smoke check. Goal 2 Playwright coverage verifies the cached shell/offline browser behavior locally. | Ready for owner smoke |
| Offline create/edit/void/retry/conflict behavior is verified | Goal 2 local browser coverage verifies offline queue persistence, reconnect sync, duplicate retry protection, and conflict state handling. The owner must repeat the manual walkthrough in staging or a production-like HTTPS environment before deployment. | Ready for owner walkthrough |
| Sync failure logging is available | Rejected and conflict client mutations emit `expense_client_mutation_sync_issue` in Rails logs. API tests cover the log marker. The runbook documents Rails log and console inspection paths. | Ready |
| User-facing sync errors are actionable | Goal 2 UI receipts cover pending, failed, rejected, and conflict states. The release runbook states that silent disappearance is a blocker. | Ready |
| No known path silently drops local mutations | Goal 2 receipts cover IndexedDB pending mutation persistence and retry behavior; Goal 3 runbook requires any saved mutation to sync, remain pending/failed, or surface rejected/conflict state. | Ready |

## Local Automated Release Gate

Run these commands immediately before owner deployment:

```bash
npm test
RAILS_ENV=test bin/rails db:drop db:create db:migrate
RAILS_ENV=test bin/rails test test/controllers/expenses_controller_test.rb test/helpers/navigation_helper_test.rb test/controllers/api/expense_snapshots_controller_test.rb test/controllers/api/expense_client_mutations_controller_test.rb test/controllers/api/trip_people_controller_test.rb test/controllers/api/split_groups_controller_test.rb
npm run test:e2e -- tests/expenses-quick-add.spec.ts --project=chromium
git diff --check
```

The Goal 3 board records the latest local results.

## Owner Manual Acceptance

Before production deployment, the owner/operator should run the full manual walkthrough from `documentation/expense_release_readiness_runbook_2026-06-13.md` in a staging or production-like HTTPS environment.

Record the result in release notes with:

- Browser and operating system.
- Whether the flow ran in a normal tab, installed PWA, or both.
- Trip ID used for the walkthrough.
- Confirmation that offline refresh preserved pending mutations.
- Confirmation that reconnect synced each mutation once.
- Confirmation that conflict handling appeared instead of overwriting a server-side change.
- Any step skipped and the reason.

## Known Release Limits

- Production deployment is intentionally not performed by this goal.
- Production destructive reset is intentionally not performed by this goal.
- Real installed-PWA verification still needs owner/operator device access.
- Settlement payment recording, receipt upload/OCR, and automatic conflict merging are outside V1.
- `npm audit` currently reports one high severity dependency advisory during test setup; this did not fail release-readiness verification but should be addressed as dependency maintenance before or shortly after rollout.
