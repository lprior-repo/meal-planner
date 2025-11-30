# Go to Gleam Port Status

**Generated:** 2025-11-29

## Summary

Core domain types and business logic have been ported to Gleam. The Go code still provides the main application entry point, database layer, and CLI orchestration.

## Types - FULLY PORTED ✅

| Go Type | Gleam Type | Module |
|---------|------------|--------|
| `Ingredient` | `Ingredient` | types.gleam |
| `Recipe` | `Recipe` | types.gleam |
| `Macros` | `Macros` | types.gleam |
| `UserProfile` | `UserProfile` | types.gleam |
| `FodmapLevel` | `FodmapLevel` | types.gleam |
| `ActivityLevel` | `ActivityLevel` | types.gleam |
| `Goal` | `Goal` | types.gleam |
| `Meal` | `Meal` | meal_plan.gleam |
| `DailyPlan` | `DailyPlan` | meal_plan.gleam |
| `WeeklyMealPlan` | `WeeklyMealPlan` | meal_plan.gleam |
| `NutritionGoals` | `NutritionGoals` | ncp.gleam |
| `NutritionData` | `NutritionData` | ncp.gleam |
| `DeviationResult` | `DeviationResult` | ncp.gleam |
| `EmailPayload` | `EmailPayload` | email.gleam |
| `MealCategory` | `MealCategory` | meal_selection.gleam |
| `MealSelectionConfig` | `MealSelectionConfig` | meal_selection.gleam |
| `MealSelectionResult` | `MealSelectionResult` | meal_selection.gleam |
| `PortionCalculation` | `PortionCalculation` | portion.gleam |
| `FODMAPAnalysis` | `FODMAPAnalysis` | fodmap.gleam |
| `Unit` | `Unit` | quantity.gleam |
| `ParsedQuantity` | `ParsedQuantity` | quantity.gleam |

## Functions - FULLY PORTED ✅

### Macro Calculations
- `Macros.Calories()` → `macros_calories()`
- `Recipe.TotalMacros()` → `total_macros()`
- `Recipe.IsVerticalDietCompliant()` → `is_vertical_diet_compliant()`

### User Profile
- `DailyProteinTarget()` → `daily_protein_target()`
- `DailyFatTarget()` → `daily_fat_target()`
- `DailyCarbTarget()` → `daily_carb_target()`
- `DailyCalorieTarget()` → `daily_calorie_target()`

### NCP
- `CalculateDeviation()` → `calculate_deviation()`
- `DeviationResult.IsWithinTolerance()` → `deviation_is_within_tolerance()`

### Meal Selection
- `GetMealCategory()` → `get_meal_category()`
- `SelectMealsForWeek()` → `select_meals_for_week()`
- `IsWithinTargets()` → `is_within_targets()`

### Portion Calculation
- `CalculatePortionForTarget()` → `calculate_portion_for_target()`
- `CalculateDailyPortions()` → `calculate_daily_portions()`

### FODMAP Analysis
- `AnalyzeRecipeFODMAP()` → `analyze_recipe_fodmap()`
- `isLowFODMAPException()` → `is_low_fodmap_exception()`

## Go Code NOT Yet Ported ❌

### Database Layer (badger_db.go, database.go)
- `InitBadgerDatabase()` - BadgerDB initialization
- `BadgerDatabase.GetAllRecipes()` - Recipe retrieval
- Recipe storage (Gleam uses SQLite for NCP only)

### Application Init & CLI (init.go, main.go)
- `InitializeApp()` - Startup orchestration
- `main()` - Entry point
- `askAppMode()` - Mode selection
- `CollectUserProfile()` - Interactive input

### Output Formatting (main.go)
- `PrintWeeklyPlan()` - Weekly plan display
- `PrintCategorizedShoppingList()` - Shopping list
- `FormatWeeklyPlanEmail()` - Email formatting
- `PrintAuditReport()` - FODMAP audit

### Shopping List (main.go)
- `GenerateShoppingList()` - List generation
- `CategorizeIngredient()` - Categorization
- `OrganizeShoppingList()` - Organization

### Weekly Plan Generation (main.go)
- `GenerateWeeklyPlan()` - Full plan generation
- `GenerateMealTimings()` - Meal scheduling

### Strict Validation (main.go)
- `ValidateRecipeStrict()` - Seed oil/grain validation
- `ValidateWeeklyPlanStrict()` - Plan validation

### Complete NCP Package (ncp/*.go)
- 18 Go files with full NCP implementation
- Gleam has basic types and storage only

## Archival Recommendation

**NO GO FILES SHOULD BE ARCHIVED YET**

The Go code still provides:
1. Main application entry point
2. BadgerDB recipe storage
3. CLI orchestration
4. Complete NCP implementation
5. Output formatting
6. Plan generation

## Port Completion

| Category | Status |
|----------|--------|
| Core Types | ✅ 100% |
| Business Logic | ✅ 100% |
| Email | ✅ 100% |
| Environment | ✅ 100% |
| Recipe Loading | ✅ 100% |
| NCP Types | ✅ 100% |
| NCP Logic | ⚠️ 20% |
| Recipe Storage | ❌ 0% |
| CLI/Interactive | ❌ 0% |
| Output Formatting | ❌ 0% |
| Plan Generation | ❌ 0% |
