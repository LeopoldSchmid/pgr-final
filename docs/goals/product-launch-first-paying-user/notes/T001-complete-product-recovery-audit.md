# T001 — Complete Product and Recovery Audit

Date: 2026-07-16

## Executive verdict

PlanGoReminisce is a substantial, bootable Rails product rather than an early prototype. It already spans the full group-trip lifecycle and has unusually deep work in meal/shopping coordination and trustworthy offline expenses. It is not currently a coherent launch candidate, however. The main branch, staged work, unstaged work, untracked release artifacts, historical documentation, and three completed Expense GoalBuddy boards describe different realities. The current product breadth also exceeds the proven browser corridor by a wide margin.

The best recovery framing is therefore: preserve the differentiated collaborative-trip core, reconcile one trustworthy source-controlled release candidate, explicitly choose which visible product areas are supported, then close the end-to-end discover → register → create/join trip → receive core value → pay funnel. Adding more unrelated features before this reconciliation would deepen uncertainty rather than improve launch readiness.

## Product purpose and target-user hypothesis

Repository evidence consistently describes a mobile-first shared trip companion for groups of friends. Its organizing idea is the trip lifecycle:

- **Plan:** dates and availability, participants, discussions, recipes, meal calendar, shopping planning and shopping execution.
- **Go:** fast in-trip capture, shared expenses, photos, journal entries and practical coordination.
- **Reminisce:** memories, favorites, maps, galleries and reports after the trip.

The strongest evidenced user hypothesis is not “any traveler who needs an itinerary.” It is a recurring group organizer and their friends who currently coordinate a multi-day group trip across chat, notes, spreadsheets, Splitwise-like expense tools and photo collections. The repository does not yet contain evidence of validated demand, a sharply worded painful job, a price, or a paid buyer segment; T002 must test those commercial hypotheses rather than treat the broad README promise as validated.

## Architecture and feature map

Current implementation scale observed by Brakeman: Rails 8.1.0, 43 controllers, 36 models, 108 templates. The frontend is mostly server-rendered Hotwire/Stimulus/Tailwind, with a bundled TypeScript island and IndexedDB queue for the new expense application. SQLite, Active Storage, Solid Queue, Solid Cache and Solid Cable support a single-host Kamal deployment.

### Identity and collaboration

- Password authentication, password reset, registration, signed persistent session cookie and locale selection exist.
- Invitations can register or authenticate a recipient and add them to a trip with guest/member/admin roles.
- Trip ownership, membership and a session-backed current-trip context exist.
- Access control is implemented in multiple controller-specific styles rather than one consistently proven policy layer.

### Trip planning

- Trip creation/editing, participants, date proposals, availability, voting and discussions exist.
- Meal planning is implemented as persisted calendar entries with recipes, assignees, duplication, drift handling and shopping synchronization.
- Shopping is a comparatively mature domain: requirements, multiple lists, assignments, partial purchase tracking, manual items and synchronization services have focused model/controller/system coverage.
- `Packing`, `Itinerary` and `Templates` are visible “Coming soon” pages backed by empty arrays. Trip-template copying contains an explicit TODO for shopping lists, journal entries and other content.

### In-trip use and expenses

- Journal entries, photo/video attachments, comments, votes, capture, gallery and map views exist.
- A new expense ledger backend is committed in `c2f19dc`; the TypeScript/offline/PWA frontend and release cleanup remain staged/unstaged.
- The expense domain includes trip people who may be registered, invited or placeholders; equal/exact/share/percentage splits; ledger balances; settlement suggestions; revisions; events; idempotent client mutations; conflicts; offline create/edit/void; and roster/split-group management.
- Legacy expense routes are being redirected to the new application, but this release state is not yet a committed coherent baseline and its E2E gate currently fails.

### Memories and post-trip use

