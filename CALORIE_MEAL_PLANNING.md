# Calorie-Based Meal Planning Features

This document describes the new calorie-goal-based meal planning and recipe selection features added to the meal-planner system.

## Overview

Four new Windmill flows have been created to enable sophisticated meal planning based on calorie targets:

1. **`grocery_list_by_calories`** - Simple daily calorie-based grocery list builder
2. **`meal_planner_weekly_by_calories`** - Advanced weekly planner with automatic budget distribution
3. **`smart_recipe_selector`** - Recipe discovery with keyword + calorie filtering
4. **`batch_meal_planning`** - Batch create meal plans from explicit recipe and date lists

Additionally, a new Windmill script wraps the existing `tandoor_recipe_select_by_calories` binary:

5. **`recipe_select_by_calories`** - Low-level recipe selection by calorie range

## Flow Details

### 1. Grocery List by Calories (`grocery_list_by_calories`)

**Purpose:** Build a grocery list for specified dates with per-meal calorie targets.

**Input Parameters:**
```json
{
  "cooking_dates": ["2025-01-15", "2025-01-16", "2025-01-17"],
  "daily_calories": 2000,
  "min_calories": 300,
  "max_calories": 800,
  "meals_per_day": 1,
  "meal_type_id": 3,
  "servings": 1
}
```

**What it does:**
1. Fetches all recipes with calorie data
2. For each cooking date, selects recipes that fit within calorie constraints
3. Creates meal plans for each recipe-date pair
4. Adds all recipes to the shopping list
5. Returns aggregated shopping list with nutrition summary

**Output:**
```json
{
  "summary": {
    "recipes_selected": 3,
    "meal_plans_created": 3,
    "shopping_items": 12,
    "total_calories": 6000,
    "average_calories_per_meal": 2000
  },
  "recipes": [
    {"id": 1, "name": "Grilled Chicken", "calories": 450},
    {"id": 2, "name": "Pasta Primavera", "calories": 380}
  ],
  "meal_plans": [
    {"id": 1, "date": "2025-01-15", "recipe": "Grilled Chicken", "servings": 1}
  ],
  "shopping_list": [
    {"food": "Chicken Breast", "amount": 500, "unit": "g", "checked": false},
    {"food": "Olive Oil", "amount": 2, "unit": "tbsp", "checked": false}
  ]
}
```

**Use Cases:**
- Plan a specific week with daily calorie targets
- Generate shopping lists that match your diet goals
- One meal per day planning (breakfast, lunch, or dinner)

**Example Usage:**
```bash
# Plan 7 days with 2000 calories per day
curl -X POST http://windmill/api/flows/f/tandoor/grocery_list_by_calories/execute \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "cooking_dates": ["2025-01-15", "2025-01-16", "2025-01-17", "2025-01-18", "2025-01-19", "2025-01-20", "2025-01-21"],
    "daily_calories": 2000,
    "min_calories": 300,
    "max_calories": 800,
    "meals_per_day": 1
  }'
```

---

### 2. Weekly Meal Planner by Calories (`meal_planner_weekly_by_calories`)

**Purpose:** Plan an entire week with automatic calorie distribution across days and meals.

**Input Parameters:**
```json
{
  "cooking_dates": ["2025-01-15", "2025-01-16", "2025-01-17", "2025-01-18", "2025-01-19", "2025-01-20", "2025-01-21"],
  "weekly_calories": 14000,
  "meals_per_day": 1,
  "min_calories": null,
  "max_calories": null,
  "meal_type_id": 3,
  "servings": 1
}
```

**Key Features:**
- Takes a **weekly calorie budget** and auto-distributes across days
- Automatically adjusts min/max per-meal constraints based on meal count
- Provides detailed nutrition breakdown per day
- Perfect for users who think in terms of weekly budgets (e.g., "14,000 cal/week")

**Calculation Logic:**
- `calories_per_day = weekly_calories / num_days`
- `calories_per_meal = calories_per_day / meals_per_day`
- If min/max not specified, defaults to ±150 calories from target

