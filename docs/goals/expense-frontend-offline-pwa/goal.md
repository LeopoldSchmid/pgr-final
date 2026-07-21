# Expense Frontend Offline PWA

## Objective

Build the modern expense frontend and offline PWA experience described in `documentation/expense_goal_2_frontend_offline_pwa_2026-06-10.md`, using the completed Goal 1 backend/API foundation as the source of truth.

This goal covers the V1 user-facing expense surface: mobile-first quick capture, flexible split editing, people and group management, balances and settlement suggestions, activity/history, installable PWA behavior, and offline create/edit/void with trustworthy sync and conflict states.

## Original Request

The user asked to prepare GoalBuddy for `documentation/expense_goal_2_frontend_offline_pwa_2026-06-10.md`, with no UI board needed.

## Intake Summary

- Input shape: `existing_plan`
- Audience: PlanGoReminisce travelers using expenses during real trips, and the development team implementing Goal 2 after Goal 1.
- Authority: `requested`
- Proof type: `test`
- Completion proof: Browser-facing automated tests and manual walkthrough evidence show the new expense app replaces the old clunky flow, works online and offline after prior use, preserves and syncs queued mutations without duplication, and exposes conflicts clearly.
- Goal oracle: The expense app can be used on mobile to add, edit, split, void, sync, retry, and resolve conflict states across online/offline transitions, while required parser, split, queue, PWA, and Playwright coverage passes.
- Likely misfire: Building attractive screens or a partial quick-add prototype while skipping durable offline behavior, conflict visibility, API integration, mobile friction, or the fixed low-dependency technology choices.
- Blind spots considered: service worker behavior in normal browser tabs versus installed PWA, offline editing complexity, backend contract drift after Goal 1, browser storage reliability, duplicate retry protection, narrow mobile layout, and tests for PWA/offline flows.
- Existing plan facts: Preserve the Goal 2 handoff document, Goal 1 dependency, fixed frontend technology, no migration requirement for existing users, and the existing project test approach from `documentation/testing.md` and `documentation/delivery_standards.md`.

## Goal Oracle

The oracle for this goal is:

`The new expense UI replaces the old expense flow and passes browser-facing proof for quick add, unequal splits, pending person inclusion, offline create/edit/void, refresh/restart persistence, reconnect sync, duplicate retry protection, conflict state handling, PWA shell caching, and mobile usability.`

The PM must keep comparing task receipts to this oracle. Planning, discovery, a passing tiny slice, or a clean-looking board is not enough. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`existing_plan`

## Current Tranche

Complete successive safe verified implementation slices until the full Goal 2 outcome is true. Start with a read-only Judge validation of the existing Goal 2 handoff against the current Rails app and completed Goal 1 backend, then move into the largest safe vertical frontend/offline slice with explicit allowed files and verification.

The PM should continue beyond the first frontend slice if safe local work remains. Do not stop at a design shell, parser-only package, service-worker-only package, or "ready for implementation" state.

## Non-Negotiable Constraints

- Use Rails as the backend and source of truth.
- Use a dedicated frontend island inside the existing Rails app.
- Use plain TypeScript modules mounted from one or more Stimulus controllers.
- Use `jsbundling-rails` with `esbuild` for the TypeScript bundle unless that exact stack is proven insufficient and the reason is documented.
- Use the existing Tailwind setup for styling.
- Use IndexedDB for local durable storage.
- Use one small IndexedDB helper dependency, `idb`, only if direct IndexedDB usage becomes noisy or fragile.
- Use a custom service worker.
- Do not add React, Svelte, Vue, Redux, a client-side router, a UI component framework, Dexie, Workbox, or a full SPA rewrite for V1.
- Keep the app served from the same Rails/Kamal deployment and same origin.
- Do not include production deployment in this goal; deployment is reserved for the owner and Goal 3 release readiness.
- Continue the existing project test approach: Rails system tests with Playwright via `capybara-playwright-driver`, standalone Playwright specs under `tests/` where helpful, no Selenium reintroduction.
- Offline support must work in a normal browser tab after prior online use; installing the PWA is not a functional prerequisite.
- V1 offline support includes creation, editing, and voiding cached expenses with conflict detection.
- V1 does not need automatic conflict merging, offline receipt upload, settlement payment recording, or hard deletion.
- Frontend previews must not become canonical money truth; Rails API validation remains authoritative.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated.

Do not stop after a single verified Worker package when the broader owner outcome still has safe local follow-up work. Advance the board to the next highest-leverage safe Worker package and continue unless a phase, risk, rejected-verification, ambiguity, or final-completion review is due.

Do not create one Worker/Judge pair per repeated file, helper, route, or UI state. Put repeated same-shape work into one coherent Worker package and review the package as a whole.

Do not stop because a slice needs owner input, credentials, production access, destructive operations, or policy decisions. Mark that exact slice blocked with a receipt, create the smallest safe follow-up or workaround task, and continue all local, non-destructive work that can still move the goal toward the full outcome.

## Slice Sizing

Safe means bounded, explicit, verified, and reversible. It does not mean tiny.

A good task is the largest safe useful slice.

Small is not the goal. Useful is the goal.

A Worker should finish the whole assigned slice. A Judge should judge the whole assigned slice. A PM should reorient the board when tasks are safe but not moving the outcome.

Tiny tasks are allowed when the failure is isolated, the risk is high, the scope is unknown, or the tiny task unlocks a larger slice. Tiny tasks are bad when they keep happening, do not change behavior, only add wrappers/contracts/proof files, or avoid the real milestone.

## Canonical Board

Machine truth lives at:

`docs/goals/expense-frontend-offline-pwa/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/expense-frontend-offline-pwa/goal.md.
```

## PM Loop

On every `/goal` continuation:

1. Read this charter.
2. Read `state.yaml`.
3. Run the bundled GoalBuddy update checker when available and mention a newer version without blocking.
4. Re-check the intake: original request, input shape, authority, proof, blind spots, existing plan facts, and likely misfire.
5. Work only on the active board task.
6. Assign Scout, Judge, Worker, or PM according to the task.
7. Write a compact task receipt.
8. Update the board.
9. If safe local work remains, choose the next largest reversible Worker package and continue unless blocked.
10. Review at phase, risk, rejected-verification, ambiguity, or final-completion boundaries.
11. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the original user outcome and records `full_outcome_complete: true`.
