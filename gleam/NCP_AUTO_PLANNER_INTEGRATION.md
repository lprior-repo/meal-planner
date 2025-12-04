# NCP Auto Planner Integration

## Overview

This integration connects the NCP (Nutrition Control Plane) system with the auto meal planner to provide intelligent recipe suggestions based on macro deficits.

## Flow

```
User checks NCP status → Shows deficit (e.g., -30g protein)
  ↓
System triggers auto planner
  ↓
Auto planner queries recipes with high protein
  ↓
Scores recipes for macro match + diet compliance
  ↓
Returns top 3-5 suggestions to user
```

## Architecture

### Core Module: `meal_planner/ncp_auto_planner.gleam`

#### Main Function

```gleam
suggest_recipes_for_deficit(
  conn: pog.Connection,
  goals: ncp.NutritionGoals,
  actual: ncp.NutritionData,
  config: SuggestionConfig,
) -> Result(SuggestionResult, StorageError)
```

**Steps:**
1. Calculate deviation from goals using NCP
2. If within tolerance (default ±10%), return empty suggestions
3. Query recipes that address the deficit
4. Score recipes for:
   - **Macro match** (50%): How well recipe fills deficit
   - **Diet compliance** (30%): Recipe compliance with diet principles
   - **Variety** (20%): Ingredient diversity
5. Filter by minimum compliance score
6. Return top N suggestions (default: 5)

#### Query Strategy

The integration intelligently queries recipes based on deficit type:

```gleam
// High protein deficit (< -15%)
query_high_protein_recipes(conn, 30.0)  // min 30g protein

// High carb deficit (< -15%)
query_high_carb_recipes(conn, 40.0)  // min 40g carbs

// Fat deficit
query_high_fat_recipes(conn, 20.0)  // min 20g fat

// Multiple deficits
query_balanced_recipes(conn)  // min 20g protein, 10g fat, 20g carbs

// Moderate deficits
// Adjusts thresholds based on deficit severity
```

#### Scoring Algorithm

**Macro Match Score (0-1)**
- Uses `ncp.score_recipe_for_deviation()`
- Prioritizes protein (weight: 0.5)
- Then fat (weight: 0.25) and carbs (weight: 0.25)
- Penalizes recipes when user is over on macros

**Diet Compliance Score (0-1)**
- Uses `diet_validator.validate_recipe()`
- Checks against Vertical Diet, Tim Ferriss, Keto, etc.
- Returns 1.0 for compliant, <1.0 for violations

**Variety Score (0-1)**
- Uses `recipe_scorer.score_variety()`
- Based on number of unique ingredients
- 5+ ingredients = 1.0 score

**Total Score**
```gleam
total_score =
  (0.5 * macro_match_score) +
  (0.3 * compliance_score) +
  (0.2 * variety_score)
```

### Configuration Presets

```gleam
// Default: Flexible, no diet restrictions
default_config()
  max_suggestions: 5
  diet_principles: []
  min_compliance_score: 0.5
  variety_weight: 0.2

// Vertical Diet: Strict compliance
vertical_diet_config()
  max_suggestions: 5
  diet_principles: [VerticalDiet]
  min_compliance_score: 0.7
  variety_weight: 0.2

// Tim Ferriss: High protein focus
tim_ferriss_config()
  max_suggestions: 5
  diet_principles: [TimFerriss]
  min_compliance_score: 0.7
  variety_weight: 0.2

// High Protein: Performance focused
high_protein_config()
  max_suggestions: 5
  diet_principles: [HighProtein]
  min_compliance_score: 0.6
  variety_weight: 0.1  // Less variety, more protein
```

## Usage Examples

### Example 1: Basic Usage

```gleam
import meal_planner/ncp
import meal_planner/ncp_auto_planner

// User's goals
let goals = ncp.NutritionGoals(
  daily_protein: 180.0,
  daily_fat: 60.0,
  daily_carbs: 250.0,
  daily_calories: 2500.0,
)

// Current consumption
let actual = ncp.NutritionData(
  protein: 120.0,   // -33% deficit!
  fat: 58.0,
  carbs: 245.0,
  calories: 2100.0,
)

// Get suggestions with default config
use result <- result.try(
  ncp_auto_planner.suggest_recipes_for_deficit(
    conn,
    goals,
    actual,
    ncp_auto_planner.default_config(),
  )
)

// Format and display
let output = ncp_auto_planner.format_suggestion_result(result)
io.println(output)
```

**Output:**
```
📊 Macro Deficit Detected
───────────────────────────────────────────────
  Protein: -33.3%
  Fat: -3.3%
  Carbs: -2.0%

🍽️  Recommended Recipes
───────────────────────────────────────────────
1. Grilled Chicken Breast
   Match: ██████████ (95%)
   Why: High protein (45g) to address deficit
   Macros: P45g F12g C8g

2. Beef and Rice Bowl
   Match: █████████░ (88%)
   Why: High protein (38g) to address deficit
   Macros: P38g F15g C55g

3. Egg White Scramble
   Match: ████████░░ (82%)
   Why: High protein (32g) to address deficit
   Macros: P32g F8g C5g
```

