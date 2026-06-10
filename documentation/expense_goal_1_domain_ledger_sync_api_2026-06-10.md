# Expense Goal 1: Domain, Ledger, and Sync API

Stand: 2026-06-10

## Purpose

Create the backend foundation for the new Expense System V1: trip-person accounting, canonical split and settlement math, late-joiner support, audit events, and an idempotent sync API for offline create/edit/void.

This goal should be accepted before the frontend goal is considered complete. The frontend may be developed in parallel, but this goal defines the canonical data model and API contracts it must use.

## Shared Product Context

PlanGoReminisce needs a modern, mobile-first, trustworthy travel ledger. Users must be able to include people before those people have registered, split costs in realistic ways, understand who owes whom, and trust that offline changes will not vanish or duplicate when the app syncs.

The current expense implementation should be replaced, not polished. There is only one test trip on production and no real user base for the old expense system, so V1 does not require a careful production data migration.

## Product Principles Relevant To This Goal

- Expenses are assigned to trip people, not directly to registered users.
- Rails is the canonical source of truth for money, authorization, validation, settlement, and sync acceptance.
- The frontend may preview calculations, but the server must validate and recompute money-critical results.
- Trust requires idempotency, audit history, and conflict detection.

## Scope

- Introduce trip-person based accounting.
- Replace user-only expense participants with trip people.
- Support registered, invited, and placeholder people.
- Support equal and unequal splits.
- Support reusable split groups.
- Add canonical balance and settlement calculations.
- Add idempotent client mutation handling for offline create, edit, and void.
- Add revision-based conflict detection for offline edits and voids.
- Add an audit trail for critical expense changes.
- Retire the old expense implementation and old test expense data safely.

## Target Domain Model

Use these concepts and names unless a concrete Rails naming conflict forces a small adjustment. Architectural decisions in this document are product decisions, not optional team preferences.

### TripPerson

Represents a human participant in a trip ledger.

Fields should support:

- trip
- display name
- optional linked user
- optional email
- status: active, invited, placeholder, archived
- metadata needed for invite/link/merge flows

Rules:

- Expenses and splits reference trip people, not users.
- One trip person may later be linked to a user.
- Placeholder and invited people can owe, pay, and receive settlement just like linked users.
- Archiving a trip person must not erase ledger history.

### Expense

Represents a canonical expense.

Fields should support:

- trip
- payer trip person
- amount
- currency
- description
- category
- expense date
- optional receipt reference
- client UUID for idempotent offline creation
- server UUID/id used by later edit and void mutations
- revision/lock version for queued offline edits
- status: draft, active, needs_split, voided

Rules:

- Amounts are decimal money values with predictable rounding.
- Euro is default currency.
- An expense is invalid without a payer.
- A draft or `needs_split` expense may exist without complete split participants. This supports quick capture when the split is not known yet.
- An active settled expense must have split participants, and the sum of split amounts must equal the expense amount after canonical server rounding.
- Draft or `needs_split` expenses must be excluded from final settlement suggestions until completed.

### ExpenseSplit

Represents what one trip person owes for one expense.

Fields should support:

- expense
- trip person
- amount owed
- split method metadata

Supported V1 split methods:

- equal split
- exact amounts
- shares/weights, for example adults 1 and child 0.5
- percentages

Exact amounts and shares/weights are the primary unequal split modes. Percentages are included in V1 because they are straightforward once exact amounts and shares share the same canonical split engine.

### SplitGroup

Represents a reusable set of trip people.

Examples:

- Everyone
- Drivers
- Family A
- Dinner group
- Adults

Rules:

- "Everyone" exists as a built-in dynamic/default group.
- User-created groups are editable.
- Historical expenses keep their actual split people even if a group changes later.

### ExpenseEvent

Append-only audit record for expense-relevant actions.

Events should cover:

- expense created
- expense edited
- expense voided/deleted
- split changed
- payer changed
- offline mutation synced
- sync failed or retried, where useful
- trip person linked to user
- trip person merged
- bulk correction applied

The event log does not need to be exposed as a full accounting ledger in V1, but the data must exist for debugging and user-facing history.

### ClientMutation

Idempotency envelope for offline and retryable writes.

Fields should support:

- client UUID / idempotency key
- trip
- actor user
- mutation type
- payload hash or canonical payload reference
- base server revision for edit and void mutations
- status: accepted, duplicate, rejected, conflict
- resulting server record reference
- error details for rejected or conflicted mutations

