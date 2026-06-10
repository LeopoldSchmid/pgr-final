# Expense System V1 Overview

Stand: 2026-06-10

## Purpose

Build the final V1 expense system for PlanGoReminisce: a modern, mobile-first, trustworthy travel ledger that supports fast expense entry, flexible splitting, late joiners, accurate settlement, and reliable offline expense work.

This overview coordinates three separate implementation goals. Each goal document is written so it can be handed to a different colleague without needing the full original planning thread.

## Goal Documents

1. [expense_goal_1_domain_ledger_sync_api_2026-06-10.md](./expense_goal_1_domain_ledger_sync_api_2026-06-10.md)
   - Backend domain model, trip-person accounting, split math, settlement, audit events, and sync API.
2. [expense_goal_2_frontend_offline_pwa_2026-06-10.md](./expense_goal_2_frontend_offline_pwa_2026-06-10.md)
   - Modern expense frontend island, quick capture, split editor, IndexedDB offline queue, PWA behavior, and sync states.
3. [expense_goal_3_release_readiness_reset_operational_trust_2026-06-10.md](./expense_goal_3_release_readiness_reset_operational_trust_2026-06-10.md)
   - Old data reset, deploy-readiness handoff, smoke tests, production-like offline verification plan, and final release acceptance criteria.

## Shared Product Context

The current expense implementation should be replaced, not polished. It is useful as reference material, but the V1 target is a new expense system designed around real travel use.

There is only one test trip on production and no real user base for the old expense system. V1 does not require a careful production data migration; old expense data may be discarded or reset during rollout after a deliberate backup/export.

## Product Outcome

Users travelling together can record and correct expenses with minimal friction, even when connectivity is unreliable. They can include people before those people have registered, split costs in realistic ways, understand who owes whom, and trust that offline changes will not vanish or duplicate when the app syncs.

The expense area should feel like a focused app inside PlanGoReminisce, not like a collection of clunky CRUD forms.

## Product Principles

1. Expense capture must be fast for the common case.
   - Target: create a normal expense in under 10 seconds.
   - Default flow: amount and short description are enough.

2. Trust is a first-class feature.
   - No silent data loss.
   - No duplicate expenses after retry.
   - Sync status is visible.
   - Split and settlement math is tested and explainable.

3. Trips contain people, not just registered users.
   - Expenses are assigned to trip people.
   - A trip person can be linked to a registered user later.
   - Pending invitees and placeholders can participate in expenses from day one.

4. The app should handle travel reality.
   - Bad signal.
   - People joining late.
   - Unequal shares.
   - Repeated merchants and descriptions.
   - A payer who is not the current user.

5. Server-side ledger correctness wins over frontend convenience.
   - The frontend may preview calculations.
   - Rails remains the canonical source of truth.
   - The server validates and recomputes money-critical results.

## Fixed V1 Decisions

These decisions are fixed for V1 and should not be reopened during implementation unless a documented blocker appears.

1. Frontend technology.
   - Use plain TypeScript modules mounted by Stimulus.
   - Use `jsbundling-rails` with `esbuild`.
   - Use existing Tailwind styling.
   - Do not use React, Svelte, Vue, Redux, a component library, a client-side router, Dexie, or Workbox for V1.
   - Use `idb` only if direct IndexedDB usage becomes noisier or riskier than the dependency.

2. Offline scope.
   - V1 includes offline create, edit, and void for cached expenses.
   - Use revision-based conflict detection.
   - Manual conflict review is enough; automatic conflict merging is not required.

3. Split modes.
   - V1 includes equal, exact amount, share/weight, and percentage splits.

4. Settlement payments.
   - Settlement suggestions are required.
   - Recording actual settlement payments is valuable but not required for V1.

5. Old expense data.
   - No full migration is required.
   - Back up/export the existing test trip if useful, then replace the old expense data/model.

6. Soft delete versus hard delete.
   - Use voiding/soft delete for expenses in V1.
   - Preserve audit history.

## Suggested Sequencing

1. Goal 1: implement the backend domain, ledger math, sync API, revisions, conflict detection, and tests.
2. Goal 2: implement the frontend island, quick capture, split editor, offline queue, PWA behavior, and sync states against the Goal 1 API.
3. Goal 3: prepare old data reset/export, deployment handoff notes, manual offline walkthrough, and final release acceptance criteria.

Actual production deployment remains outside these implementation goals and is owned by the product owner/operator.

Some setup work in Goal 2, such as `jsbundling-rails` and TypeScript, may happen while Goal 1 is being built, but Goal 2 acceptance depends on stable Goal 1 API contracts.

## Explicit Non-Goals For V1

These should not block the V1 expense release unless scope is explicitly expanded.

- Receipt OCR.
- AI-based natural language parsing.
- Bank import.
- Multi-currency exchange-rate automation.
- Push notifications.
- Native iOS/Android wrappers.
- Full double-entry accounting UI.
- Public sharing outside trip members.

## Final Definition Of Done

The expense system is V1 complete when a real travel group can use PlanGoReminisce as its primary shared expense ledger, including pending people, unequal shares, fast mobile capture, offline create/edit/void, trustworthy sync, accurate balances, and settlement suggestions, with automated and manual proof that money and sync behavior are correct.
