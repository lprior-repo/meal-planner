# Feature: Nutrition Dashboard UI Component

## Bead ID: meal-planner-baj

## Feature Description
Build an interactive nutrition dashboard UI component that displays daily macro tracking with progress bars, calorie summary, and meal logging interface.

## Capabilities

### Capability 1: Display Daily Macro Progress
**Behaviors:**
- GIVEN a user profile with daily targets WHEN the dashboard loads THEN display protein/fat/carbs progress bars
- GIVEN current intake of 120g protein vs 180g target WHEN rendering THEN show 67% filled progress bar
- GIVEN intake exceeds target WHEN rendering THEN cap progress bar at 100% with overflow indicator

### Capability 2: Show Calorie Summary
**Behaviors:**
- GIVEN daily macros WHEN calculating calories THEN use formula: (protein*4) + (fat*9) + (carbs*4)
- GIVEN current and target macros WHEN displaying THEN show "current / target cal" format
- GIVEN zero intake WHEN displaying THEN show "0 / target cal"

### Capability 3: Integrate with SSR Dashboard Page
**Behaviors:**
- GIVEN server/src/server/web.gleam dashboard_page WHEN rendering THEN use Lustre elements
- GIVEN user profile from storage WHEN loading THEN calculate targets via types.daily_macro_targets
- GIVEN daily log WHEN loading THEN sum entries for total_macros

## Acceptance Criteria
- [ ] Progress bars render with correct percentages
- [ ] Calorie calculation matches shared/types.gleam macros_calories function
- [ ] Dashboard integrates with existing storage module
- [ ] All new code has corresponding tests
- [ ] Zero runtime errors on page load

## Test Criteria (BDD)
```gherkin
Scenario: Display macro progress for user with partial intake
  Given a user with bodyweight 180 lbs and moderate activity
  And daily targets of 180g protein, 54g fat, 315g carbs
  And current intake of 120g protein, 40g fat, 200g carbs
  When the dashboard renders
  Then protein bar shows 67% (120/180)
  And fat bar shows 74% (40/54)
  And carbs bar shows 63% (200/315)
  And calorie summary shows "1640 / 2484 cal"
```
