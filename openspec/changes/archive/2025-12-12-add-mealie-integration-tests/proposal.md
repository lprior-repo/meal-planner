# Change: Add Mealie Integration Test Coverage

## Why
Currently, Mealie recipe integration lacks comprehensive test coverage. The auto planner, recipe mapper, and food logging features work with Mealie recipes but have minimal automated testing. This creates risk when modifying these integration points.

## What Changes
- Add test coverage for auto planner with Mealie recipes (save/load, filtering, planning)
- Add test coverage for Mealie recipe mapper (`mealie_to_recipe` conversion)
- Add test coverage for `filter_recipes_by_macros` function
- Add test coverage for food logging with `mealie_recipe` source type
- Verify auto planner works without local recipe storage (Mealie-only mode)

## Impact
- **Affected specs**: mealie-integration
- **Affected code**:
  - `gleam/test/auto_planner_test.gleam` - Add Mealie recipe tests
  - `gleam/test/mealie_mapper_test.gleam` - Expand mapper tests
  - `gleam/test/mealie_client_test.gleam` - Add filtering tests
  - `gleam/test/food_log_api_test.gleam` - Add Mealie source tests
- **Beads tasks**:
  - meal-planner-9hk0 (save/load)
  - meal-planner-l5tz (end-to-end)
  - meal-planner-tslc (no local storage)
  - meal-planner-kb6k (filter by macros)
  - meal-planner-5bjq (mapper)
  - meal-planner-yyxg (MealieRecipe input)
  - meal-planner-tafs (food logs)
