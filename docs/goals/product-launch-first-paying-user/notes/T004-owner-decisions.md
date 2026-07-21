# T004 — Owner Decisions

Status: complete

## Approved launch positioning and scope

Decision date: 2026-07-16

The owner approved **Option 1: Group-trip operations hub**.

### Supported paid-beta corridor

- Focused public offer and onboarding.
- Registration, authentication and invitation acceptance.
- Trip creation, details, participants, switching and date coordination.
- Meal planning and recipes needed for real meal plans.
- Shopping Plan, Shopping Lists, assignments, partial purchases and meal-to-shopping synchronization.
- Expense V1: quick capture, supported split modes, pending people, balances/settlements, activity and proven offline/conflict behavior.
- Core Memories: journal/photo capture, feed, favorites and the supported map/gallery behavior needed for the product promise.
- Mobile-first verification, real-phone photo upload, staging, backups, monitoring, support, privacy/legal and payment/entitlement flows.

### Explicitly deferred and hidden before first paid launch

- Packing.
- Itinerary.
- Templates and incomplete trip-copy ambitions.
- Memory albums.
- Broad redesign or brand-system overhaul beyond the focused Wegsam rename.
- Native applications, universal offline support, OCR/AI, bank import, payment transfers and automatic currency conversion.
- PostgreSQL migration or unrelated architecture rewrites.

### Refinement rule

Refinement is launch scope only when it materially improves the paying organizer's or invited group's ability to onboard, coordinate meals/shopping, trust expenses, preserve the core memory, or trust the service. Unsupported-area polish remains deferred.

## Approved focused design boundary

Decision date: 2026-07-21

- Targeted UX, interaction, accessibility, mobile and visual refinement is approved throughout the supported paid-beta corridor.
- Apply the Wegsam working brand consistently to the supported public, purchase, onboarding and core-product journeys.
- Preserve working domain behavior while making the supported journey coherent; do not retain confusing or untrustworthy launch-critical UI merely to avoid a redesign.
- Do not perform a broad architecture rewrite, polish hidden/deferred features, or expand scope merely to make the whole historical application visually uniform.
- Owner acceptance of the complete supported journey is required before outreach or launch.

## Remaining pre-production gates, not owner-scope decisions

- Formal trademark clearance for the preferred product name before broad public promotion.

## Selling-identity constraint

Decision date: 2026-07-16

- The owner's existing business, Zapfe, is a UG shared with two other shareholders and remains outside this project.
- The owner approved creating a personally operated German Einzelunternehmen under the Kleinunternehmerregelung as the selling identity.
- This Einzelunternehmen is intended as an umbrella for multiple software products, not only PlanGoReminisce.
- All revenue from those personally operated software products must be considered together for the Kleinunternehmer thresholds.
- The owner remains employed during a paid sabbatical financed through a Wertguthaben and plans to spend fewer than 20 hours per week on the software business. The launch is therefore planned as a nebenberufliche Selbstständigkeit, subject to confirmation by the owner's health insurer and any required employer notification.
- No real payment may be accepted until the Einzelunternehmen has been registered, its tax setup confirmed, and the required seller/legal details are available.
- Stripe test-mode integration and all other safe local work may proceed once the remaining product decisions are recorded; production activation remains gated.

## Rejected pricing direction

Decision date: 2026-07-16

The owner rejected one-time per-trip pricing. The proposed €19–29 trip pass felt too expensive and did not match the owner's own willingness to pay.

## Approved introductory pricing

The owner approved a combined monthly and annual organizer subscription. Invited participants remain free. This supports short, trip-shaped usage through monthly cancellation while giving recurring organizers a cheaper annual path.

Decision date: 2026-07-16

- Monthly organizer subscription: **€2.99/month**.
- Annual organizer subscription: **€24.99/year**.
- All invited trip participants remain free.
- Pricing is an explicitly adjustable paid-beta experiment, not a permanent commitment.
- The launch must measure checkout completion, activation/core-value completion, cancellation and support/refund reasons before revising the price.
- Subscription renewal, cancellation, total price and annual billing must be presented transparently.

## Approved payment provider

Decision date: 2026-07-16