- Unified journal/attachment feeds, favorites, maps, trip gallery/report routes and exports exist.
- `Memories#albums` is a visible “Coming soon” page.
- The exact durable value after a trip is broader in navigation than the automated evidence proves.

### Platform and operations

- PWA manifest/service worker, mobile navigation, Kamal, Docker, SSL, local file storage and staging configuration exist.
- Production health at `https://plangoreminisce.duzend.net/up` returned HTTP 200 on 2026-07-16.
- Staging health at `https://staging.plangoreminisce.duzend.net/up` returned HTTP 502 on the same check.
- No payment/checkout/subscription implementation, product analytics, error-monitoring integration, terms, privacy notice or imprint was found.

## End-to-end journey inventory

| Journey stage | Current evidence | Verdict / risk |
| --- | --- | --- |
| Discover | Public landing page says “Plan. Go. Reminisce.” and presents three generic lifecycle benefits with registration/sign-in CTAs. | Functional basic entry, but no focused segment, proof, supported-scope explanation, price or paid offer. |
| Register / sign in | Rails authentication, reset and invitation-aware registration exist. | Plausible but under-proven: no dedicated controller/system coverage for sessions, registrations or passwords. |
| Create or join trip | Trip CRUD, membership, invitations and switching exist; several controller tests cover trips/switching/invitations. | Core exists. Email delivery and full invited-user browser journey are not production-proven. |
| Plan dates | Date proposals, availability and voting exist. | Red baseline: all three stale calendar integration checks fail/error due changed redirect, missing expected heading and obsolete route helper. |
| Plan meals / shopping | Deep domain/UI implementation with 3 passing Rails system tests and substantial controller/model/service coverage. | Strongest currently committed product corridor, though real mobile group use and staging remain unproven. |
| Use expenses during trip | Deep backend plus staged TypeScript/offline/PWA work. Unit JS checks pass. | High potential but not releasable today: first of 16 Playwright scenarios fails, preventing the remaining 15 from running. Manual HTTPS/device acceptance was explicitly left to the owner. |
| Capture photos / memories | Uploads, journal, comments, gallery, map and memory feed exist. | Core exists, but iPhone upload is a historical release risk and lacks real-device proof; several controllers have no direct coverage. |
| Post-trip value | Favorites, gallery, map, report/export surfaces exist. | Broad but weakly proven; albums remain placeholder. |
| Pay for product | No repository implementation or offer found. | Entire funnel stage missing. Monetization cannot be described as launch-ready. |
| Operate safely | Production health is green; staging is 502; local-disk persistence and runbooks exist. | No current staging proof, automated backup evidence, monitoring, support process or rollback drill. |

## Current recovery and dirty-worktree reconciliation

The repository is on `master`, one commit ahead of `origin/master`:

- `c2f19dc feat: implement API controllers for expense management and trip functionalities` is the committed Expense Goal 1/backend layer.
- The index contains roughly **3,576 inserted / 292 deleted lines across 24 files**, primarily the Expense Goal 2 TypeScript/IndexedDB/PWA frontend, JS build tooling, tests and its completed board.
- The working tree adds roughly **461 inserted / 140 deleted lines across 22 files**, primarily release routing, navigation, observability, Docker build adjustments, UI refinements and E2E/controller updates associated with Expense Goal 3.
- Goal 3's board and two release documents are untracked; several tracked files are both staged and modified (`AM`/`MM`).
- All three historical Expense boards say `done`, but the new broad audit found the current Expense Playwright gate red. Those boards prove substantial completed work packages; they do not prove that the present mixed worktree is a publishable release.

No product files were edited during T001. Running `npm test` regenerated ignored assets under `app/assets/builds/` and ignored files under `tmp`; the tracked status remained the pre-existing product diff plus this new GoalBuddy control surface.

## Verification baseline on 2026-07-16

### Passing

