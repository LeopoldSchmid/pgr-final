# Expense Goal 2: Modern Frontend and Offline PWA Experience

Stand: 2026-06-10

## Purpose

Build the user-facing expense experience as a focused frontend island inside the Rails app: fast mobile capture, flexible split editing, people/groups management, balances, settlement suggestions, offline create/edit/void, and trustworthy sync states.

This goal depends on Goal 1 for the canonical backend model, API contracts, server-side money calculations, idempotency, revisions, and conflict behavior.

## Shared Product Context

PlanGoReminisce needs a modern, mobile-first, trustworthy travel ledger. Users must be able to include people before those people have registered, split costs in realistic ways, understand who owes whom, and trust that offline changes will not vanish or duplicate when the app syncs.

The expense area should feel like a focused app inside PlanGoReminisce, not like a collection of clunky CRUD forms.

## Fixed Frontend Technology

Use this stack for V1:

- Rails remains the backend and source of truth.
- Use a dedicated frontend island for the expense area, but do not introduce React, Svelte, Vue, Redux, a component library, or a client-side router for V1.
- Use plain TypeScript modules mounted from one or more Stimulus controllers.
- Use the existing Tailwind setup for styling. Do not add a UI component framework.
- Use `jsbundling-rails` with `esbuild` for the TypeScript bundle. Do not use Vite unless `jsbundling-rails` and `esbuild` prove insufficient for a documented reason.
- Use IndexedDB for local durable storage.
- Use one small IndexedDB helper dependency, `idb`, unless direct IndexedDB usage stays simple and well-tested. Do not use Dexie for V1 because the feature does not need its larger abstraction surface.
- Use a small internal state/store module with pure functions for expense draft state, split editor state, parser output, and sync queue transitions. Do not add a global state management library.
- Use a custom service worker. Do not add Workbox for V1.
- Keep the app served from the same Rails/Kamal deployment and same origin.

The goal is a modern app-like interaction model with the smallest reasonable dependency footprint. This is not a full SPA rewrite.

## Suggested Frontend Structure

The exact filenames can change, but keep responsibilities separated like this:

```text
app/javascript/expenses/
  app.ts
  api.ts
  db.ts
  parser.ts
  render.ts
  splits.ts
  store.ts
  sync.ts
  types.ts
```

One or more Stimulus controllers mount the expense app and handle lifecycle:

```text
app/javascript/controllers/expense_app_controller.ts
```

Rules:

- Keep parser, split math previews, sync queue transitions, and state reducers as pure functions where practical.
- Keep DOM rendering isolated from API and IndexedDB code.
- Do not duplicate canonical money truth in the frontend. Frontend previews must be validated by the Rails API.

## Scope

- Replace the old expense index/new/edit flow with a modern expense app surface.
- Build a mobile-first dashboard.
- Build ultra-fast expense capture.
- Build a flexible split editor.
- Build roster management for pending people.
- Build balances, per-person views, and settlement suggestions.
- Build duplicate previous expense and recent suggestions.
- Build offline expense creation, editing, and voiding with visible sync states.
- Build installable PWA behavior for the expense workflow.

## API Dependency From Goal 1

The frontend expects same-origin Rails JSON endpoints that can:

- load the active trip expense snapshot: trip people, split groups, expenses, balances, settlement suggestions, and recent suggestion data
- create/update/void trip people
- invite/link/merge trip people
- create/update/void split groups
- create/update/void expenses
- submit queued client mutations for offline create/edit/void
- fetch sync result state, including accepted, duplicate, rejected, and conflict
- fetch conflict data containing server values and queued local values
- run the retroactive include assistant preview and apply action

If these contracts are not stable yet, build the frontend against a thin local adapter so API shape changes stay isolated in `api.ts`.

## Core Screens

### Expense Dashboard

Should show:

- active trip context
- total spend
- current user's balance
- number of expenses
- sync status summary
- settlement suggestions
- recent expenses
- primary add expense action
- access to people, groups, balances, and history

The dashboard should be dense enough for repeated trip use, not a marketing-style card page.

### Quick Add

The common flow should be one focused input plus a compact confirmation row.

Examples:

- `43.20 pizza`
- `pizza 43,20`
- `€12 coffee`
- `120 hotel`

The app infers:

- amount
- currency where possible
- description
- category
- payer default
- split group default

The confirmation row should make the inferred values visible and tappable:

- amount
- description
- category
- paid by
- split with
- date

The user should be able to save immediately or expand advanced controls.

### Split Editor

Supported modes:

- Everyone equal
- Selected people equal
- Exact amounts
- Shares/weights
- Percentages

Requirements:

- Show per-person owed amount before save.
- Show validation errors inline.
- Allow switching modes without losing intentional selections where reasonable.
- Provide split group shortcuts.
- Provide "split remaining equally" for exact amount mode.

### People and Groups

Should support:

- adding placeholder people
- inviting by email
- editing display names
- linking/claiming invited people
- merging duplicate trip people
- creating and editing split groups

### Balances and Settlement

Should support:

- balance per trip person
- "I owe / I am owed" view for current user
- settlement suggestions
- clear explanation of how a settlement affects balances

Recording actual settlement payments is not required for V1.

### Activity/History