### Example 2: With Diet Compliance

```gleam
// Get suggestions that comply with Vertical Diet
let config = ncp_auto_planner.vertical_diet_config()

use result <- result.try(
  ncp_auto_planner.suggest_recipes_for_deficit(
    conn,
    goals,
    actual,
    config,
  )
)
```

This will:
- Only suggest recipes with low FODMAP ingredients
- Exclude seed oils
- Prefer beef, chicken, eggs, white rice, sweet potatoes
- Filter out recipes with compliance score < 0.7

### Example 3: Generate Full Meal Plan

```gleam
// Generate a complete meal plan to meet goals
use plan <- result.try(
  ncp_auto_planner.generate_meal_plan_for_deficit(
    conn,
    goals,
    actual,
    ncp_auto_planner.high_protein_config(),
    max_recipes: 4,  // Up to 4 meals
  )
)

// Plan contains optimized recipe selection
plan.recipes          // List of 4 recipes
plan.total_macros     // Sum of all recipe macros
plan.generated_at     // Timestamp
```

The iterative algorithm:
1. Selects highest-scoring recipe
2. Updates deficit with recipe macros
3. Re-scores remaining recipes
4. Repeats until deficit resolved or max recipes reached

## Integration Points

### NCP Module (`meal_planner/ncp.gleam`)

**Used by Auto Planner:**
- `calculate_deviation()` - Compute macro deficit
- `deviation_is_within_tolerance()` - Check if suggestions needed
- `score_recipe_for_deviation()` - Score recipe for macro match
- `generate_reason()` - Human-readable explanation

### Recipe Scorer (`meal_planner/auto_planner/recipe_scorer.gleam`)

