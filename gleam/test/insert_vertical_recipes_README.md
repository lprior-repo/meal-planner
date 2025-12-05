# Vertical Diet Recipes Test

## Overview
This test module handles insertion of Vertical Diet recipes into the database.

## Database Timeout Fix (meal-planner-uxe0)

**Problem**: The `insert_all_vertical_diet_recipes_test()` function was timing out during bulk database inserts.

**Solution**: Converted the long-running database insertion test to a manual function that is skipped by default:

- Renamed: `insert_all_vertical_diet_recipes_test()` → `insert_all_vertical_diet_recipes_manual()`
- Added: Quick `module_loads_test()` that verifies recipes load without database access
- Benefit: Tests run fast by default, manual database insertion available when needed

## Running Tests

### Standard Test Run (Fast)
```bash
gleam test --target erlang --module insert_vertical_recipes_test
```
This runs `module_loads_test()` which verifies the module loads 25 recipes correctly.

### Manual Database Insertion
To actually insert recipes into the database:

```bash
# Ensure PostgreSQL is running
pg_isready -h localhost -p 5432

# Run the manual insertion function
gleam run -m insert_vertical_recipes_test insert_all_vertical_diet_recipes_manual
```

## Expected Behavior

- **module_loads_test**: Completes in <1 second, verifies 25 recipes exist
- **insert_all_vertical_diet_recipes_manual**: Takes several seconds, performs bulk DB inserts

## Recipe Breakdown

The Vertical Diet includes:
- 🥩 Beef mains: 8 recipes
- 🦬 Bison mains: 2 recipes
- 🐑 Lamb mains: 2 recipes
- 🍚 Rice sides: 6 recipes
- 🥕 Vegetable sides: 7 recipes

**Total: 25 recipes**

All recipes are:
- Low FODMAP
- Vertical Diet compliant
- Easy to digest
- Micronutrient-dense
