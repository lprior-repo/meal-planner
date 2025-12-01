# Feature: Weekly Meal Planning

## Bead ID: meal-planner-0fq

## Parent Epic: meal-planner-g8s (Meal Planner Web Application MVP)

## Dependencies
- Recipe Management CRUD

## Feature Description
Enable users to plan meals for the upcoming week, with automatic shopping list generation and nutritional balance optimization.

## Capabilities

### Capability 1: Create Weekly Plan
**Behaviors:**
- GIVEN week view WHEN displayed THEN show 7 days with meal slots
- GIVEN meal slot WHEN clicking THEN show recipe selector
- GIVEN recipe WHEN selected THEN assign to day/meal slot
- GIVEN plan WHEN saved THEN persist to weekly_plans table

### Capability 2: Auto-Generate Plan
**Behaviors:**
- GIVEN user profile WHEN auto-generating THEN optimize for macro targets
- GIVEN recipes WHEN selecting THEN consider variety and preferences
- GIVEN FODMAP settings WHEN enabled THEN filter low-FODMAP only
- GIVEN generated plan WHEN presented THEN allow user modifications

### Capability 3: View Weekly Nutrition Summary
**Behaviors:**
- GIVEN weekly plan WHEN viewing THEN show daily macro totals
- GIVEN averages WHEN calculating THEN show weekly protein/fat/carb averages
- GIVEN targets WHEN comparing THEN highlight over/under days

### Capability 4: Generate Shopping List
**Behaviors:**
- GIVEN weekly plan WHEN generating list THEN aggregate all ingredients
- GIVEN duplicate ingredients WHEN combining THEN sum quantities
- GIVEN shopping list WHEN exporting THEN support text/PDF formats

### Capability 5: Copy and Modify Plans
**Behaviors:**
- GIVEN previous week WHEN copying THEN duplicate to new week
- GIVEN template plan WHEN applying THEN use as starting point
- GIVEN plan WHEN modifying THEN allow swap/remove/add meals

## Acceptance Criteria
- [ ] Users can manually plan meals for 7 days
- [ ] Auto-generate creates balanced weekly plan
- [ ] Weekly nutrition summary shows macro breakdown
- [ ] Shopping list aggregates ingredients correctly
- [ ] Plans can be copied and modified

## Test Criteria (BDD)
```gherkin
Scenario: Plan a week manually
  Given user is on weekly planning page
  When user assigns "Oatmeal" to Monday breakfast
  And assigns "Chicken Salad" to Monday lunch
  And saves the plan
  Then Monday shows both meals
  And daily macro total updates

Scenario: Generate shopping list
  Given weekly plan has 14 meals assigned
  When user generates shopping list
  Then all unique ingredients appear
  And quantities are summed per ingredient
```
