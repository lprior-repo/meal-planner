# Types Module

**Purpose:** Central entry point and documentation for all type definitions in the meal-planner system.

## Overview

This module organizes type definitions into focused, single-responsibility modules to reduce coupling and improve maintainability. Each sub-module handles a specific domain of types.

## Module Organization

### Core Nutrition Types
- **macros.gleam** - Macros type with calorie/ratio calculations
- **micronutrients.gleam** - Micronutrients (vitamins, minerals)
- **nutrition.gleam** - NutritionData and NutritionGoals

### Food & Recipe Types
- **food.gleam** - Food, FoodEntry, and FoodSource types
- **custom_food.gleam** - CustomFood for user-created foods
- **recipe.gleam** - Recipe and Ingredient types (legacy and meal planning)
- **food_log.gleam** - FoodLog type for tracking consumption

### Meal Planning Types
- **meal_plan.gleam** - MealPlan, DayMeals, and DailyMacros
- **grocery_item.gleam** - GroceryItem for shopping lists

### Supporting Types
- **measurements.gleam** - Measurement and Unit types
- **food_source.gleam** - FoodSourceType enumeration
- **pagination.gleam** - Pagination for API responses
- **search.gleam** - Search filter and response types
- **user_profile.gleam** - UserProfile type
- **json.gleam** - JSON encoding/decoding utilities

## Usage

Import specific type modules directly:

```gleam
import meal_planner/types/macros.{type Macros}
import meal_planner/types/food.{type Food, type FoodEntry}
import meal_planner/types/meal_plan.{type MealPlan, type DayMeals}
```

## Public API

This module serves as documentation only. All types are defined in their respective sub-modules. See individual module README files for detailed API documentation.

## Design Principles

1. **Single Responsibility** - Each module handles one domain
2. **Opaque Types** - Core types use opaque constructors for validation
3. **Immutability** - All types are immutable following Gleam conventions
4. **Exhaustive Matching** - All variants covered in case expressions
5. **Type Safety** - No dynamic types; custom types for all domains

## Related Modules

- **tandoor/client/** - Tandoor API integration (uses Recipe types)
- **fatsecret/** - FatSecret API integration (uses Food/Nutrition types)
- **storage/** - Database persistence (serializes all types)

## Refactoring Notes

This module structure is part of the AI-Friendly Codebase Refactoring (Epic MP-0vh). The goal is to keep all files under 500 lines with focused responsibilities.

**Previous State:** All types were in a single monolithic `types.gleam` file (2000+ lines)

**Current State:** Split into 16 focused modules, each under 300 lines
