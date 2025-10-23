# Navigation Redesign with Test Coverage

## Overview
Restructure the app from phase-based (Plan/Go/Reminisce) to feature-based navigation with persistent trip context, Twitter-style responsive design (bottom nav on mobile, left sidebar on desktop). **Full test coverage using Minitest.**

## Context & Rationale

Originally, the app was structured around 3 phases of a trip: Plan, Go, and Reminisce. However, during development, it became clear that many features are relevant to multiple stages, making this structure inflexible.

**Key insights:**
- Users operate within the context of a single trip most of the time
- Features span multiple "phases" (expenses, journal entries, photos are used throughout)
- Users have many trips over a longer time horizon
- Need to maintain trip context while allowing easy switching between trips

## New Navigation Structure

### Mobile (< 768px)
- **Fixed bottom nav:** Home | Trip | Plans | Memories | Expenses
- **Top bar:** [ Back] [Context/Trip Name] [=¡ Help] [=d Avatar]
- **Avatar:** Opens slide-in side panel from left

### Desktop (>= 768px)
- **Fixed left sidebar:** Home | Trip | Plans | Memories | Expenses
- **Top bar:** [Context/Trip Name] [=¡ Help] [=d Avatar]
- **Avatar:** Opens dropdown/panel from top-right

### Navigation Items Explained

1. **<à Home** - Overview of all trips, dashboard, recent activity
2. ** Trip** - Current/selected trip OR next scheduled trip OR create trip prompt
3. **=Ë Plans** - Scheduling, dates, shopping lists, meal plans, discussions (scoped to current trip)
4. **=÷ Memories** - View memories, create Instagram-style posts, photos, journal entries (scoped to current trip)
5. **=° Expenses** - Expense tracking and splitting (scoped to current trip)

### Avatar Side Panel Contents
- Profile/Settings
- Invitations (with notification badge)
- Sign Out
- (Future: Recipes, Overall Calendar, etc.)

### Auto-scoping Behavior
- **Home**: Always shows all trips
- **Trip**: Shows current trip (or next scheduled, or create prompt)
- **Plans/Memories/Expenses**: Auto-scope to current trip when one is selected, otherwise prompt to select a trip

---

## Implementation Plan (TDD Approach)

### Phase 1: Trip Context Management (with tests)

#### 1.1 Create TripContext Concern Test
**File:** `test/controllers/concerns/trip_context_test.rb`

Tests:
- Setting current trip in session
- Retrieving current trip from session
- Falling back to next scheduled trip
- Clearing trip context
- Authorization (user must own or be member)

#### 1.2 Implement TripContext Concern
**File:** `app/controllers/concerns/trip_context.rb`

Methods:
- `set_current_trip(trip)` - stores trip_id in session
- `current_trip` - retrieves from session, validates access
- `current_trip_or_next` - returns current or next scheduled
- `clear_trip_context` - clears session
- Includes authorization checks

#### 1.3 Update ApplicationHelper Tests
**File:** `test/helpers/application_helper_test.rb`

Tests:
- `current_trip_context` with session persistence
- `trip_switcher_path` helper
- `scoped_path(feature)` for auto-scoping

#### 1.4 Update ApplicationHelper
**File:** `app/helpers/application_helper.rb`

Updates:
- Modify `current_trip_context` to check session first
- Add `trip_switcher_path`
- Add `scoped_path(feature)` for smart routing

---

### Phase 2: New Controllers (with tests)

#### 2.1 Home Controller Tests
**File:** `test/controllers/home_controller_test.rb`

Tests:
- Index shows all user trips (owned + member)
- Displays recent activity
- No trips state (prompts create)
- Authentication required

#### 2.2 Implement Home Controller
**File:** `app/controllers/home_controller.rb`
- `index` - shows all trips, recent activity, stats

#### 2.3 Plans Controller Tests
**File:** `test/controllers/plans_controller_test.rb`

