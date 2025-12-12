# Implementation Tasks

## 1. Mealie Mapper Tests
- [ ] 1.1 Test `mealie_to_recipe` conversion with complete recipe
- [ ] 1.2 Test `mealie_to_recipe` with missing optional fields
- [ ] 1.3 Test nutrition data parsing edge cases
- [ ] 1.4 Verify ingredient mapping accuracy

## 2. Filter by Macros Tests
- [ ] 2.1 Test `filter_recipes_by_macros` with exact matches
- [ ] 2.2 Test with tolerance ranges (±10%)
- [ ] 2.3 Test with empty recipe list
- [ ] 2.4 Test with no matching recipes

## 3. Auto Planner with Mealie Tests
- [ ] 3.1 Test auto planner with MealieRecipe input (convert → plan)
- [ ] 3.2 Test save/load meal plan with `recipe_json` field
- [ ] 3.3 Test auto planner without local recipe storage (Mealie-only)
- [ ] 3.4 Test end-to-end: fetch from Mealie → filter → plan → save

## 4. Food Logging with Mealie Tests
- [ ] 4.1 Test creating food log with `mealie_recipe` source type
- [ ] 4.2 Test retrieving food logs with Mealie source
- [ ] 4.3 Test macro aggregation with Mealie recipes
- [ ] 4.4 Verify `recipe_json` field populated correctly

## 5. Integration Validation
- [ ] 5.1 Run full test suite and verify all tests pass
- [ ] 5.2 Test with real Mealie instance (manual verification)
- [ ] 5.3 Update documentation with test coverage info
