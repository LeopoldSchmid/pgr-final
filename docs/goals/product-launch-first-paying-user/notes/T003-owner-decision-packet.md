# T003 — Skeptical Owner Decision Packet

Date: 2026-07-16

## Judge decision

**Decision: approve progression to an explicit owner gate; do not authorize implementation yet.**

The evidence supports a paid launch path, but not a launch of the current worktree and not a promise that every visible feature is finished. The product's strongest coherent shape is a mobile-first shared operations hub for self-organized friend-group trips. The launch plan should preserve all five lifecycle areas only where they provide a working core; it should hide unfinished ambitions and resist a broad redesign.

The €29 per-trip recommendation, the precise supported scope, payment provider, legal/business identity, production-data treatment and acquisition authority are owner choices. T004 must record them before T005 defines allowed files or Worker packages.

## Current-state verdict

### What is genuinely strong

1. **A real domain, not a demo:** Trips, people, invitations, dates, meal planning, shopping, expense ledger and memories share a meaningful group context.
2. **Distinctive integrated wedge:** Meal → shopping coordination plus trustworthy group expenses is more differentiated than generic itinerary planning or expense splitting alone.
3. **Serious expense architecture:** Pending people, flexible splits, idempotent offline mutations, conflict states and ledger events solve real travel conditions.
4. **Mobile/lifecycle intent:** The product is designed for before, during and after the trip and already has a deployed production instance.
5. **Substantial verification substrate:** 234 Rails tests, focused shopping tests, Rails system tests and a 16-scenario expense E2E file exist even though the present gate is not green.

### What prevents selling today

1. There is no single source-controlled release candidate; Expense Goal 1–3 work is split across committed, staged, unstaged and untracked layers.
2. Rails calendar coverage and Expense E2E are red; CI does not represent the real release gate and Rubocop/Brakeman mechanics are red.
3. Staging returns 502.
4. No checkout, entitlement, pricing, invoice/confirmation, refund, support, analytics or payment failure lifecycle exists.
5. No imprint, privacy, terms/service description, withdrawal handling or processor/data-retention workflow exists.
6. Authorization and browser coverage are inconsistent across the supported collaborative surface.
7. Public navigation and README overstate unfinished areas.

## Recommended paid-beta product definition

### Audience

German-speaking organizer of a 5–15-person self-organized group trip within the next 90 days, especially a holiday home, cabin weekend, festival/camping trip or recurring friend-group trip.

### Paid promise

> Ein gemeinsamer Ort für eure Gruppenreise: Essen und Einkäufe koordinieren, gemeinsame Ausgaben zuverlässig im Blick behalten und die wichtigsten Erinnerungen festhalten.

This deliberately avoids promising route optimization, booking import, flights, comprehensive itinerary management, universal offline access or a native app.

### Recommended supported launch scope

#### Discover and buy

- Focused German offer/landing page.
- Transparent €29 one-time trip price and scope.
- Imprint, privacy, terms/service description, withdrawal/refund and support contact.
- Hosted checkout, signed/idempotent fulfillment, confirmation and payment/refund state.

#### Enter the product

- Registration, sign-in/reset and first-run onboarding.
- Create a trip or accept an invitation.
- Organizer owns the paid trip entitlement; invited members do not pay.
- Clear empty states and one short path to the first collaborative action.

#### Trip core

- Trip details, participants, invitations and date coordination.
- Mobile-safe trip switching and navigation.
- Discussions may remain available if they pass the access/test matrix, but should not be a paid headline or receive major refinement.

#### Plans core

- Meal calendar and recipes required for real planned meals.
- Shopping Plan, multiple lists, assignments, partial purchase and manual additions.
- Meal → shopping synchronization and drift/completion behavior.

#### Expense core

- Finish and reconcile the current V1 worktree.
- Quick capture, equal/exact/share/percentage splits, pending people, balances/settlements, activity and offline create/edit/void/conflict behavior.
- Do not promise OCR, bank import, automatic currency conversion or payment transfers.

#### Memories core

- Journal/photo capture, shared feed, favorites and map/gallery behavior needed for the advertised “memories” promise.
- Real-phone photo upload is a hard gate.
- Album organization is not required.

#### Operations

- Working staging, production backup/restore, monitoring, logs without sensitive content, rollback and owner support process.
- Privacy-safe first-party funnel events.

### Hide or defer by default

- Packing.
- Itinerary.
- Templates and incomplete trip-copy ambition.
- Memory albums.
- Broad redesign/rebrand.
- Native wrappers, universal offline, AI/OCR, bank import, payment transfers and automatic exchange rates.
- PostgreSQL migration and architecture rewrites.
- Cleaning every historical Rubocop offense before a bounded lint policy is chosen.

## Why this scope is not “minimum at any cost”

The recommendation keeps meaningful refinement in every supported core flow. It does not ship a shell around payments. It also refuses to turn every old aspiration into a launch dependency. The refinement test is:

> Does this change materially improve the paying organizer's ability to get the group onboarded, coordinate food/shopping, trust expenses, preserve the core memory, or trust the service?

If yes, it can enter a launch package. If it only makes an unsupported area prettier or broadens the promise, it stays deferred.

## Alternatives and tradeoffs

### Alternative 1 — Meals and shopping only

- Smaller and more differentiated.
- Fastest technical path.
- Lower perceived willingness to pay and weak use during/after the trip.
- Would underuse the already substantial Expense work and contradict the owner's desire to assess/finish the application as a whole.

### Alternative 2 — Complete Plan–Go–Reminisce platform

- Strong brand narrative and long-term ambition.
- Requires completing itinerary, packing, templates, albums and much broader evidence before honest launch.
- Highest risk of returning to endless refinement; rejected for the first paid launch.

