# Mealie Integration Specification

## ADDED Requirements

### Requirement: Mealie Recipe Mapper Test Coverage
The test suite SHALL verify that Mealie recipes are correctly converted to internal Recipe types with all fields mapped appropriately.

#### Scenario: Complete recipe conversion
- **WHEN** `mealie_to_recipe` is called with a complete MealieRecipe
- **THEN** all fields (name, slug, ingredients, nutrition) are mapped correctly
- **AND** the resulting Recipe type is valid

#### Scenario: Optional fields handling
- **WHEN** `mealie_to_recipe` is called with missing optional fields
- **THEN** None values are handled gracefully
- **AND** the conversion succeeds without errors

### Requirement: Recipe Filtering by Macros Test Coverage
The test suite SHALL verify that Mealie recipes can be filtered based on macronutrient targets with configurable tolerance.

#### Scenario: Exact macro match
- **WHEN** `filter_recipes_by_macros` is called with recipes matching target macros
- **THEN** matching recipes are returned
- **AND** non-matching recipes are excluded

#### Scenario: Tolerance range filtering
- **WHEN** recipes are within ±10% of target macros
- **THEN** they are included in filtered results

### Requirement: Auto Planner with Mealie Recipes Test Coverage
The test suite SHALL verify that the auto planner can generate meal plans using Mealie recipes as input.

#### Scenario: Mealie recipe input
- **WHEN** auto planner receives MealieRecipe list
- **THEN** recipes are converted to internal type
- **AND** meal plan is generated successfully
- **AND** selected recipes maintain Mealie metadata

#### Scenario: Save and load with recipe_json
- **WHEN** a meal plan with Mealie recipes is saved
- **THEN** `recipe_json` field contains full recipe data
- **AND** loading the plan reconstructs recipes correctly

#### Scenario: No local storage mode
- **WHEN** auto planner runs without local recipe database
- **THEN** it uses only Mealie recipes
- **AND** meal plan generation succeeds

### Requirement: Food Logging with Mealie Source Test Coverage
The test suite SHALL verify that food logs can track meals from Mealie recipes with proper source attribution.

#### Scenario: Create log with Mealie recipe
- **WHEN** a food log is created with `source_type = "mealie_recipe"`
- **THEN** log is saved with `recipe_json` field populated
- **AND** macros are calculated from Mealie nutrition data

#### Scenario: Retrieve Mealie-sourced logs
- **WHEN** food logs are queried for a date
- **THEN** Mealie-sourced logs include full recipe data
- **AND** macros aggregate correctly across all sources

### Requirement: End-to-End Integration Test Coverage
The test suite SHALL verify the complete workflow from Mealie API fetch to meal plan generation and food logging.

#### Scenario: Full integration workflow
- **WHEN** recipes are fetched from Mealie API
- **THEN** they can be filtered by macros
- **AND** used in auto meal planning
- **AND** logged as food entries
- **AND** all steps complete without errors