Rules:

- Retrying the same offline-created expense must not create duplicates.
- Retrying the same offline edit or void must not apply the mutation twice.
- The same client UUID with a conflicting payload must be rejected or flagged.
- If the base server revision no longer matches, the mutation must not silently overwrite server state.

## API Contract Required By Goal 2

Expose same-origin Rails JSON endpoints for the frontend expense island. Exact route names can follow Rails conventions, but the frontend must be able to:

- load the active trip expense snapshot: trip people, split groups, expenses, balances, settlement suggestions, and recent suggestion data
- create/update/void trip people
- invite/link/merge trip people
- create/update/void split groups
- create/update/void expenses
- submit queued client mutations for offline create/edit/void
- fetch sync result state, including accepted, duplicate, rejected, and conflict
- fetch conflict data containing server values and queued local values
- run the retroactive include assistant preview and apply action

All write APIs must enforce authorization and server-side validation. The sync API must use idempotency keys and base revisions.

## Late Joiner Requirements

The system must solve the "person joins after expenses were entered" problem.

Required flows:

1. Add pending person
   - A trip organizer or member can add a trip person by name before the person has an account.
   - Optional email invite can be attached.
   - That trip person can be selected in expenses immediately.

2. Link on join
   - When a user accepts an invite, the app can link that user to the existing trip person.
   - Existing expenses and balances remain continuous.
   - The user should understand that prior expenses were already assigned to them.

3. Merge duplicate people
   - If "Max" was added as a placeholder and "max@example.com" joins separately, the app provides a controlled merge.
   - Merge must preview the result and preserve audit history.

4. Retroactive include assistant
   - If a person was genuinely forgotten, users can add them to selected previous expenses.
   - The flow must support filters such as date range, category, payer, and selected expenses.
   - The flow must show a before/after balance preview before applying changes.

## Backend Acceptance Criteria

- Expenses can be created for registered users, invited people, and placeholder people.
- A pending trip person can later be linked to a registered user without changing historical expense ownership.
- Equal splits are rounded deterministically and sum exactly to the expense amount.
- Exact amount splits reject invalid totals.
- Share/weight splits produce deterministic owed amounts and handle rounding.
- Percentage splits produce deterministic owed amounts and handle rounding.
- Balance calculations work for mixed equal, exact, share-based, and percentage expenses.
- Draft and `needs_split` expenses are excluded from settlement suggestions until completed.
- Settlement suggestions minimize transfers while preserving correct net balances.
- Duplicate client mutations are idempotent.
- Conflicting client mutations with the same idempotency key are rejected or flagged.
- Offline edit/void mutations with stale base revisions produce a conflict instead of silently overwriting server changes.
- Expense events are written for create, edit, delete/void, split change, trip-person link, merge, bulk correction, and accepted sync mutations.
- Old expense data is backed up/exported if desired, then discarded or reset as part of replacing the old expense implementation.
- Authorization prevents non-members from reading or mutating trip expenses.
- Rails model/service/request tests cover money math, late joiners, trip-person linking, duplicate protection, stale revision conflicts, settlement, and authorization boundaries.

## Testing Requirements

Continue the existing project test approach:

- Rails tests cover backend domain logic, services, API validation, authorization, and model behavior.
- No Selenium reintroduction.
- Follow `documentation/testing.md` and `documentation/delivery_standards.md`.

Required automated coverage:

- model tests for `TripPerson`, `Expense`, `ExpenseSplit`, `SplitGroup`, `ExpenseEvent`, and `ClientMutation`
- service tests for split math
- service tests for settlement math
- service tests for retroactive include preview/apply
- service or request tests for idempotent sync
- request/controller tests for authorization and API validation
- tests proving draft/needs_split expenses are excluded from settlement
- tests proving stale revision edits/voids produce conflicts

## Dependencies On Other Goals

- Goal 2 depends on this goal for API contracts, canonical calculation behavior, revisions, and sync semantics.
- Goal 3 depends on this goal for old data reset behavior, deploy readiness, and final release acceptance.

## Done For Goal 1

Goal 1 is complete when the backend can represent and validate the new expense system, compute correct balances and settlements, handle late joiners, accept idempotent offline mutations, detect edit/void conflicts, and prove those behaviors through Rails tests.
