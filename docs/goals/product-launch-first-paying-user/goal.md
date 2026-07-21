# Product Launch and First Paying User

## Objective

Assess the entire existing product, make an explicit owner decision about the launch scope, refine the necessary and highest-value parts, publish a trustworthy paid product, and obtain the first real paying user.

## Original Request

The user wants to return to this long-stalled project, understand its complete current state, finish and refine the parts that genuinely belong in the application, monetize it, publish it, and continue until a real outside user has paid and experienced the core value.

## Intake Summary

- Input shape: `recovery`
- Audience: The product owner first, followed by prospective paying users.
- Authority: `requested` for full read-only assessment and local implementation after the owner decision gate; production publication, spending, credentials, legal choices, and destructive operations still require their normal explicit approvals.
- Proof type: `metric`
- Completion proof: At least one real outside user discovers the public product, pays successfully, completes onboarding, and experiences the central product value.
- Goal oracle: A receipt-backed production funnel walkthrough plus evidence of the first genuine external successful payment and completed core journey.
- Likely misfire: Declaring success after an audit, a polished local application, a deployment, or a working payment sandbox without reaching a real paying user.
- Blind spots considered: Scope creep disguised as refinement; incomplete core product areas; launch without a coherent offer; payment, onboarding, trust, privacy, operations, or acquisition gaps; stale plans and a large pre-existing dirty worktree.
- Existing plan facts: Existing GoalBuddy boards and release-readiness documentation are present and must be assessed as evidence, not assumed current or discarded.

## Goal Oracle

The oracle for this goal is:

`A real outside user can discover the public offer, pay successfully, complete onboarding, and experience the core value; final proof includes the production funnel evidence and the genuine successful payment.`

The PM must keep comparing task receipts to this oracle. Planning, discovery, a passing tiny slice, or a clean-looking board is not enough. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`recovery`

## Current Tranche

Run a comprehensive read-only product, technical, operational, and commercial assessment. Present the findings and explicit scope choices to the owner. After the owner decision gate, execute successive coherent, verified launch packages until the product is public and the first real paying user has completed the core journey.

## Non-Negotiable Constraints

- Do not treat planning, deployment, or sandbox payment as the final outcome.
- Do not make major product or commercial choices before the owner decision gate.
- Evaluate the whole project; do not preserve the current architecture, feature set, positioning, price, or launch approach merely because it already exists.
- Preserve all pre-existing user changes in the dirty worktree and avoid overlapping writes until their intent and status are understood.
- Refinement is welcome when evidence connects it to core value, trust, usability, or conversion; aesthetic or comfort work without that connection stays deferred.
- Never expose secrets or real customer/payment data in receipts.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or Judge selection if safe approved work can continue. If an exact owner decision, credential, production action, legal choice, or expenditure is the only remaining blocker, record the precise request and continue every safe local task first.

## Slice Sizing

Safe means bounded, explicit, verified, and reversible. It does not mean tiny. Prefer complete user-facing or operational vertical slices over isolated helpers and cosmetic churn.

## Board Health

Machine truth lives at `docs/goals/product-launch-first-paying-user/state.yaml`.

## Run Command

```text
/goal Follow docs/goals/product-launch-first-paying-user/goal.md.
```

## PM Loop

On every `/goal` continuation, follow the GoalBuddy execution contract, work only on the active task, record a compact receipt, update the board, and keep advancing until the oracle is proven or an exact terminal owner decision is required.