**Output includes:**
```json
{
  "nutrition_targets": {
    "weekly_budget": 14000,
    "days_planned": 7,
    "meals_per_day": 1,
    "daily_target": 2000,
    "per_meal_target": 2000
  },
  "summary": {
    "total_recipes": 7,
    "total_meal_plans": 7,
    "total_shopping_items": 42,
    "total_calories": 14000,
    "average_calories_per_meal": 2000
  },
  "meal_plans": [...],
  "shopping_list_by_food": [...],
  "detailed_shopping": [...]
}
```

**Use Cases:**
- Weekly meal planning for the whole family
- Budget-based planning (e.g., 2000-2500 cal/day × 7 days)
- Multiple meals per day planning (breakfast + lunch + dinner)
- Flexible date ranges (can plan 3 days, 14 days, etc.)

**Example Usage:**
```bash
# Plan 7 days with 14000 total calories (2000/day) with 3 meals per day
curl -X POST http://windmill/api/flows/f/tandoor/meal_planner_weekly_by_calories/execute \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "cooking_dates": ["2025-01-15", "2025-01-16", "2025-01-17", "2025-01-18", "2025-01-19", "2025-01-20", "2025-01-21"],
    "weekly_calories": 21000,
    "meals_per_day": 3,
    "meal_type_id": 3
  }'
```

---

### 3. Smart Recipe Selector (`smart_recipe_selector`)

**Purpose:** Discover recipes that match specific keywords AND calorie constraints.

**Input Parameters:**
```json
{
  "keyword": "chicken",
  "target_calories": 500,
  "min_calories": 300,
  "max_calories": 700,
  "count": 5
}
```

**What it does:**
1. Fetches all recipes from Tandoor
2. Filters by keyword (if provided) - searches recipe name and description
3. Further filters by calorie range
4. Deterministically selects N recipes
5. Enriches results with full recipe details (prep time, ingredients, etc.)

**Output:**
```json
{
  "search_criteria": {
    "keyword": "chicken",
    "count_requested": 5,
    "min_calories": 300,
    "max_calories": 700,
    "average_calories": 450,
    "total_calories": 2250
  },
  "summary": {
    "recipes_found": 5,
    "keyword_filter": "yes",
    "avg_calories_per_recipe": 450
  },
  "recipes": [
    {
      "index": 1,
      "id": 42,
      "name": "Quick Chicken Stir-fry",
      "calories": 450,
      "description": "Fast and easy weeknight dinner",
      "prep_time_min": 5,
      "cook_time_min": 15,
      "servings": 4,
      "ingredients_count": 8
    }
  ],
  "nutrition_breakdown": {
    "total_recipes": 5,
    "total_calories": 2250,
    "avg_per_recipe": 450,
    "min_recipe_calories": 380,
    "max_recipe_calories": 520
  }
}
```

**Use Cases:**
- Find recipes by keyword + calorie goal
- Recipe discovery for specific diets (e.g., "vegetarian 400-600 cal")
- Quick meal planning for specific cuisines (e.g., "asian 400-500 cal")
- Browse recipes that fit your nutrition plan

**Keyword Examples:**
- `"chicken"` - Find all chicken recipes
- `"quick"` - Find recipes with "quick" in name/description
- `"vegetarian"` - Find vegetarian recipes
- `"greek"` - Find recipes with Greek cuisine
- `"dinner"` - Find dinner recipes

**Example Usage:**
```bash
# Find 5 quick chicken recipes around 400-500 calories
curl -X POST http://windmill/api/flows/f/tandoor/smart_recipe_selector/execute \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "keyword": "quick chicken",
    "target_calories": 450,
    "min_calories": 400,
    "max_calories": 500,
    "count": 5
  }'
```

---

### 4. Batch Meal Planning (`batch_meal_planning`)

**Purpose:** Create meal plans from explicit recipe and date lists with flexible cycling patterns.

**Input Parameters:**
```json
{
  "recipe_ids": [1, 2, 3, 4, 5],
  "cooking_dates": ["2025-01-15", "2025-01-16", "2025-01-17", "2025-01-18", "2025-01-19"],
  "cooking_pattern": "cycle",
  "meal_type_id": 3,
  "servings": 1
}
```