Tests:
- Index requires trip context
- Shows date proposals, discussions, shopping lists
- Redirects to trip selection if no context
- Scopes to current trip only
- Authorization (must be trip owner/member)

#### 2.4 Implement Plans Controller
**File:** `app/controllers/plans_controller.rb`
- `index` - aggregates planning features for current trip
- Includes: date proposals, discussions, shopping lists, recipes

#### 2.5 Memories Controller Tests
**File:** `test/controllers/memories_controller_test.rb`

Tests:
- Index requires trip context
- Shows journal entries and attachments
- Filters by current trip
- Create memory (Instagram-style post)
- Pagination
- Authorization

#### 2.6 Implement Memories Controller
**File:** `app/controllers/memories_controller.rb`
- `index` - aggregates journal entries, photos for current trip
- `create` - create new memory/journal entry

---

### Phase 3: Navigation Components (with system tests)

#### 3.1 System Test: Avatar Side Panel
**File:** `test/system/avatar_side_panel_test.rb`

Tests:
- Clicking avatar opens side panel
- Panel contains: Profile, Invitations, Sign Out
- Invitations show badge count
- Clicking outside closes panel
- Sign out works from panel
- Mobile slide-in animation
- Desktop dropdown behavior

#### 3.2 Create Avatar Side Panel Partial
**Files:**
- `app/views/shared/_avatar_side_panel.html.erb`
- `app/javascript/controllers/side_panel_controller.js`

#### 3.3 System Test: Top Bar
**File:** `test/system/top_bar_test.rb`

Tests:
- Shows app name when no trip context
- Shows trip name when in trip context
- Back button navigates correctly
- Help icon present
- Avatar button triggers panel
- Trip name is clickable for trip switching

#### 3.4 Create Top Bar Partial
**File:** `app/views/shared/_top_bar.html.erb`

#### 3.5 System Test: Bottom Navigation (Mobile)
**File:** `test/system/bottom_navigation_test.rb`

Tests:
- All 5 nav items visible on mobile
- Active state highlighting
- Navigation to each section
- Hidden on desktop
- Trip context auto-scoping

#### 3.6 Update Bottom Navigation
**File:** `app/views/shared/_bottom_navigation.html.erb`

#### 3.7 System Test: Left Sidebar (Desktop)
**File:** `test/system/left_sidebar_test.rb`

Tests:
- Sidebar visible on desktop only
- All 5 nav items present
- Active state highlighting
- Fixed positioning
- Trip context auto-scoping

#### 3.8 Create Left Sidebar Partial
**File:** `app/views/shared/_left_sidebar.html.erb`

---

### Phase 4: Trip Switching (with tests)

#### 4.1 Trip Switcher Controller Tests
**File:** `test/controllers/trip_switcher_controller_test.rb`

Tests:
- GET shows all user trips
- POST switches to selected trip
- Validates user has access to trip
- Redirects back to previous page after switch
- Clears trip context (switch to "no trip")

#### 4.2 Implement Trip Switcher
**File:** `app/controllers/trip_switcher_controller.rb`
- `index` - show trip selection modal/page
- `update` - set selected trip in session
- `destroy` - clear trip context

#### 4.3 Trip Switcher View
**File:** `app/views/trip_switcher/index.html.erb`
- Modal/overlay with all trips
- Current trip highlighted
- Option to clear selection

---

### Phase 5: Routes & Layout (with tests)

#### 5.1 Routes Test
**File:** `test/routing/navigation_routes_test.rb`

Tests:
- Home route
- Trip switcher routes
- Plans/memories routes
- Backward compatibility with phase routes

#### 5.2 Update Routes
**File:** `config/routes.rb`

Changes:
- Add home route (or update root)
- Add trip switcher routes
- Add plans routes
- Add memories routes
- Keep old phase routes for compatibility

#### 5.3 Integration Test: Full Navigation Flow
**File:** `test/integration/navigation_flow_test.rb`

