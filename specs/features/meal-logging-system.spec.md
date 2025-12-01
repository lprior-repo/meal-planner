# Feature: Meal Logging System

## Bead ID: meal-planner-oix

## Parent Epic: meal-planner-g8s (Meal Planner Web Application MVP)

## Dependencies
- meal-planner-67c: USDA import (CLOSED)

## Feature Description
Enable users to log meals throughout the day by selecting recipes or searching USDA foods, specifying serving sizes, and tracking their nutritional intake.

## Capabilities

### Capability 1: Log Meal from Recipe
**Behaviors:**
- GIVEN recipe list WHEN user selects recipe THEN show serving size input
- GIVEN serving size WHEN user confirms THEN create food log entry
- GIVEN entry WHEN created THEN store in food_logs with timestamp and meal type

### Capability 2: Log Meal from USDA Food Search
**Behaviors:**
- GIVEN search query WHEN user types THEN show matching USDA foods
- GIVEN USDA food WHEN selected THEN show portion size input (grams)
- GIVEN portion WHEN confirmed THEN calculate macros and create entry

### Capability 3: Quick Log Recent Meals
**Behaviors:**
- GIVEN user history WHEN logging THEN show 5 most recent meals
- GIVEN recent meal WHEN selected THEN pre-fill serving size
- GIVEN quick log WHEN confirmed THEN create entry with one click

### Capability 4: Edit and Delete Entries
**Behaviors:**
- GIVEN logged entry WHEN editing THEN allow serving size change
- GIVEN edited entry WHEN saved THEN recalculate macros
- GIVEN entry WHEN deleted THEN remove from daily log

### Capability 5: Meal Type Classification
**Behaviors:**
- GIVEN new entry WHEN logging THEN auto-suggest meal type by time
- GIVEN meal types WHEN available THEN offer Breakfast, Lunch, Dinner, Snack
- GIVEN meal type WHEN set THEN store with entry for filtering

## Acceptance Criteria
- [ ] Users can log meals from recipe list
- [ ] Users can search and log USDA foods
- [ ] Recent meals appear for quick re-logging
- [ ] Entries can be edited and deleted
- [ ] Meal type is captured with each entry

## Test Criteria (BDD)
```gherkin
Scenario: Log a recipe as lunch
  Given user is on meal logging page
  When user selects "Chicken and Rice" recipe
  And enters serving size 1.5
  And confirms as "Lunch"
  Then entry appears in today's food log
  And macros are calculated as 1.5x recipe macros

Scenario: Log USDA food by search
  Given user searches for "banana"
  When user selects "Bananas, raw"
  And enters portion size 118g (1 medium)
  Then entry shows ~105 calories, 27g carbs
```
