# Status Quo (2026-04-09)

## Stack
1. Backend: Ruby on Rails 8.1.
2. Frontend: Hotwire (Turbo + Stimulus), server-rendered HTML.
3. Database: SQLite in `storage/`.
4. Styling: Tailwind CSS.
5. Deploy: Kamal on a single Hetzner host.

## Current feature baseline
1. Authentication, invitations and trip context switching exist.
2. Trip areas are structured around `Home`, `Trip`, `Plans`, `Memories`, `Expenses`.
3. Date proposal/calendar planning exists.
4. Expense tracking exists.
5. Recipe management and shopping lists exist.
6. Meal planning is currently being reworked from recipe selection toward calendar-based meal plans.
7. Attachments, journal/memories and discussions exist.
8. The intended first real-world test scope includes all major areas, not just planning.
9. The old `selected_for_shopping` recipe flag is considered legacy and should be removed during stabilization.

## Current engineering reality
1. Local documentation is partly outdated and must not be treated as source of truth.
2. The current uncommitted work is centered on meal planning and shopping list generation.
3. The app boots locally when executed with the intended Ruby/Bundler toolchain.
4. Controller-level regression checks for trip switching and plans routing are passing again.
5. Rails-Systemtests now run with Playwright instead of Selenium.
6. The verified automated regression baseline now covers plans, trip switching, shopping generation, memories, expenses, invitations, trip attachments, key trip pages, model logic and the current meal-planning system flow.
7. The current broad verified corridor is `106 runs, 278 assertions, 0 failures, 0 errors, 0 skips`.
8. Mobile-first behavior must be treated as a release criterion, especially around media upload.
9. Remaining warning noise is narrowed down to a non-blocking local VIPS module warning and an upstream `marcel` warning under Ruby 3.4.
10. The shopping flow is currently being refactored toward a three-step process: `Meal Plan -> Shopping Plan -> Shopping List`.
11. The latest uncommitted shopping work adds Turbo-updated shopping rows, a compact `Shopping Plan`, bulk assignment to lists, and a rapid-add footer that is still being tuned for mobile spacing.
12. `Plans` navigation is intended to return users to the last selected secondary tab instead of always resetting to `Meal Plan`.

## Deployment baseline
1. Current production host is `plangoreminisce.duzend.net`.
2. Existing production data lives in the Kamal volume `plangoreminisce_storage`.
3. A staging target is now scaffolded via `config/deploy.staging.yml`.
4. Planned staging host is `staging.plangoreminisce.duzend.net`.
5. Staging uses its own Kamal service name and its own persistent volume `plangoreminisce_staging_storage`.
6. Near-term work should deploy to staging first; production remains unchanged until the staging version is trusted.

## Short-term priorities
1. Introduce staging and deploy the current code there without touching the legacy MVP data.
2. Back up the current production SQLite/Active Storage data before any migration work.
3. Audit the old production schema/data and decide what can be migrated into the new app cleanly.
4. Replace outdated docs with a compact status/testing/deploy baseline.
5. Validate mobile-first core flows, with special attention to iPhone photo upload behavior.
