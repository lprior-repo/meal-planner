# Vertical Slice Architecture

Each feature directory contains:
- **flow.yaml** - Windmill workflow orchestrating the feature
- **lambdas/** - Rust scripts specific to this feature
- **schemas/** - JSON schemas for request/response
- **tests/** - Integration tests for the feature

## Features

### nutrition-compliance
Daily nutrition compliance checking and recommendations.
- Lambdas: calculate_deviation, check_tolerance, generate_recommendations
- Flow: Daily compliance check workflow

### meal-planning  
Automated meal plan generation and optimization.
- Lambdas: fetch_recipes, filter_by_preferences, optimize_macros, generate_plan
- Flow: Meal planning workflow

### recipe-sync
Sync recipes from Tandoor to local database.
- Lambdas: fetch_tandoor_recipes, transform_recipe, store_recipe
- Flow: Recipe sync workflow

### grocery-list
Generate shopping lists from meal plans.
- Lambdas: extract_ingredients, consolidate_quantities, categorize_items
- Flow: Grocery list generation workflow