- `npm test`: pass; expense bundle builds and 2 JavaScript tests pass.
- `bin/rails test test/system` outside the socket-restricted sandbox: 3 runs, 7 assertions, 0 failures/errors.
- `bundle exec brakeman --no-pager --no-exit-on-warn`: completes with 1 medium-confidence warning and no scanner error.
- Production `/up`: HTTP 200.

### Failing or incomplete

- `PARALLEL_WORKERS=1 bin/rails test`: 234 runs, 670 assertions, **2 failures and 1 error**, all in `test/integration/calendar_system_test.rb`.
- `npx playwright test tests/expenses-quick-add.spec.ts --project=chromium --workers=1 --reporter=list`: **1 failed, 15 did not run**. The first preview test expects `43.20 EUR` and description text that are absent from the rendered quick preview.
- `bin/rubocop`: 232 files inspected, **707 offenses, 628 autocorrectable**. This is largely pre-existing style debt but makes the CI lint job red today.
- `bin/brakeman --no-pager`: exits before scanning because the binstub forces `--ensure-latest` and locked Brakeman 7.1.0 is no longer latest. CI uses this exact command, so the security job is red until dependency/policy handling changes. A direct scan reports one medium-confidence `PermitAttributes` warning for allowing invitation `role`; model validation constrains values, but role assignment/authorization still deserves explicit review.
- `bin/importmap audit`: current vulnerability state unverified. The audit requires sending dependency metadata to registry.npmjs.org; the execution environment rejected that external disclosure without explicit owner approval. Do not interpret this as pass or fail.
- Staging `/up`: HTTP 502.

### CI mismatch

`.github/workflows/ci.yml` runs Brakeman/importmap/Rubocop and is configured for pushes to `main`, while the repository's active/default-looking local and remote branch is `master`. Pull requests still trigger it, but ordinary pushes to `master` do not match the declared push branch. The workflow also lacks the Rails test suite, JavaScript unit tests and Playwright/system tests, so even a green workflow would not prove the current release gate.

## Technical, security, privacy and operational findings

1. **Source-of-truth failure is the primary recovery risk.** A release cannot safely be cut until the committed/staged/unstaged Goal 1–3 layers are reconciled, verified and intentionally committed or reworked.
2. **Automated evidence is materially narrower than product breadth.** There is no direct controller coverage for sessions, registrations, passwords, date proposals/votes, discussions/replies, recipes/library, journal entries, search, profile, timeline and several other user-facing controllers. Browser proof is one 3-test meal file and one currently red 16-test expense file.
3. **Authorization patterns are inconsistent.** Some controllers scope through `Current.user`, others load `Trip.find` and authorize membership separately, and `JournalEntriesController` scopes trips only through ownership even though the product promises member collaboration. This needs a systematic access matrix, not only isolated fixes.
4. **Visible scope overpromises.** Packing, itinerary, templates and albums are navigable placeholders, while README claims include packing, reusable templates, offline capability and other breadth that current evidence does not uniformly support.
5. **Security gate mechanics are unhealthy.** The checked-in Brakeman command is guaranteed to fail whenever the locked version is not latest; Rubocop has hundreds of offenses; dependency auditing has no captured current result.
6. **Privacy/legal readiness is absent.** The app processes accounts, invitee emails, trip dates/locations, photos, journal text and expense/relationship data, and loads Google Fonts plus multiple CDN scripts/styles. No privacy notice, terms, imprint, retention/deletion/export policy or consent/cookie position was found. Germany/EU publication makes this a launch-gate category requiring owner/legal decisions, not a cosmetic document task.
7. **Operations are not yet trustworthy.** Staging is down; production uses a single local SQLite/Active Storage volume; no automated backup/restore evidence, uptime/error monitoring, incident/support path or verified rollback was found. The deploy config uses a remote root SSH builder and a machine-specific key path. SMTP configuration exists in Rails, but the visible Kamal secret list contains only `RAILS_MASTER_KEY`; invitation mail delivery needs an environment-level proof without exposing secrets.
8. **External/offline behavior is split.** The layout loads Google Fonts and multiple CDN assets, while offline behavior is concentrated in the expense service worker. The product-level meaning of “offline” must be stated narrowly or broadened and tested.
9. **Documentation has valuable history but conflicting truth.** `status_quo.md` reports an old 106-test green corridor; the current run is 234 tests with calendar failures. README roadmap marks implemented areas as incomplete, claims a missing `LICENSE` file, references absent API docs and describes PostgreSQL scaling while the active production path intentionally uses SQLite.