Should show enough history to build trust:

- expense created
- expense edited
- split changed
- synced from offline
- failed sync requiring attention
- person linked or merged
- bulk correction applied

## Smart Capture Parser

V1 uses deterministic local parsing and learned suggestions, not network-dependent AI.

Parser behavior:

- Detect locale-aware amounts.
- Detect currency symbols and codes.
- Remove amount/currency tokens from the description.
- Normalize whitespace and punctuation.
- Infer category from deterministic ranking.
- Default payer to current trip person.
- Default split group to last used group or everyone.

Category inference ranking:

1. Exact previous description or merchant match.
2. User's previous correction for similar text.
3. Trip-level merchant or phrase history.
4. Keyword dictionary.
5. Fallback to other.

Examples:

- pizza, restaurant, cafe -> food
- train, taxi, uber, gas -> transport
- hotel, hostel, airbnb -> accommodation
- museum, tour, tickets -> activities
- supermarket, groceries, pharmacy -> shopping

Acceptance:

- The parser works offline.
- Low-confidence guesses are visibly editable.
- Corrections are remembered for future suggestions.
- Parser tests cover common German and English decimal formats, currency symbols, and ambiguous input.

## Offline Expense Work and Sync

V1 offline support must cover creation, editing, and voiding cached expenses with conflict detection.

Offline support does not require the user to install the PWA. Service workers, IndexedDB, cached app assets, and queued sync work in a normal browser tab after the user has previously loaded the expense app over HTTPS. Installing the PWA mainly improves launch convenience and gives the app a standalone icon/window. It is not a functional prerequisite.

Required behavior:

- The expense app shell loads when offline after prior use.
- Recent trip roster, split groups, and recent expenses are available offline after prior sync.
- A user can create a new expense offline.
- A user can edit an offline-created pending expense before it syncs.
- A user can edit a previously synced cached expense while offline.
- A user can void a previously synced cached expense while offline.
- Offline expenses appear immediately in the expense list with a pending status.
- Pending mutations include all needed split data, a client mutation UUID, and the base server revision when editing or voiding existing records.
- When connectivity returns, queued mutations sync automatically on app open, online events, and explicit retry. Do not depend only on browser Background Sync because support is inconsistent across browsers.
- Successful sync replaces or links the local pending record with the server record.
- Failed sync remains visible with an error state and retry path.
- Duplicate retries do not create duplicate server expenses or duplicate edit/void effects.
- If the server revision changed while the user was offline, the mutation is not silently overwritten. The app shows a conflict state with server values and local queued values, then lets the user choose how to proceed.
- Draft or `needs_split` expenses can sync without complete split data, but they must be excluded from settlement until completed.

Explicit V1 limitations:

- V1 does not need automatic conflict merging. Manual conflict review is enough.
- V1 uses voiding/soft delete for expense removal. Hard deletion is not required.
- V1 does not need offline receipt upload.

## Frontend Acceptance Criteria

- A user can create a normal expense in under 10 seconds on mobile using defaults.
- The UI supports equal, exact amount, share/weight, and percentage splits.
- Placeholder and invited trip people can be selected in expense splits.
- A new pending person can be added from the expense flow without leaving the task.
- The user can duplicate a previous expense and adjust it.
- Recent descriptions and category suggestions reduce repeated typing.
- The dashboard clearly shows total spend, current user's balance, and settlement suggestions.
- Every expense shows sync state when relevant.
- Offline-created and offline-edited expenses are not lost after refresh, browser restart, or reconnect.
- Retrying sync cannot create duplicate creates, duplicate edits, or duplicate voids.
- Offline edit conflicts are detected and shown instead of silently overwriting server changes.
- Failed sync entries remain visible and actionable.
- The app is installable as a PWA on supported browsers, but offline work also functions in a normal browser tab after prior online use.
- The expense app remains usable on narrow mobile screens without text overlap or hidden critical actions.
- Frontend tests cover parser behavior, split editor state, offline queue behavior, conflict handling, and sync state transitions.
- Playwright covers online quick add, unequal split, pending person inclusion, offline create, offline edit, offline void, reconnect sync, conflict state, and duplicate retry protection.

## Testing Requirements

Continue the existing project test approach:

- Rails system tests continue to use Playwright via `capybara-playwright-driver`.
- Standalone Playwright specs under `tests/` may be added for browser/PWA/offline flows that are easier to express directly in Playwright.
- No Selenium reintroduction.
- Follow `documentation/testing.md` and `documentation/delivery_standards.md`.

Required automated coverage:

- parser tests for quick-capture strings
- split editor state tests
- IndexedDB queue tests
- sync state transition tests
- conflict-state tests
- Rails system or Playwright coverage for the critical mobile and offline flows

## Dependencies On Other Goals

- Goal 1 must define stable API contracts, canonical split behavior, revisions, and conflict semantics.
- Goal 3 will verify this goal in production-like conditions and ensure the PWA/service worker/deploy path works with Kamal.

## Done For Goal 2

Goal 2 is complete when the new expense UI replaces the old clunky flow, supports the full V1 interaction scope, works offline after prior online use, preserves pending mutations across refresh/restart, syncs without duplication, shows conflicts clearly, and passes the required browser-facing tests.
