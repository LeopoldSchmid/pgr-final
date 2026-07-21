# T005 — Launch Work Packages and First Worker Contract

Status: complete

Decision date: 2026-07-21

## Verdict

Implementation may begin, but the largest safe first slice is **recovery of the existing mixed Expense release candidate**, not branding, billing or outreach. The current tree still combines committed, staged, unstaged and untracked Expense/PWA work. On activation of T005, `bin/rails test` reported 234 runs, 378 assertions, 2 failures and 92 errors; the dominant error is invalid foreign-key fixture state involving trip people, trip members and sessions. `npm test` is green with two JavaScript suites.

No prospect outreach is authorized. Production writes and destructive data actions remain gated.

## Sequenced launch backlog

### Package 1 — Recover and prove Expense V1

Reconcile the existing Expense domain/API/frontend/PWA layers without discarding owner work. Restore a clean test database contract, make the full Rails and Expense browser gates green, verify the supported offline/conflict behavior, and leave an explainable diff and release receipt.

### Package 2 — Lock the supported Wegsam surface

Apply the focused Wegsam working brand, introduce the `wegsam.duzend.net` host path/configuration, hide Packing, Itinerary, Templates and Albums, align German/English navigation and public copy, and remove unsupported claims. Do not create a broad design system.

### Package 3 — Prove organizer and invitee foundations

Create the supported-resource authorization matrix and regression coverage; refine registration, trip creation/switching, date coordination, invitation delivery/acceptance and member roles as one mobile-first organizer-to-invitee journey.

### Package 4 — Prove meal and shopping group value

Refine and verify meal planning, recipe use, shopping synchronization, assignments and partial purchases as a coherent multi-user mobile journey. Resolve only defects or UX friction within that corridor.

### Package 5 — Prove core Memories and user-controlled data

Refine journal/photo capture, feed, favorites and supported map/gallery behavior; prove real-phone uploads and independent preservation/export of originals. Add the user-facing download/deletion behavior required by the approved archive promise.

### Package 6 — Add the paid-access corridor

Implement Stripe Managed Payments test-mode Checkout/Billing/Portal, idempotent lifecycle handling, organizer entitlement, invited-member access, cancellation, refunds and the free read-only archive. Cover success, failure, duplicate webhook, expiry and resubscription.

### Package 7 — Public trust and lifecycle

Add reviewed German/English offer, price, renewal/cancellation, refund/withdrawal, privacy, terms, imprint and support surfaces. Remove avoidable third-party asset leakage and add privacy-safe funnel instrumentation. Professional/legal approval remains a live-payment gate.

### Package 8 — Operations and staging

Restore isolated staging; automate and prove database plus Active Storage backup/restore; separately export the legacy trip originals; add monitoring, privacy-safe logging, SMTP proof, rollback and incident/support runbooks. Complete desktop and real-phone staging acceptance.

### Package 9 — Pre-launch audit and owner go/no-go

Run the complete discover-to-archive acceptance corridor. Only after all gates pass and the owner explicitly accepts the product may production payment activation, broad promotion or personal prospect outreach occur.

## First Worker package

### Objective

Turn the current mixed Expense V1 work into one coherent, regression-protected local release candidate while preserving all pre-existing changes. Diagnose and repair the fixture/database failure first, then resolve the remaining Rails and Expense E2E failures by correcting product or test behavior rather than weakening assertions.

### Allowed files

- `Gemfile`, `Gemfile.lock`, `package.json`, `package-lock.json`, `Procfile.dev`, `Dockerfile`, `playwright.config.ts`
- `app/controllers/expenses_controller.rb`
- `app/controllers/api/expense_client_mutations_controller.rb`
- `app/controllers/api/expense_snapshots_controller.rb`
- `app/controllers/api/retroactive_expense_inclusions_controller.rb`
- `app/controllers/api/split_groups_controller.rb`
- `app/controllers/api/trip_people_controller.rb`
- `app/controllers/pwa_controller.rb`
- `app/helpers/navigation_helper.rb`
- `app/javascript/custom_service_worker.js`
- `app/javascript/expense_application.ts`
- `app/javascript/controllers/expense_app_controller.ts`
- `app/javascript/expenses/**`
- `app/models/client_mutation.rb`, `app/models/expense.rb`, `app/models/expense_event.rb`, `app/models/expense_participant.rb`, `app/models/expense_split.rb`
- `app/models/split_group.rb`, `app/models/split_group_membership.rb`, `app/models/trip.rb`, `app/models/trip_person.rb`
- `app/services/expenses/**`
- `app/views/expenses/index.html.erb`, `app/views/shared/_secondary_navigation.html.erb`
- `app/views/layouts/application.html.erb` (added during execution after Playwright proved that the fixed desktop sidebar intercepted supported Expense controls because main content lacked the matching offset)
- `db/migrate/20260610000100_create_expense_ledger_foundation.rb`, `db/migrate/20260610000200_allow_expenses_without_legacy_payer.rb`, `db/schema.rb`
- `test/fixtures/**`
- Expense-related tests under `test/controllers`, `test/models`, `test/services`, `test/helpers` and `test/javascript`
- `test/integration/calendar_system_test.rb`
- `tests/expenses-quick-add.spec.ts`
- `documentation/expense_goal_3_release_readiness_reset_operational_trust_2026-06-10.md`, `documentation/expense_release_acceptance_2026-06-13.md`, `documentation/expense_release_readiness_runbook_2026-06-13.md`, `documentation/testing.md`, `documentation/decision_log.md`

Goal/state files remain PM-owned and are not Worker-editable.

### Verify

1. `bin/rails db:test:prepare`
2. `bin/rails test`
3. `npm test`
4. `npx playwright test tests/expenses-quick-add.spec.ts --project=chromium --workers=1 --reporter=list`
5. `git diff --check`
6. Record `git status --short` and explain every remaining staged/unstaged/untracked Expense file.

### Stop if

- Progress would require discarding, resetting or blindly replacing pre-existing staged/unstaged work.
- A schema change would risk existing production data without an explicit forward migration and rollback/backup explanation.
- A failure exposes ambiguity outside approved Expense V1 behavior rather than a diagnosable defect.
- Fixing the package requires edits outside the allowed files; return the exact additional path and reason to the PM.
- The same verification failure repeats twice without a materially new diagnosis.

## Dependencies and gates

- Package 1 precedes all product refinement because every later acceptance suite depends on a trustworthy baseline.
- Packages 2–5 precede paid access so entitlement is not built around unstable product behavior.
- Package 6 may use Stripe test mode before business registration; live mode may not.
- Packages 7–8 may proceed locally without outreach, but legal acceptance, credentials, DNS/production actions and spending retain their normal explicit gates.
- Package 9 alone can request an owner outreach decision.
