# Feature: Live Dashboard with Real Data Integration

## Bead ID: meal-planner-8rh

## Parent Epic: meal-planner-g8s (Meal Planner Web Application MVP)

## Dependencies
- meal-planner-baj: Nutrition dashboard UI (CLOSED)

## Feature Description
Connect the nutrition dashboard to real storage data, displaying actual daily food logs instead of hardcoded sample data. Enable real-time macro tracking throughout the day.

## Capabilities

### Capability 1: Load Daily Log from Storage
**Behaviors:**
- GIVEN dashboard page request WHEN loading THEN fetch today's food log from SQLite
- GIVEN date parameter WHEN provided THEN load that day's food log
- GIVEN no entries for date WHEN loading THEN return empty macros (0, 0, 0)

### Capability 2: Calculate Real-Time Progress
**Behaviors:**
- GIVEN daily log entries WHEN displaying THEN sum all entry macros for totals
- GIVEN user profile WHEN calculating targets THEN use profile-based macro targets
- GIVEN current vs target WHEN rendering THEN show accurate progress percentages

### Capability 3: Display Today's Meals
**Behaviors:**
- GIVEN food log entries WHEN rendering THEN show meal cards with name, time, macros
- GIVEN entry WHEN clicking THEN allow editing serving size
- GIVEN entry WHEN deleting THEN remove from log and update totals

### Capability 4: Date Navigation
**Behaviors:**
- GIVEN dashboard WHEN user clicks previous/next THEN navigate to adjacent days
- GIVEN date picker WHEN user selects date THEN load that day's log
- GIVEN historical date WHEN viewing THEN show read-only historical data

## Acceptance Criteria
- [ ] Dashboard loads real data from food_logs table
- [ ] Progress bars reflect actual intake vs targets
- [ ] Today's meals list shows logged entries
- [ ] Date navigation works for past 30 days
- [ ] Empty state handles days with no entries

## Test Criteria (BDD)
```gherkin
Scenario: Dashboard shows real daily intake
  Given user has logged "Chicken and Rice" for lunch today
  And the meal has 45g protein, 8g fat, 45g carbs
  When user visits /dashboard
  Then protein progress shows 45g consumed
  And calorie display shows 432 calories

Scenario: Empty day shows zero progress
  Given no food entries exist for today
  When user visits /dashboard
  Then all macro bars show 0%
  And calorie display shows "0 / target"
```