**Used by Auto Planner:**
- `score_variety()` - Ingredient diversity score
- `score_macro_match()` - Alternative macro scoring (not used in favor of NCP's)

### Diet Validator (`meal_planner/diet_validator.gleam`)

**Used by Auto Planner:**
- `validate_recipe()` - Check diet compliance
- Diet principles: VerticalDiet, TimFerriss, Keto, Paleo, etc.

### Storage (`meal_planner/storage.gleam`)

**Used by Auto Planner:**
- `search_recipes()` - Query recipes by macro thresholds
- Supports filtering by min protein, fat, carbs

## Testing

### Test Coverage

**File:** `test/meal_planner/ncp_auto_planner_test.gleam`

**Test Categories:**
1. **Configuration Tests** (4 tests)
   - Default, Vertical Diet, Tim Ferriss, High Protein configs

2. **Deficit Detection Tests** (6 tests)
   - Protein, carb, fat deficits
   - Within/outside tolerance

3. **Recipe Scoring Tests** (6 tests)
   - High/low protein for deficit
   - Balanced recipes for multiple deficits
   - Scoring when within tolerance
   - Scoring when over on all macros

4. **Diet Compliance Tests** (3 tests)
   - Vertical Diet compliance
   - Tim Ferriss compliance/violations

5. **Format Tests** (3 tests)
   - Within tolerance output
   - Deficit with suggestions
   - Deficit without suggestions

6. **Integration Flow Tests** (3 tests)
   - Complete flow with protein deficit
   - Complete flow within tolerance
   - Complete flow with multiple deficits

7. **Edge Case Tests** (5 tests)
   - Empty recipe list
   - Single recipe
   - Suggestion limit enforcement
   - Zero macro recipes

**Total: 30 comprehensive tests**

### Running Tests

```bash
# Run all tests
gleam test

# Run specific test file
gleam test --target erlang -- test/meal_planner/ncp_auto_planner_test.gleam
```

## Web Endpoint (Future)

**Planned endpoint:** `/api/ncp/suggestions`

```json
POST /api/ncp/suggestions
{
  "goals": {
    "daily_protein": 180,
    "daily_fat": 60,
    "daily_carbs": 250,
    "daily_calories": 2500
  },
  "actual": {
    "protein": 120,
    "fat": 58,
    "carbs": 245,
    "calories": 2100
  },
  "diet_principles": ["vertical_diet"],
  "max_suggestions": 5
}
```

**Response:**
```json
{
  "within_tolerance": false,
  "deficit": {
    "protein_pct": -33.3,
    "fat_pct": -3.3,
    "carbs_pct": -2.0,
    "calories_pct": -16.0
  },
  "suggestions": [
    {
      "recipe": {
        "id": "recipe-123",
        "name": "Grilled Chicken Breast",
        "macros": { "protein": 45, "fat": 12, "carbs": 8 }
      },
      "total_score": 0.95,
      "macro_match_score": 0.98,
      "compliance_score": 0.9,
      "reason": "High protein (45g) to address deficit"
    }
  ]
}
```

### HTMX Integration

```html
<!-- Trigger auto suggestions on NCP status page -->
<button
  hx-post="/api/ncp/suggestions"
  hx-target="#recipe-suggestions"
  hx-swap="innerHTML"
  hx-trigger="click"
  hx-vals='{"diet_principles": ["vertical_diet"]}'>
  Get Recipe Suggestions
</button>

<div id="recipe-suggestions">
  <!-- Suggestions will be inserted here -->
</div>
```

**Server renders:**
```gleam
pub fn render_suggestions(suggestions: List(RecipeSuggestion)) -> String {
  html.div([], [
    html.h3([], [html.text("Recommended Recipes")]),
    html.div([attribute.class("recipe-list")],
      list.map(suggestions, render_suggestion_card)
    )
  ])
}
```

## Performance Considerations

### Query Optimization

**Recipe queries are optimized with indexes:**
- `CREATE INDEX idx_recipes_protein ON recipes(protein DESC)`
- `CREATE INDEX idx_recipes_fat ON recipes(fat DESC)`
- `CREATE INDEX idx_recipes_carbs ON recipes(carbs DESC)`

**Query limits:**
- Default: 50 recipes per query
- Scored in memory (fast for 50 recipes)
- Top N selected (default: 5)

### Scoring Performance

**Fast path for common cases:**
- Within tolerance: No queries, immediate return
- Single deficit: One targeted query
- Multiple deficits: Balanced query with multiple filters

**Complexity:**
- Query: O(log n) with indexes
- Scoring: O(m) where m = recipes returned (max 50)
- Sorting: O(m log m)
- Total: ~O(log n + m log m) ≈ O(50 * log 50) = ~280 operations

## Future Enhancements

### 1. Meal Timing Optimization
```gleam
pub type MealTiming {
  Breakfast
  PreWorkout
  PostWorkout
  Lunch
  Dinner
}

// Suggest recipes based on time of day
suggest_for_meal_time(
  conn,
  deficit,
  timing: PostWorkout,  // Prioritize fast carbs + protein
  config,
)
```

### 2. Ingredient Availability
```gleam
// Filter by ingredients user has in stock
suggest_with_ingredients(
  conn,
  deficit,
  available_ingredients: ["chicken", "rice", "eggs"],
  config,
)
```

### 3. Prep Time Consideration
```gleam
pub type SuggestionConfig {
  // ... existing fields ...
  max_prep_time_minutes: Option(Int),  // Filter by prep time
  prefer_meal_prep: Bool,               // Prefer recipes good for meal prep
}
```

### 4. Historical Preferences
```gleam
// Learn from user's past recipe selections
suggest_with_preferences(
  conn,
  deficit,
  user_history: List(RecipeInteraction),  // Liked, disliked, logged
  config,
)
```

### 5. Budget Optimization
```gleam
// Consider ingredient costs
suggest_budget_friendly(
  conn,
  deficit,
  max_cost_per_serving: 5.0,  // Max $5 per serving
  config,
)
```

## Troubleshooting

### No Suggestions Returned

**Causes:**
1. All recipes filtered out by diet compliance
2. No recipes in database match deficit
3. Min compliance score too high

**Solutions:**
- Lower `min_compliance_score` to 0.3-0.5
- Add more recipes to database
- Use `default_config()` instead of strict diet configs
- Check if within tolerance (no suggestions needed)

### Low-Quality Suggestions

**Causes:**
1. Variety weight too high
2. Compliance weight too low
3. Database has limited recipe variety

**Solutions:**
- Adjust weights in `SuggestionConfig`
- Use preset configs (vertical_diet_config, etc.)
- Add more diverse recipes to database

### Performance Issues

**Causes:**
1. Large recipe database without indexes
2. Querying too many recipes

**Solutions:**
- Create indexes on protein, fat, carbs columns
- Reduce query limit from 50 to 20
- Cache suggestions for same deficit

## Related Documentation

- [NCP Module](./src/meal_planner/ncp.gleam) - Nutrition Control Plane
- [Recipe Scorer](./src/meal_planner/auto_planner/recipe_scorer.gleam) - Recipe scoring algorithms
- [Diet Validator](./src/meal_planner/diet_validator.gleam) - Diet compliance checking
- [HTMX Usage](./HTMX_USAGE.md) - Frontend integration patterns

## Contributing

When adding new features to the NCP auto planner:

1. **Write tests first** - Follow TDD approach
2. **Document scoring changes** - Explain weight adjustments
3. **Consider performance** - Profile with large recipe sets
4. **Maintain compatibility** - Don't break existing configs
5. **NO .js files** - Use HTMX for all interactivity

## License

Part of the meal-planner project.