**Cooking Patterns:**
- **`"cycle"`** (default): If more dates than recipes, repeats recipe list
  - 5 recipes + 7 dates → recipes[5] repeats for dates 6-7
- **`"sequential"`**: Uses last recipe for remaining dates if recipes run out

**What it does:**
1. Maps recipes to dates using the specified pattern
2. Creates meal plan entries for each recipe-date pair
3. Adds all recipes to shopping list (supports different servings per meal)
4. Returns shopping list grouped by food and sorted by date

**Output:**
```json
{
  "summary": {
    "meals_planned": 7,
    "unique_recipes": 5,
    "shopping_items": 35,
    "dates_covered": 7,
    "total_recipe_calories": 3250
  },
  "meal_plans": [
    {"id": 1, "date": "2025-01-15", "recipe": "Grilled Chicken", "calories": 450, "servings": 1}
  ],
  "recipes_used": [
    {"id": 1, "name": "Grilled Chicken", "servings": 4, "calories": 450, "prep_time": 5, "cook_time": 15}
  ],
  "shopping_list": [...],
  "grouped_shopping": [...]
}
```

**Use Cases:**
- Plan meals with your favorite recipes
- Rotate recipes across a week
- Create meal plans from a curated list of recipes
- Support different servings per meal
- Quick batch planning without calorie calculation

**Example Usage:**
```bash
# Plan 7 days with 5 favorite recipes, cycling through them
curl -X POST http://windmill/api/flows/f/tandoor/batch_meal_planning/execute \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "recipe_ids": [1, 2, 3, 4, 5],
    "cooking_dates": ["2025-01-15", "2025-01-16", "2025-01-17", "2025-01-18", "2025-01-19", "2025-01-20", "2025-01-21"],
    "cooking_pattern": "cycle",
    "servings": 1.5
  }'
```

---

## Script: Recipe Select by Calories

**Path:** `f/tandoor/recipe_select_by_calories`

**Purpose:** Low-level script for calorie-based recipe filtering. Used internally by flows but can be called directly.

**Input:**
```json
{
  "recipes": [
    {"id": 1, "name": "Recipe A", "calories": 450},
    {"id": 2, "name": "Recipe B", "calories": 380}
  ],
  "target_calories": 2000,
  "min_calories": 300,
  "max_calories": 800,
  "count": 3
}
```

**Output:**
```json
{
  "selected_recipes": [
    {"id": 1, "name": "Recipe A", "calories": 450},
    {"id": 3, "name": "Recipe C", "calories": 520}
  ],
  "stats": {
    "count": 2,
    "total": 970,
    "average": 485,
    "min": 450,
    "max": 520
  },
  "warning": null
}
```

---

## Implementation Details

All flows follow these patterns:

### Architecture
- **Bash scripts** wrap binaries and handle JSON serialization
- **Windmill flows** orchestrate scripts and handle complex logic
- **Nushell formatting** provides rich output formatting and grouping
- **JavaScript transforms** compute dynamic parameters

### Key Features
1. **Deterministic Selection:** Uses `target_calories` as seed for reproducible results
2. **Flexible Filtering:** Min/max constraints + optional keyword filtering
3. **Auto-distribution:** Weekly budgets auto-distribute across days and meals
4. **Grouped Output:** Shopping lists grouped by food with totals
5. **Nutrition Tracking:** Calorie summaries at multiple levels
6. **Error Handling:** `skip_failures: false` ensures data integrity

### Integration Points
- Uses existing `tandoor_recipe_list_flat` binary for recipe fetching
- Uses existing `tandoor_recipe_select_by_calories` binary for filtering
- Uses existing meal planning binaries for creating entries
- Uses existing shopping list binaries for aggregation

---

## Real-World Examples

### Example 1: Weekly Diet Plan (2000 cal/day, 3 meals)

