# Expense Goal 3: Release Readiness, Reset, and Operational Trust

Stand: 2026-06-10

## Purpose

Make the new Expense System V1 ready for the product owner/operator to ship: prepare reset/export handling for old test expense data, document deployment implications, validate PWA/offline behavior in production-like conditions, document operations, and define final release acceptance.

This goal should run after Goals 1 and 2 are functionally complete, though deploy-readiness work can be prepared earlier. Actual production deployment is explicitly out of scope for the implementation team and remains owned by the product owner/operator.

## Shared Product Context

PlanGoReminisce needs a modern, mobile-first, trustworthy travel ledger. Users must be able to include people before those people have registered, split costs in realistic ways, understand who owes whom, and trust that offline changes will not vanish or duplicate when the app syncs.

The current expense implementation should be replaced, not polished. There is only one test trip on production and no real user base for the old expense system, so V1 does not require a careful production data migration.

## Scope

- Old expense data reset/export decision.
- Feature flag or controlled rollout.
- Backward compatibility decision for old expense views.
- Production deploy compatibility notes for Kamal.
- Monitoring/logging for sync failures.
- Manual test scripts for offline scenarios.
- Documentation for users and developers.
- Final acceptance across Goals 1 and 2.

## Deploy-Readiness Requirements

The current Kamal deployment remains the deployment target, but the implementation team should not perform the production deployment as part of this goal.

Expected implementation changes that must be documented for the product owner/operator:

- Add `jsbundling-rails` with `esbuild`.
- Install frontend dependencies during Docker build.
- Ensure production asset compilation includes the expense bundle.
- Keep PWA/service worker assets served by Rails.
- Keep the expense API same-origin to preserve cookie auth and CSRF simplicity.
- Keep HTTPS enabled through the existing Kamal proxy.

No required V1 infrastructure:

- no separate frontend host
- no separate API service
- no native app build
- no external sync service
- no external AI service

Potential later infrastructure:

- separate Solid Queue worker for heavier jobs
- receipt OCR provider
- push notification keys
- native shells if app store distribution becomes important

## Old Data Reset Requirements

The existing production expense data is not real user data. A careful migration is not required for V1.

Required rollout behavior:

- Before rollout, take a database backup or export of the one test trip if it is still useful.
- Remove or ignore old expense records as part of replacing the old implementation.
- Create new trip-person records from trip owners and members for active trips.
- Seed or create no fake expense data in production.
- Document the reset in `documentation/decision_log.md`.
- Keep enough local seed/test data to exercise the new expense flows in development.

## Backward Compatibility Requirements

- Old expense routes must either redirect to the new expense app or be removed safely.
- Existing trip navigation must point to the new expense app.
- Any old expense views left in the repository must be clearly unused or removed.
- If a feature flag is used, the fallback behavior must be explicit and temporary.

## Quality Bar

Money behavior must be tested more rigorously than normal CRUD.

The existing project test approach must continue:

- Rails tests cover backend domain logic, services, API validation, authorization, and model behavior.
- Rails system tests continue to use Playwright via `capybara-playwright-driver`.
- Standalone Playwright specs under `tests/` may be added for browser/PWA/offline flows that are easier to express directly in Playwright.
- No Selenium reintroduction.
- Follow `documentation/testing.md` and `documentation/delivery_standards.md`.

Required automated coverage across Goals 1 and 2:

- unit/service tests for split math
- unit/service tests for settlement math
- unit/service tests for idempotent sync
- model tests for trip-person linking and merging
- controller/request tests for authorization and API validation
- frontend parser, split editor, IndexedDB queue, and conflict-state tests
- Playwright online and offline walkthroughs

## Required Manual Acceptance Walkthrough

Run this in a production-like local or staging environment before the product owner/operator performs the actual production deployment.

1. Open the app in a normal browser tab and load an active trip online.
2. Confirm the same expense workflow can also be launched from the installed PWA on at least one supported browser.
3. Add a pending person.
4. Add an equal split expense.
5. Add an exact amount unequal split expense.
6. Add a share/weight unequal split expense.
7. Add a percentage split expense.
8. Add an expense paid by someone else.
9. Create a quick-capture draft without a completed split and confirm it is excluded from settlement.
10. Go offline in the normal browser tab after prior online use.
11. Add an expense offline.
12. Edit that offline-created pending expense before reconnecting.
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

## Release Acceptance Criteria

- All Goal 1 backend acceptance criteria pass.
- All Goal 2 frontend acceptance criteria pass.
- Old expense test data is backed up/exported if desired, then reset or ignored according to a documented decision.
- Old expense routes either redirect to the new expense app or are removed safely.
- The new expense app is available from the existing trip navigation.
- The PWA manifest and service worker pass a production smoke test.
- The product owner/operator has clear notes for the Kamal deploy and asset pipeline changes.
- Offline create, edit, void, retry, and conflict handling are verified in a production-like environment.
- Sync failure logging is available to developers.
- User-facing errors explain what happened and how to retry.
- There is no known path where a locally saved expense mutation disappears without either syncing or showing an actionable error.

## Operational Acceptance Criteria

- Deployment documentation explains any new JS build step.
- The Dockerfile/Kamal build path installs frontend dependencies and compiles the expense bundle.
- A developer can identify sync failures from logs or persisted mutation state.
- PWA/service worker cache versioning is documented well enough to avoid stale asset confusion during deploys.
- The release decision and old data reset are recorded in `documentation/decision_log.md`.
- Any known limitation is documented before release.

## Dependencies On Other Goals

- Goal 1 must provide the backend domain, tests, sync API, conflict behavior, and old data reset mechanics.
- Goal 2 must provide the frontend app, offline queue, PWA behavior, and browser-facing test coverage.

## Done For Goal 3

Goal 3 is complete when the new expense system has passed automated tests, production-like offline/manual acceptance, old data reset/export handling, route cleanup, deploy-readiness documentation, and operational documentation. Actual production deployment is not part of this goal.
