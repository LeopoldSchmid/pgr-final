# Expense System V1 Release Readiness Runbook

Stand: 2026-06-13

## Scope

This runbook prepares the product owner/operator to release Expense System V1. It does not perform production deployment and does not perform destructive production data reset.

Use it together with:

- `documentation/expense_goal_3_release_readiness_reset_operational_trust_2026-06-10.md`
- `documentation/expense_release_acceptance_2026-06-13.md`
- `documentation/testing.md`
- `documentation/delivery_standards.md`
- `documentation/decision_log.md`

## Release Decision

Expense System V1 replaces the old expense CRUD flow. The release path is:

- `/expenses` for the modern expense app.
- Same-origin Rails JSON APIs under `/api/trips/:trip_id/...`.
- Rails-served PWA manifest and service worker.
- Kamal-managed Rails deployment.

Old expense create/edit/delete/duplicate and old secondary pages are release-compatible only as redirects back to `/expenses`.

## Old Data Reset And Export

Existing production expense data is considered test data for V1. A careful production migration is not required.

Before rollout, the operator should choose one of these non-destructive backup paths:

```bash
bin/kamal console
```

Inside the production console, inspect and export if desired:

```ruby
trip = Trip.find_by(name: "THE_TEST_TRIP_NAME")
trip&.expenses&.includes(:expense_splits, :expense_participants)&.as_json
trip&.trip_people&.as_json
```

If the test trip is still useful, save the output outside the server before rollout. If it is not useful, record that the old data was intentionally ignored.

Do not seed fake expense data in production. Development and test fixtures/spec setup remain the place for exercise data.

## Kamal And Docker Build Notes

The production image must install JavaScript dependencies before Rails asset precompile because the expense app is bundled through `jsbundling-rails` and `esbuild`.

Expected build behavior:

- Docker build installs Ruby gems.
- Docker build installs Node/npm in the build stage.
- Docker build runs `npm ci`.
- Rails asset precompile invokes the JavaScript build and emits `app/assets/builds/expense_app.js` into compiled assets.
- Kamal keeps `asset_path: /rails/public/assets` so fingerprinted assets bridge between versions.

No separate frontend host, API service, native app build, external sync service, or external AI service is required for V1.

## PWA And Service Worker Operations

The service worker is served by Rails at `/service-worker` and registered by the expense bundle. It caches navigations with a network-first strategy and runtime assets with a cache-first strategy.

Before release, smoke test on HTTPS:

1. Open `/expenses` online.
2. Confirm the service worker registers in browser devtools.
3. Refresh once while online so the expense shell is cached.
4. Go offline in browser devtools.
5. Refresh `/expenses`.
6. Confirm the expense app shell appears and uses the cached snapshot when the API cannot be reached.

When changing service worker caching behavior, bump cache names in `app/javascript/custom_service_worker.js` so old cached assets are discarded on activation.

## Sync Failure Observability

Users see pending, failed, conflict, and rejected mutation states in the expense app.

Developers can inspect:

- Browser IndexedDB database `plangoreminisce-expenses`, store `pending_mutations`.
- Rails logs for `expense_client_mutation_sync_issue`, which is emitted for rejected and conflict sync attempts with `trip_id`, `actor_id`, `client_uuid`, `mutation_type`, `status`, and JSON error details.
- Persisted `ClientMutation` records for accepted, duplicate, rejected, and conflict mutation handling.
- `ExpenseEvent` records for critical expense actions.

Useful Rails console checks:

```ruby
trip = Trip.find(<trip_id>)
trip.client_mutations.order(created_at: :desc).limit(20).pluck(:client_uuid, :mutation_type, :status, :error_details)
trip.client_mutations.where(status: %w[rejected conflict]).order(created_at: :desc).pluck(:client_uuid, :mutation_type, :status, :error_details)
trip.expense_events.order(created_at: :desc).limit(20).pluck(:event_type, :expense_id, :actor_id, :payload)
```

Operational rule: a locally saved mutation must either sync, remain visible as pending/failed, or become visible as conflict/rejected. Silent disappearance is a release blocker.

## Required Automated Checks

Run before owner deployment:

```bash
npm test
RAILS_ENV=test bin/rails db:drop db:create db:migrate
RAILS_ENV=test bin/rails test test/controllers/expenses_controller_test.rb test/helpers/navigation_helper_test.rb test/controllers/api/expense_snapshots_controller_test.rb test/controllers/api/expense_client_mutations_controller_test.rb test/controllers/api/trip_people_controller_test.rb test/controllers/api/split_groups_controller_test.rb
npm run test:e2e -- tests/expenses-quick-add.spec.ts --project=chromium
git diff --check
```

For a broader release gate, also run:

```bash
PARALLEL_WORKERS=1 bin/rails test
```

## Manual Acceptance Walkthrough

Run this in a production-like local or staging environment before production deployment:

1. Open the app in a normal browser tab and load an active trip online.
2. Confirm the same expense workflow can launch from the installed PWA on at least one supported browser.
3. Add a pending person.
4. Add an equal split expense.
5. Add an exact amount unequal split expense.
6. Add a share/weight unequal split expense.
7. Add a percentage split expense.
8. Add an expense paid by someone else.
9. Create a quick-capture draft without a completed split and confirm it is excluded from settlement, if that draft path is enabled.
10. Go offline in the normal browser tab after prior online use.
11. Add an expense offline.
12. Edit that offline-created pending expense before reconnecting, if pending-edit UX is enabled.
13. Edit a previously synced cached expense while offline.
14. Void a previously synced cached expense while offline.
15. Refresh while offline and confirm pending mutations remain.
16. Reconnect.
17. Confirm each mutation syncs once.
18. Retry sync and confirm no duplicate appears.
19. Simulate a server-side change and confirm an offline edit conflict is shown instead of overwritten.
20. Link an invited/pending person to a user.
21. Confirm historical balances remain continuous.
22. Run the retroactive include assistant on selected expenses and verify the preview before applying.

If a step is not directly runnable by the implementation agent because it needs staging, a device install, or production-like credentials, the product owner/operator should run it and record the result in the release notes.

## Known V1 Limits

- Production deployment is operator-owned and outside this goal.
- Production destructive reset is operator-owned and outside this goal.
- Settlement payment recording is not required for V1.
- Receipt upload/OCR is not required for V1.
- Automatic conflict merging is not required for V1.
