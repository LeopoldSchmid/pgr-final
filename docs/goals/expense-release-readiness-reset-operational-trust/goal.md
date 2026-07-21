# Expense Release Readiness, Reset, and Operational Trust

## Objective

Make the Expense System V1 ready for the product owner/operator to ship, based on `documentation/expense_goal_3_release_readiness_reset_operational_trust_2026-06-10.md`.

This goal covers release readiness after the Goal 1 backend/API and Goal 2 frontend/offline/PWA work: old test data reset/export handling, controlled rollout and route cleanup, Kamal/deploy compatibility documentation, production-like offline/PWA validation, sync-failure observability, user/developer operations documentation, and final release acceptance. Actual production deployment remains out of scope and owned by the product owner/operator.

## Original Request

The user asked to prepare GoalBuddy for:

`documentation/expense_goal_3_release_readiness_reset_operational_trust_2026-06-10.md`

## Intake Summary

- Input shape: `existing_plan`
- Audience: PlanGoReminisce product owner/operator, future maintainers, and the implementation team preparing the release.
- Authority: `requested`
- Proof type: `test`
- Completion proof: The release-readiness board is complete only when automated tests, production-like local/staging acceptance evidence or owner-facing manual acceptance instructions, reset/export decision documentation, old-route cleanup, Kamal/build notes, sync-failure observability, PWA/service worker deploy notes, and final release acceptance are all recorded.
- Goal oracle: A product owner/operator can safely decide to ship Expense System V1 because the app has verified backend/frontend behavior, production-like offline/PWA proof, documented reset/export and deploy implications, observable sync failures, clear operational instructions, and no known path where a locally saved expense mutation silently disappears.
- Likely misfire: Treating Goal 3 as a documentation-only pass while skipping old-route cleanup, production-like PWA/offline proof, sync failure observability, reset/export decision logging, or final acceptance mapped back to Goals 1 and 2.
- Blind spots considered: production deployment is explicitly excluded; old test data is not real user data; manual acceptance may need owner execution if local/staging constraints block direct walkthrough; Docker/Kamal asset compilation must account for the new TypeScript bundle; service worker cache versioning can create stale-asset confusion; release acceptance must not assume Goals 1 and 2 are complete without checking their receipts and current verification.
- Existing plan facts:
  - Primary plan: `documentation/expense_goal_3_release_readiness_reset_operational_trust_2026-06-10.md`.
  - Goal 3 depends on Goal 1 backend/domain/API and Goal 2 frontend/offline/PWA completion.
  - Actual production deployment is not part of this goal.
  - Kamal remains the deployment target.
  - No separate frontend host, API service, native app build, external sync service, or external AI service is required for V1.
  - Existing old expense production data is test data; careful production migration is not required.
  - Existing project test approach from `documentation/testing.md` and `documentation/delivery_standards.md` must continue.

## Goal Oracle

The oracle for this goal is:

`Expense System V1 is release-ready when reset/export handling, route/navigation compatibility, Kamal/build/PWA operational notes, sync-failure observability, production-like offline/manual acceptance evidence or owner instructions, and final acceptance across Goals 1 and 2 are complete and verified without performing production deployment.`

The PM must keep comparing task receipts to this oracle. A passing implementation slice or a documentation update is not enough by itself. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`existing_plan`

## Current Tranche

Validate Goal 3 against the completed Goal 1 and Goal 2 board receipts and current repository state, then complete the largest safe release-readiness work packages until the full release-readiness outcome is true. Do not begin with production deployment, credentials, destructive data reset, or assumptions about the operator's production environment.

## Non-Negotiable Constraints

- Do not perform actual production deployment.
- Do not perform destructive production data reset.
- Preserve Rails/Kamal same-origin deployment.
- Keep the new expense system aligned with the fixed low-dependency frontend choices from Goal 2.
- Continue the existing test approach: Rails tests, Playwright system/browser tests where appropriate, no Selenium reintroduction.
- Follow `documentation/testing.md` and `documentation/delivery_standards.md`.
- Do not add new infrastructure unless the first Judge task proves it is required for release readiness and records the reason.
- Document any owner/operator action clearly instead of silently encoding it in implementation.

## Stop Rule

Stop only when a final audit proves the full Goal 3 owner outcome is complete.

Do not stop after planning, prerequisite validation, a deploy note, or one successful verification command if release-readiness work remains. If production credentials, staging access, or destructive reset permission are needed, block that specific task and continue every safe local preparation or documentation task that can still advance the release-readiness outcome.

## Canonical Board

Machine truth lives at:

`docs/goals/expense-release-readiness-reset-operational-trust/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/expense-release-readiness-reset-operational-trust/goal.md.
```

## PM Loop

On every `/goal` continuation:

1. Read this charter.
2. Read `state.yaml`.
3. Re-check the intake: original request, input shape, authority, proof, blind spots, existing plan facts, and likely misfire.
4. Work only on the active board task.
5. Assign Scout, Judge, Worker, or PM according to the task.
6. Write a compact task receipt.
7. Update the board.
8. If safe local work remains, choose the next largest reversible Worker package and continue unless blocked.
9. Review at phase, risk, rejected-verification, ambiguity, or final-completion boundaries.
10. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the Goal 3 oracle and records `full_outcome_complete: true`.
