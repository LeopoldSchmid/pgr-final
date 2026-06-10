# Expense Goal 1: Domain, Ledger, and Sync API

## Objective

Implement the backend foundation for Expense System V1: trip-person accounting, canonical split and settlement math, late-joiner support, audit events, and an idempotent sync API for offline create/edit/void.

## Original Request

`$goalbuddy documentation/expense_goal_1_domain_ledger_sync_api_2026-06-10.md`

## Intake Summary

- Input shape: `existing_plan`
- Audience: PlanGoReminisce implementation team and future frontend/offline work
- Authority: `requested`
- Proof type: `test`
- Completion proof: Rails model/service/request tests pass for the new backend domain, sync semantics, late-joiner behavior, settlement math, and authorization boundaries; a final audit maps implementation evidence back to `documentation/expense_goal_1_domain_ledger_sync_api_2026-06-10.md`.
- Goal oracle: the Goal 1 handoff document plus passing targeted Rails tests for all backend acceptance criteria.
- Likely misfire: implementing superficial CRUD tables or preserving the old user-bound expense model while missing trip-person accounting, idempotent sync, stale revision conflicts, audit events, or settlement correctness.
- Blind spots considered: existing app routes/auth/current trip conventions, dirty worktree state, old expense implementation coupling, migration/reset implications, API compatibility required by Goal 2, and verification breadth for money behavior.
- Existing plan facts: use `TripPerson`, `Expense`, `ExpenseSplit`, `SplitGroup`, `ExpenseEvent`, and `ClientMutation`; expenses reference trip people; support draft/active/needs_split/voided expenses; include equal/exact/share/percentage splits; exclude draft/needs_split from settlement; support pending people, linking, merging, and retroactive include preview/apply; expose same-origin Rails JSON APIs for Goal 2; use idempotency keys and base revisions for offline create/edit/void; detect stale revision conflicts; continue Rails test approach; no careful production migration is required.

## Goal Oracle

The oracle for this goal is:

`Goal 1 is complete when the backend can represent and validate the new expense system, compute correct balances and settlements, handle late joiners, accept idempotent offline mutations, detect edit/void conflicts, and prove those behaviors through Rails tests.`

The PM must keep comparing task receipts to this oracle. Planning, discovery, a passing tiny slice, or a clean-looking board is not enough. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`existing_plan`

## Current Tranche

Complete the Goal 1 backend implementation end to end. Start by validating the handoff plan against the current Rails app, then execute successive safe backend slices until all Goal 1 acceptance criteria are met and verified.

## Non-Negotiable Constraints

- Preserve the product direction in `documentation/expense_goal_1_domain_ledger_sync_api_2026-06-10.md`.
- Do not implement the frontend island in this goal.
- Do not perform production deployment in this goal.
- Do not rely on a careful production migration; old expense data may be backed up/exported and reset because it is only test data.
- Rails remains the canonical source of truth for money, authorization, validation, settlement, and sync acceptance.
- Frontend previews are not canonical; server-side calculations and validations must decide money outcomes.
- Continue the existing project test approach from `documentation/testing.md` and `documentation/delivery_standards.md`.
- Do not revert unrelated existing work in the dirty worktree.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated.

Do not stop after a single verified Worker package when the broader owner outcome still has safe local follow-up work. Advance the board to the next highest-leverage safe Worker package and continue unless a phase, risk, rejected-verification, ambiguity, or final-completion review is due.

Do not create one Worker/Judge pair per repeated file, table, route, or helper. Put repeated same-shape work into one Worker package and review the package as a whole.

Do not stop because a slice needs owner input, credentials, production access, destructive operations, or policy decisions. Mark that exact slice blocked with a receipt, create the smallest safe follow-up or workaround task, and continue all local, non-destructive work that can still move the goal toward the full outcome.

## Slice Sizing

Safe means bounded, explicit, verified, and reversible. It does not mean tiny.

A good task is the largest safe useful slice.

Small is not the goal. Useful is the goal.

A Worker should finish the whole assigned slice. A Judge should judge the whole assigned slice. A PM should reorient the board when tasks are safe but not moving the outcome.

Tiny tasks are allowed when the failure is isolated, the risk is high, the scope is unknown, or the tiny task unlocks a larger slice. Tiny tasks are bad when they keep happening, do not change behavior, only add wrappers/contracts/proof files, or avoid the real milestone.

## Canonical Board

Machine truth lives at:

`docs/goals/expense-domain-ledger-sync-api/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/expense-domain-ledger-sync-api/goal.md.
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
10. Review at phase, risk, rejected-verification, ambiguity, or final-completion boundaries; do not review every small Worker by habit.
11. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the original user outcome and records `full_outcome_complete: true`.