- **Stripe Managed Payments** is the launch payment model, with Stripe acting as Merchant of Record for supported transactions.
- Use Stripe Checkout and Stripe Billing for monthly and annual organizer subscriptions.
- Use Stripe Customer Portal for subscription management and cancellation.
- Use Managed Payments to delegate supported indirect-tax calculation, collection, filing/remittance, transaction fraud/disputes and transaction-related customer support to Stripe.
- Begin with Stripe-supported card payments and automatically available wallets/localization; avoid custom payment-method scope before first revenue.
- Development and verification begin in Stripe test mode. Live activation remains gated by business/tax registration and complete seller/legal details.
- The accounting treatment of Managed Payments payouts and cross-border Stripe fees must be confirmed before production accounting is finalized.

## Approved initial markets and languages

Decision date: 2026-07-16

- The product may be purchased globally in countries supported by Stripe Managed Payments; unsupported or sanctioned markets are excluded.
- Germany and the United States are the first actively targeted markets.
- German and English are required launch languages for the supported purchase, onboarding, core-product, support and legal journeys.
- Prices originate in EUR and may be localized through Stripe's supported checkout capabilities.
- International purchase availability does not broaden the paid-beta feature corridor or justify country-specific product features before first revenue.

## Preferred product brand and seller-name boundary

Decision date: 2026-07-21

- **Wegsam** is the approved working product name, replacing PlanGoReminisce subject to final domain availability and formal trademark clearance.
- The German root and meaning (passable/accessible) plus the echo of “gemeinsam” fit the group-travel positioning and remain reasonably pronounceable internationally.
- Preferred German tagline: **Gemeinsam unterwegs.**
- Working English message: **Plan together. Travel together. Remember together.**
- The legal seller remains the owner's full civil name as a German Einzelunternehmer; no separate umbrella-company brand is required for first revenue.
- `wegsam.duzend.net` is the approved initial public product address; purchasing a standalone domain is explicitly deferred and does not block development or the paid beta.
- `plangoreminisce.duzend.net` remains a legacy/staging address during transition and should ultimately redirect without losing the existing trip or uploads.
- The repository may be renamed to the Wegsam working brand, but broad public promotion and material brand investment remain gated by appropriate DPMA/EUIPO trademark review.

## First-customer prospect pool

Decision date: 2026-07-21

- The owner has approximately three to five personal contacts who regularly organize group trips and could be approached for the paid beta.
- Prospect names and personal contact details must not be committed to the repository; use anonymized prospect slots in planning receipts.
- **No outreach is currently authorized.** The owner considers the application unfinished and it is too early to approach prospects.
- Outreach remains gated by completion of the paid-beta product corridor, mobile acceptance, working staging, backup/restore proof, payment/legal readiness and an explicit owner go/no-go walkthrough.
- Only after that explicit approval may outreach wording and follow-up handling be prepared for actual use.

## Approved post-subscription access

Decision date: 2026-07-16

- Full paid access continues through the end of the already-paid billing period.
- After paid access ends, existing trips become a free read-only archive for organizers and invited participants.
- Existing trip information, expenses and memories remain viewable, and users can download their own photos/data.
- Creating trips, editing, uploading and inviting require an active organizer subscription.
- Resubscribing restores write access without a separate restoration fee.
- There is no short automatic 30- or 90-day deletion window. User-requested deletion remains supported; any future inactive-data retention limit requires transparent advance notice.

## Approved refund and withdrawal policy

Decision date: 2026-07-20

- Offer a full, no-questions-asked refund within 14 days of the first monthly or annual subscription purchase.
- After that period, cancellation stops future renewal; no prorated refund is promised for the current billing period.
- Refund an accidental annual renewal when requested within seven days.
- Duplicate charges, material service failures and mandatory statutory claims remain refundable outside these voluntary windows.
- After a refund and paid-access expiry, the trip follows the approved free read-only archive behavior.
- Statutory consumer rights are not limited, and Stripe Managed Payments may issue refunds under its Merchant-of-Record rules.
- The final checkout wording, withdrawal instructions and policy must receive appropriate professional/legal review before live payments.

## Approved existing production-data handling

Decision date: 2026-07-20

- Production contains one old real-world test trip created with the owner's friends in 2025; it is not disposable seed data.
- Preserve and migrate the trip rather than resetting production.
- Create and verify a full production backup before any migration or risky deployment.
- Export or separately back up the trip's original uploaded images so they can be restored independently of the application database.
- Do not enroll any existing account into a paid subscription automatically.
- Any legacy-account communication or access change must be explicit and non-destructive.