```bash
curl -X POST http://windmill/api/flows/f/tandoor/meal_planner_weekly_by_calories/execute \
  -d '{
    "cooking_dates": [
      "2025-01-15", "2025-01-16", "2025-01-17",
      "2025-01-18", "2025-01-19", "2025-01-20", "2025-01-21"
    ],
    "weekly_calories": 42000,
    "meals_per_day": 3,
    "min_calories": 500,
    "max_calories": 900
  }'
```

Results:
- Daily target: 6000 cal (42000/7)
- Per meal: 2000 cal (6000/3)
- Actual constraints: 500-900 cal per meal
- 21 meals total (3/day × 7 days)
- Shopping list for ~50+ ingredients

### Example 2: Quick Healthy Dinner Selection

```bash
curl -X POST http://windmill/api/flows/f/tandoor/smart_recipe_selector/execute \
  -d '{
    "keyword": "quick healthy",
    "target_calories": 600,
    "min_calories": 500,
    "max_calories": 700,
    "count": 5
  }'
```

Results:
- 5 recipes matching "quick" + "healthy"
- Between 500-700 calories each
- Full recipe details (prep time, ingredients, nutrition)

### Example 3: Batch Plan with Favorite Recipes

```bash
curl -X POST http://windmill/api/flows/f/tandoor/batch_meal_planning/execute \
  -d '{
    "recipe_ids": [42, 17, 89, 33, 105],
    "cooking_dates": ["2025-01-20", "2025-01-21", "2025-01-22"],
    "cooking_pattern": "cycle",
    "servings": 2
  }'
```

Results:
- Recipe 42, 17, 89, 33, 105 on days 1-5
- Recipes 42, 17 on days 6-7 (cycling)
- Each with 2 servings
- Complete shopping list

---

## Comparison Matrix

| Feature | By Calories | Weekly | Smart Select | Batch |
|---------|-------------|--------|--------------|-------|
| **Input Type** | Daily cal + dates | Weekly budget + dates | Keywords + ranges | Recipe IDs + dates |
| **Auto-calc** | Per day | Per day/meal | None | None |
| **Keyword Filter** | ❌ | ❌ | ✅ | ❌ |
| **Calorie Control** | Per meal | Per meal | Per recipe | None |
| **Batch Size** | Single week | Any length | 1-20 recipes | Any length |
| **Best For** | Specific daily targets | Weekly planning | Recipe discovery | Favorite recipes |
| **Complexity** | Medium | High | Medium | Low |

---

## Troubleshooting

### "Insufficient matching recipes"

**Cause:** No recipes fall within the min/max calorie range.

**Solutions:**
- Widen the min/max range
- Check if recipes have calorie data (run `add_calories_to_recipes` flow first)
- Try different keywords

### "Fewer recipes selected than requested"

**Cause:** Not enough recipes match all filters.

**Solution:**
- Reduce `count` parameter
- Widen calorie range
- Remove keyword filter

### Shopping list empty

**Cause:** Meal plans were created but not added to shopping list.

**Solution:**
- Verify Tandoor API connection
- Check that recipes exist in Tandoor
- Run flow with `skip_failures: false` (default) to catch errors

---

## Future Enhancements

Potential improvements for next iterations:

1. **Budget Constraints:** Add cost optimization alongside calories
2. **Nutrient Tracking:** Track macros (protein, carbs, fat) not just calories
3. **Dietary Restrictions:** Add filters for allergies, vegetarian, etc.
4. **Prep Time Optimization:** Prefer recipes with shorter prep times
5. **Shopping List Export:** Export to common grocery app formats
6. **Meal Plan Visualization:** Calendar view of planned meals
7. **Nutrition Timeline:** Show nutrition by day/week/month
8. **Recipe Substitutions:** Auto-suggest alternatives based on calories

---

## References

- Binary: `tandoor_recipe_select_by_calories` - `/src/bin/tandoor_recipe_select_by_calories.rs`
- Binary: `tandoor_recipe_list_flat` - `/src/bin/tandoor_recipe_list_flat.rs`
- Module: `tandoor::recipe_selection` - `/src/tandoor/recipe_selection.rs`
- Existing flow: `weekly_grocery_list_builder` - Pattern reference
- Existing flow: `weekly_meal_plan` - Pattern reference