Test complete user journey:
1. Sign in ’ Home
2. Select trip ’ Trip context set
3. Navigate to Plans ’ scoped to trip
4. Navigate to Memories ’ scoped to trip
5. Switch trip ’ context updates
6. Clear trip ’ context cleared
7. Open avatar panel ’ sign out

#### 5.4 Update Application Layout
**File:** `app/views/layouts/application.html.erb`

Changes:
- Remove old top nav
- Add new top bar
- Add left sidebar (desktop)
- Keep bottom nav (mobile)
- Add side panel

---

### Phase 6: Helper Updates (with tests)

#### 6.1 Helper Tests
**File:** `test/helpers/navigation_helper_test.rb`

Tests:
- `active_nav_class(section)`
- `trip_context_display`
- `scoped_feature_path(feature)`

#### 6.2 Create Navigation Helper
**File:** `app/helpers/navigation_helper.rb`

Methods:
- Active state detection for nav items
- Trip context display helpers
- Smart path generation

---

### Phase 7: Styling

#### 7.1 Update CSS
**File:** `app/assets/stylesheets/application.css`

Additions:
- Left sidebar styles
- Avatar side panel styles (slide-in animation)
- Top bar styles
- Responsive breakpoints
- Active state indicators

---

### Phase 8: Testing & Verification

#### 8.1 Run Test Suite
```bash
# Unit/integration tests
rails test

# System tests
rails test:system

# All tests
rails test:all
```

---

## Test Files to Create

### Unit Tests (Minitest)
1. `test/controllers/concerns/trip_context_test.rb`
2. `test/helpers/application_helper_test.rb`
3. `test/helpers/navigation_helper_test.rb`
4. `test/controllers/home_controller_test.rb`
5. `test/controllers/plans_controller_test.rb`
6. `test/controllers/memories_controller_test.rb`
7. `test/controllers/trip_switcher_controller_test.rb`
8. `test/routing/navigation_routes_test.rb`

### Integration Tests (Minitest)
9. `test/integration/navigation_flow_test.rb`

### System Tests (Capybara)
10. `test/system/avatar_side_panel_test.rb`
11. `test/system/top_bar_test.rb`
12. `test/system/bottom_navigation_test.rb`
13. `test/system/left_sidebar_test.rb`
14. `test/system/trip_switching_test.rb`

---

## Implementation Files to Create/Modify

### Create
- `app/controllers/concerns/trip_context.rb`
- `app/controllers/home_controller.rb`
- `app/controllers/plans_controller.rb`
- `app/controllers/memories_controller.rb`
- `app/controllers/trip_switcher_controller.rb`
- `app/views/home/index.html.erb`
- `app/views/plans/index.html.erb`
- `app/views/memories/index.html.erb`
- `app/views/trip_switcher/index.html.erb`
- `app/views/shared/_top_bar.html.erb`
- `app/views/shared/_avatar_side_panel.html.erb`
- `app/views/shared/_left_sidebar.html.erb`
- `app/javascript/controllers/side_panel_controller.js`
- `app/helpers/navigation_helper.rb`

### Modify
- `app/views/layouts/application.html.erb`
- `app/views/shared/_bottom_navigation.html.erb`
- `app/helpers/application_helper.rb`
- `app/controllers/application_controller.rb`
- `config/routes.rb`
- `app/assets/stylesheets/application.css`

---

## Success Criteria

 All new tests passing (100% coverage for new code)
 Existing tests still passing (no regressions)
 Navigation works on mobile and desktop
 Trip context persists across page loads
 Trip switching works from sidebar/top bar
 Avatar panel opens/closes correctly
 Auto-scoping to current trip works
 Backward compatibility maintained

---

## Future Enhancements

- Hotwire Native integration for mobile apps
- Recipe library in avatar menu
- Overall calendar view
- Advanced trip analytics
- Collaborative features expansion