### Alternative 3 — Expense-first product

- Clear immediate pain and advanced backend.
- Directly competes with mature free Splitwise behavior; current E2E is red.
- Rejected as primary positioning, retained as a central part of the integrated value.

## Proposed offer and price test

### Recommended

**Founding Trip Pass — €29 one time per trip, all invited participants included.**

Recommended boundaries:

- no automatic renewal;
- organizer is purchaser and trip-pass owner;
- collaborators get full supported-trip participation;
- no coupon/free “friend payment” for the oracle;
- one clearly stated support period and archive/retention rule;
- price shown as the actual consumer total;
- reassess only after meaningful evidence, not after one objection.

### Evidence thresholds

- Success for the current goal: one genuine external €29 payment plus onboarding and completed group core-value event.
- Continue price validation: approach 10 qualified organizers; aim for at least 3 serious walkthroughs and document every rejection reason.
- Reconsider the offer if 10 qualified prospects understand the product and none will pay; do not respond by adding random features.
- Consider annual pricing only after repeated-trip intent appears.

## Publication route

1. Reconcile the worktree and establish a green local candidate.
2. Restore isolated staging and run the complete paid funnel with provider test mode.
3. Back up current production data and make an explicit preserve/migrate/reset decision.
4. Deploy the paid-beta candidate behind the focused public offer.
5. Invite the first qualified prospects personally.
6. Record privacy-safe funnel evidence and complete the first paid core journey.

Do not perform a broad anonymous launch before the founder-led funnel works.

## Payment recommendation

The Judge does not silently choose the provider:

- **Stripe Checkout:** lower fee and straightforward Rails integration; owner remains responsible for merchant/tax/billing operations.
- **Paddle:** higher fee, merchant-of-record tax/payment administration; requires approval/onboarding and still does not replace product privacy/imprint/terms duties.

Recommended decision rule: choose the first provider for which the owner can truthfully complete business verification and consumer/tax obligations with acceptable effort. Implement one provider only.

## First-customer experiment

1. Owner identifies ten real organizers with a qualifying trip inside 90 days.
2. Conduct a short problem walkthrough before demoing.
3. Show a seeded trip matching the person's actual group.
4. Offer the €29 pass directly.
5. Concierge-onboard purchaser and one collaborator without hiding product friction.
6. Complete and record the core event:
   - organizer paid and created the trip;
   - at least two other people joined;
   - either one meal/shopping loop was completed or three accepted shared expenses involved at least two people.
7. Ask what existing tools were replaced and whether the organizer would use/pay again.

## Ranked work after owner approval

### Phase 0 — Recovery baseline

1. Snapshot and reconcile committed/staged/unstaged/untracked Expense work.
2. Fix the Rails/calendar and Expense E2E baselines.
3. Define selected-scope lint/security/dependency gates and align CI with `master` or intentionally rename the branch.

### Phase 1 — Supported product corridor

1. Hide deferred placeholders and align navigation/copy.
2. Build the access-control matrix and regression coverage.
3. Refine the real-phone organizer → invitee → meal/shopping → expense → memory journey.

### Phase 2 — Paid/publication corridor

1. Offer, checkout, fulfillment/entitlement and confirmation/refund behavior.
2. Legal/privacy/support surfaces and data-rights behavior.
3. Funnel events, monitoring, backup/restore and staging proof.

### Phase 3 — Production and acquisition

1. Production-data decision, backup, deploy and rollback readiness.
2. Test purchase, then real founder-led outreach.
3. First genuine paid journey and final audit.

## Required production-readiness gates

1. One clean, intentional release diff/commit chain; no unexplained `AM`/`MM` state.
2. Database migration and rollback/backup proof.
3. Green Rails, JS, selected system/Playwright and payment/entitlement suites.
4. Current security/dependency scan outcomes; no CI command that fails only because “latest” changed.
5. Authorization matrix for every supported resource and role.
6. Staging HTTPS walkthrough on desktop and real phone, including invitation email, photo upload and expense offline/reconnect.
7. Checkout test-mode success/failure/duplicate/webhook/refund paths.
8. Price, terms, withdrawal/refund and confirmation correctness.
9. Privacy notice, imprint, processor inventory, deletion/export/retention operations.
10. Monitoring, support, backup/restore and rollback contacts/actions.
11. Production smoke plus privacy-safe oracle instrumentation.

## Exact owner decisions required at T004

1. **Positioning:** approve the self-organized group-trip operations hub, or choose the narrower meal/shopping alternative.
2. **Supported scope:** approve the listed Trip + Meals/Shopping + Expenses + core Memories corridor and hide Packing/Itinerary/Templates/Albums.
3. **Price:** approve €29 one-time per trip with invitees included, or name the first price/model.
4. **Provider:** Stripe or Paddle, based on the owner's business/tax setup and successful provider onboarding.
5. **Selling identity:** legal/business entity, country and whether the initial paid beta is Germany/German only.
6. **Access/retention:** how long paid trip editing and post-trip archive access last.
7. **Refund/withdrawal stance:** owner-approved policy after professional/legal review.
8. **Production data:** preserve/migrate/reset after backup; identify whether any real users must be protected.
9. **Acquisition authority:** approve personal outreach and identify ten qualified upcoming-trip organizers; no external messages are sent without this authority.
10. **Design boundary:** approve focused offer/onboarding/core-flow refinement but no broad redesign or rebrand before first payment.

## Missing evidence

- Owner's actual business/tax/legal setup.
- Provider account eligibility and credentials.
- Existing production user/data sensitivity.
- Any prior user interviews, trips, usage feedback or willingness-to-pay evidence outside the repository.
- A real list of qualified upcoming-trip organizers.
- Real-device and production-like acceptance.

No Worker package is approved until T004 records the decisions above.