## Ranked launch blockers

### P0 — before meaningful launch implementation

1. Reconcile and protect the mixed Expense worktree into one explainable release candidate; do not overwrite the staged/unstaged owner work.
2. Define the owner-approved supported product scope and remove, hide or clearly label every unsupported visible path.
3. Restore an honest gate: Rails suite, Expense E2E, lint/security policy and current dependency audit outcome.
4. Establish a working isolated staging environment and prove the chosen core group journey there, including invitation mail and mobile behavior.
5. Perform an authorization/access-control matrix for every supported collaborative resource.

### P0 — jointly with commercial/legal work

6. Choose a concrete buyer, painful job and paid offer; implement the missing price/checkout/access/payment lifecycle.
7. Close EU/Germany publication basics for privacy, terms/imprint, external assets, data retention/deletion/export and payment processing.
8. Add backup/restore, monitoring, operational ownership, support contact and rollback evidence.

### High-value refinements after scope decision

1. First-run onboarding that creates or joins a trip and reaches one meaningful collaborative action quickly.
2. A coherent lifecycle navigation story that does not expose placeholders or competing legacy/context routes.
3. Real-phone refinement of invitation, meal/shopping, expense and photo capture flows.
4. Focused landing/offer copy aligned to the chosen buyer and strongest differentiated workflow.
5. Product analytics around discover → register → trip created/joined → collaborator active → core-value event → checkout/payment.

### Default defer candidates unless owner evidence promotes them

- Building packing, itinerary, templates or albums merely because placeholders exist.
- Native wrappers, OCR, bank import, AI parsing, automatic multi-currency rates or automatic conflict merging.
- Broad architectural rewrites, PostgreSQL migration, component-framework adoption or generic design polish.
- Deep cleanup of all 707 style offenses before the formatter/lint policy and launch scope are decided.

## Questions requiring Judge/owner resolution

1. Which narrow “core value event” will define a successful paid trip group: collaborative meal/shopping planning, trustworthy shared expenses, the complete Plan–Go–Reminisce lifecycle, or a deliberately chosen bundle?
2. Is the payer the trip organizer, every member, or a group/trip purchase? This changes permissions, onboarding, checkout and value framing.
3. Should the currently public production instance be treated as legacy data to migrate, a beta to preserve, or disposable test state after backup?
4. Which visible placeholders are genuinely part of the desired product rather than old ambition?
5. What evidence, if any, already exists outside the repository about real users, previous trips, pain points, willingness to pay or acquisition channels?

## Evidence index

- Product/architecture: `README.md`, `documentation/status_quo.md`, `documentation/stabilization_plan.md`, `documentation/plangoreminisce-architecture.md`, `config/routes.rb`.
- Product decisions: `documentation/decision_log.md`, `documentation/meal_plan_finalization_spec_2026-04-17.md`, `documentation/expense_system_v1_plan_2026-06-10.md`.
- Recovery state: `git log`, `git status`, staged and unstaged diffs, three `docs/goals/expense-*` boards and their release notes.
- User surfaces: `app/views/home/index.html.erb`, shared navigation, plans/memories/expenses views and corresponding controllers.
- Security/operations: authentication concern, invitation/member models/controllers, `config/deploy*.yml`, `config/environments/production.rb`, `Dockerfile`, `DEPLOYMENT.md` and staging documents.
- Verification: the exact commands and results recorded above.
