# Auto Meal Planner - Component Interaction Diagram

## High-Level Data Flow

```
┌───────────────────────────────────────────────────────────────────────┐
│                         USER REQUEST                                   │
│  {                                                                     │
│    user_id: "user123",                                                 │
│    diet_principles: ["vertical_diet"],                                 │
│    macro_targets: {protein: 180, fat: 60, carbs: 250}                 │
│  }                                                                     │
└─────────────────────────────┬─────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────────┐
│                    API Handler (web.gleam)                             │
│  generate_meal_plan_handler()                                          │
│    • Parse JSON request                                                │
│    • Validate user_id exists                                           │
│    • Decode diet principles                                            │
│    • Call auto_planner.generate_plan()                                 │
└─────────────────────────────┬─────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────────┐
│             Auto Planner Orchestrator (auto_planner.gleam)             │
│  generate_plan(config, recipes, goals)                                 │
│    ┌──────────────────────────────────────────────────────────────┐   │
│    │ Step 1: Fetch Available Recipes                             │   │
│    │   auto_planner_storage.get_recipes_for_user()               │   │
│    └──────────────┬───────────────────────────────────────────────┘   │
│                   │                                                    │
│    ┌──────────────▼───────────────────────────────────────────────┐   │
│    │ Step 2: Filter by Diet Compliance                           │   │
│    │   For each recipe:                                           │   │
│    │     diet_validator.validate_recipe(recipe, diets)           │   │
│    │   Keep only compliant recipes                               │   │
│    └──────────────┬───────────────────────────────────────────────┘   │
│                   │                                                    │
│    ┌──────────────▼───────────────────────────────────────────────┐   │
│    │ Step 3: Get User's Nutrition Goals                          │   │
│    │   ncp.get_goals(user_id) -> NutritionGoals                  │   │
│    │   Calculate current deviation                                │   │
│    └──────────────┬───────────────────────────────────────────────┘   │
│                   │                                                    │
│    ┌──────────────▼───────────────────────────────────────────────┐   │
│    │ Step 4: Score Each Recipe                                   │   │
│    │   For each recipe:                                           │   │
│    │     score_recipe(recipe, goals, diets, variety_context)     │   │
│    │   Returns: List(#(Recipe, Float))                           │   │
│    └──────────────┬───────────────────────────────────────────────┘   │
│                   │                                                    │
│    ┌──────────────▼───────────────────────────────────────────────┐   │
│    │ Step 5: Select Top 4 with Variety                           │   │
│    │   Sort by score (descending)                                │   │
│    │   Apply variety filter:                                     │   │
│    │     • Penalize duplicate protein sources                    │   │
│    │     • Re-sort with variety scores                           │   │
│    │   Take top 4                                                │   │
│    └──────────────┬───────────────────────────────────────────────┘   │
│                   │                                                    │
│    ┌──────────────▼───────────────────────────────────────────────┐   │
│    │ Step 6: Validate Total Macros                               │   │
│    │   Sum macros from selected recipes                          │   │
│    │   Check against targets (+/- 10% tolerance)                 │   │
│    └──────────────┬───────────────────────────────────────────────┘   │
│                   │                                                    │
│    ┌──────────────▼───────────────────────────────────────────────┐   │
│    │ Step 7: Create AutoMealPlan                                 │   │
│    │   Build ScoredRecipe list with match_reason                 │   │
│    │   Generate plan ID                                           │   │
│    │   Set status = Active                                        │   │
│    └──────────────┬───────────────────────────────────────────────┘   │
└────────────────────┼──────────────────────────────────────────────────┘
                     │
                     ▼
┌───────────────────────────────────────────────────────────────────────┐
│              Storage Layer (auto_planner_storage.gleam)                │
│  save_meal_plan(conn, plan)                                            │
│    • Insert into auto_meal_plans table                                 │
│    • Serialize diet_principles to JSON                                 │
│    • Serialize recipe_ids to JSON                                      │
│    • Serialize macro_targets to JSON                                   │
│    • Return plan_id                                                    │
└─────────────────────────────┬─────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────────┐
│                      DATABASE (SQLite/PostgreSQL)                      │
│  Tables:                                                               │
│    • auto_meal_plans          [id, user_id, recipe_ids, ...]         │
│    • recipe_diet_compliance   [recipe_id, vertical_compliant, ...]   │
│    • recipes                  [id, name, macros, ...]                │
│    • nutrition_state          [date, protein, fat, carbs, ...]       │
└─────────────────────────────┬─────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────────┐
│                       JSON RESPONSE                                    │
│  {                                                                     │
│    "id": "plan_abc123",                                                │
│    "recipes": [                                                        │
│      {                                                                 │
│        "recipe": {...},                                                │
│        "score": 0.95,                                                  │
│        "match_reason": "High protein, vertical diet compliant"         │
│      }                                                                 │
│    ],                                                                  │
│    "total_macros": {...}                                               │
│  }                                                                     │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Module Interaction Details

### 1. Scoring Algorithm Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│  score_recipe(recipe, goals, diets, variety_context) -> Float       │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ MACRO MATCH SCORE (Weight: 0.40)                            │  │
│  │ ───────────────────────────────────────────────────────────  │  │
│  │  1. Convert recipe.macros to NutritionData                   │  │
│  │  2. ncp.calculate_deviation(goals, recipe_data)             │  │
│  │  3. Calculate match percentage for each macro:               │  │
│  │     • protein_match = 1.0 - |dev.protein| / 100             │  │
│  │     • fat_match = 1.0 - |dev.fat| / 100                     │  │
│  │     • carb_match = 1.0 - |dev.carbs| / 100                  │  │
│  │  4. Average: (protein + fat + carb) / 3                     │  │
│  │                                                               │  │
│  │  Result: 0.0 - 1.0 ──────────────────────────▶ * 0.40       │  │
│  └──────────────────────────────────────────────┬────────────────┘  │
│                                                  │                   │
│  ┌──────────────────────────────────────────────▼────────────────┐  │
│  │ DIET COMPLIANCE SCORE (Weight: 0.30)                        │  │
│  │ ───────────────────────────────────────────────────────────  │  │
│  │  For each diet in diets:                                     │  │
│  │    validation = diet_validator.validate_recipe(recipe, diet) │  │
│  │    if validation.compliant -> +1                             │  │
│  │                                                               │  │
│  │  compliance_score = compliant_count / total_diets            │  │
│  │                                                               │  │
│  │  Result: 0.0 - 1.0 ──────────────────────────▶ * 0.30       │  │
│  └──────────────────────────────────────────────┬────────────────┘  │
│                                                  │                   │
│  ┌──────────────────────────────────────────────▼────────────────┐  │
│  │ PROTEIN QUALITY SCORE (Weight: 0.20)                        │  │
│  │ ───────────────────────────────────────────────────────────  │  │
│  │  1. Identify primary protein source from ingredients         │  │
│  │  2. Assign quality score:                                    │  │
│  │     • Beef/Salmon: 1.0                                       │  │
│  │     • Chicken/Turkey: 0.8                                    │  │
│  │     • Eggs/Greek Yogurt: 0.6                                 │  │
│  │     • Plant protein: 0.4                                     │  │
│  │  3. Scale by protein amount:                                 │  │
│  │     quality * min(recipe.protein / 40.0, 1.0)               │  │
│  │                                                               │  │
│  │  Result: 0.0 - 1.0 ──────────────────────────▶ * 0.20       │  │
│  └──────────────────────────────────────────────┬────────────────┘  │
│                                                  │                   │
│  ┌──────────────────────────────────────────────▼────────────────┐  │
│  │ VARIETY SCORE (Weight: 0.10)                                │  │
│  │ ───────────────────────────────────────────────────────────  │  │
│  │  Check if recipe.primary_protein in variety_context:         │  │
│  │    • Already selected -> 0.3 (heavy penalty)                │  │
│  │    • Not selected -> 1.0 (variety bonus)                    │  │
│  │                                                               │  │
│  │  Result: 0.3 or 1.0 ─────────────────────────▶ * 0.10       │  │
│  └──────────────────────────────────────────────┬────────────────┘  │
│                                                  │                   │
│  ┌──────────────────────────────────────────────▼────────────────┐  │
│  │ FINAL SCORE                                                  │  │
│  │ ───────────────────────────────────────────────────────────  │  │
│  │  final = (macro * 0.40) + (diet * 0.30) +                   │  │
│  │          (protein * 0.20) + (variety * 0.10)                │  │
│  │                                                               │  │
│  │  clamp(final, 0.0, 1.0)                                      │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

### 2. Diet Validation Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│  validate_recipe(recipe, diet) -> ValidationResult                   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Step 1: Check Cache                                          │  │
│  │   auto_planner_storage.get_compliance(recipe.id)             │  │
│  │                                                               │  │
│  │   IF cache exists AND age < 7 days:                          │  │
│  │     RETURN cached result                                      │  │
│  │   ELSE:                                                       │  │
│  │     Continue to validation                                    │  │
│  └──────────────┬────────────────────────────────────────────────┘  │
│                 │                                                    │
│  ┌──────────────▼────────────────────────────────────────────────┐  │
│  │ Step 2: Validate Based on Diet Type                          │  │
│  │                                                               │  │
│  │ ┌─────────────────────────────────────────────────────────┐ │  │
│  │ │ IF diet == VerticalDiet:                                │ │  │
│  │ │   • Check recipe.vertical_compliant == True             │ │  │
│  │ │   • Check recipe.fodmap_level == Low                    │ │  │
│  │ │   • Check protein source in approved list               │ │  │
│  │ │   • Check carb sources (rice, sweet potato, oats)       │ │  │
│  │ │   • Violations list: reasons for non-compliance         │ │  │
│  │ └─────────────────────────────────────────────────────────┘ │  │
│  │                                                               │  │
│  │ ┌─────────────────────────────────────────────────────────┐ │  │
│  │ │ IF diet == TimFerriss:                                  │ │  │
│  │ │   • Check protein >= 20g per serving                    │ │  │
│  │ │   • Check carbs < 30g OR from beans/legumes             │ │  │
│  │ │   • Check fat < 15g per serving                         │ │  │
│  │ │   • Check NO white carbs (bread, pasta, white rice)     │ │  │
│  │ │   • Violations list: reasons for non-compliance         │ │  │
│  │ └─────────────────────────────────────────────────────────┘ │  │
│  │                                                               │  │
│  │ ┌─────────────────────────────────────────────────────────┐ │  │
│  │ │ IF diet == LowFodmap:                                   │ │  │
│  │ │   • Check recipe.fodmap_level == Low                    │ │  │
│  │ │   • Violations: if Medium or High                       │ │  │
│  │ └─────────────────────────────────────────────────────────┘ │  │
│  └──────────────┬────────────────────────────────────────────────┘  │
│                 │                                                    │
│  ┌──────────────▼────────────────────────────────────────────────┐  │
│  │ Step 3: Build ValidationResult                               │  │
│  │   compliant = (violations.length == 0)                       │  │
│  │   confidence = 1.0 (manual validation) or                    │  │
│  │                0.8 (heuristic validation)                     │  │
│  └──────────────┬────────────────────────────────────────────────┘  │
│                 │                                                    │
│  ┌──────────────▼────────────────────────────────────────────────┐  │
│  │ Step 4: Cache Result                                         │  │
│  │   auto_planner_storage.save_compliance(recipe.id, result)    │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

### 3. Recipe Selection with Variety

```
┌─────────────────────────────────────────────────────────────────────┐
│  select_recipes(scored_list, count: 4, variety: 0.10) -> List       │
│                                                                      │
│  Input: [(Recipe, Score), ...]                                      │
│         e.g., [(salmon, 0.95), (beef, 0.90), (chicken, 0.85), ...]  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Step 1: Initial Sort by Score                                │  │
│  │   Sort descending: highest score first                        │  │
│  │                                                               │  │
│  │   Result:                                                     │  │
│  │   1. Grilled Salmon (0.95) - protein: salmon                 │  │
│  │   2. Ribeye Steak (0.90) - protein: beef                     │  │
│  │   3. Baked Chicken (0.85) - protein: chicken                 │  │
│  │   4. Salmon Patties (0.83) - protein: salmon ⚠️              │  │
│  │   5. Ground Beef Bowl (0.80) - protein: beef ⚠️              │  │
│  └──────────────┬────────────────────────────────────────────────┘  │
│                 │                                                    │
│  ┌──────────────▼────────────────────────────────────────────────┐  │
│  │ Step 2: Apply Variety Penalty                                │  │
│  │   selected = []                                               │  │
│  │   selected_proteins = []                                      │  │
│  │                                                               │  │
│  │   For each recipe in sorted list:                            │  │
│  │     IF recipe.protein NOT IN selected_proteins:               │  │
│  │       add to selected                                         │  │
│  │       add protein to selected_proteins                        │  │
│  │     ELSE:                                                     │  │
│  │       penalty = recipe.score * 0.7  // Heavy penalty         │  │
│  │       IF penalty > lowest_selected_score:                     │  │
│  │         replace lowest with this recipe                       │  │
│  │                                                               │  │
│  │   Result after variety filtering:                             │  │
│  │   1. Grilled Salmon (0.95) - salmon ✓                        │  │
│  │   2. Ribeye Steak (0.90) - beef ✓                            │  │
│  │   3. Baked Chicken (0.85) - chicken ✓                        │  │
│  │   4. Pork Chops (0.78) - pork ✓ (4th unique protein)         │  │
│  │                                                               │  │
│  │   Skipped:                                                    │  │
│  │   • Salmon Patties (0.83) - duplicate salmon                 │  │
│  │   • Ground Beef Bowl (0.80) - duplicate beef                 │  │
│  └──────────────┬────────────────────────────────────────────────┘  │
│                 │                                                    │
│  ┌──────────────▼────────────────────────────────────────────────┐  │
│  │ Step 3: Build ScoredRecipe List                              │  │
│  │   For each selected recipe:                                   │  │
│  │     • Calculate macro_contribution (per serving)              │  │
│  │     • Generate match_reason from scoring components           │  │
│  │     • Create ScoredRecipe object                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Database Query Flow

### Generate Meal Plan - Database Interactions

```
┌─────────────────────────────────────────────────────────────────────┐
│  Database Queries During generate_plan()                             │
│                                                                      │
│  Query 1: Get User's Nutrition Goals                                │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ SELECT daily_protein, daily_fat, daily_carbs, daily_calories │  │
│  │ FROM nutrition_goals WHERE user_id = ?                       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Query 2: Get Available Recipes                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ SELECT r.id, r.name, r.protein, r.fat, r.carbs,             │  │
│  │        r.servings, r.category, r.fodmap_level,               │  │
│  │        r.vertical_compliant                                   │  │
│  │ FROM recipes r                                                │  │
│  │ WHERE r.enabled = 1                                          │  │
│  │ LIMIT 500                                                     │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Query 3: Get Cached Diet Compliance (for each recipe)              │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ SELECT recipe_id, vertical_diet_compliant,                   │  │
│  │        tim_ferriss_compliant, last_checked                   │  │
│  │ FROM recipe_diet_compliance                                  │  │
│  │ WHERE recipe_id IN (?, ?, ?, ...)                            │  │
│  │   AND last_checked > date('now', '-7 days')                  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Query 4: Insert Generated Meal Plan                                │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ INSERT INTO auto_meal_plans                                  │  │
│  │   (user_id, diet_principles, recipe_ids,                     │  │
│  │    macro_targets, status)                                    │  │
│  │ VALUES (?, ?, ?, ?, 'active')                                │  │
│  │ RETURNING id                                                 │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Query 5: Update Compliance Cache (if needed)                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ INSERT INTO recipe_diet_compliance                           │  │
│  │   (recipe_id, vertical_diet_compliant,                       │  │
│  │    tim_ferriss_compliant, compliance_notes)                  │  │
│  │ VALUES (?, ?, ?, ?)                                          │  │
│  │ ON CONFLICT(recipe_id) DO UPDATE                             │  │
│  │   SET vertical_diet_compliant = excluded.vertical_diet_compliant,│
│  │       tim_ferriss_compliant = excluded.tim_ferriss_compliant,│  │
│  │       last_checked = CURRENT_TIMESTAMP                       │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Error Handling Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│  Error Scenarios and Recovery                                        │
│                                                                      │
│  Error 1: Insufficient Recipes                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Trigger: Available recipes < 4                                │  │
│  │ Response:                                                     │  │
│  │   PlanError.InsufficientRecipes(available: 2, required: 4)   │  │
│  │ HTTP: 404 Not Found                                          │  │
│  │ Message: "Only 2 recipes available, need at least 4"         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Error 2: No Compliant Recipes                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Trigger: All recipes fail diet validation                    │  │
│  │ Response:                                                     │  │
│  │   PlanError.NoCompliantRecipes(diet: VerticalDiet)           │  │
│  │ HTTP: 404 Not Found                                          │  │
│  │ Message: "No recipes found matching Vertical Diet"           │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Error 3: Macro Targets Unreachable                                 │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Trigger: Selected recipes deviate >20% from targets          │  │
│  │ Response:                                                     │  │
│  │   PlanError.MacroTargetUnreachable(                          │  │
│  │     "Protein target 180g, closest achievable: 130g"          │  │
│  │   )                                                           │  │
│  │ HTTP: 200 OK (with warning in response)                      │  │
│  │ Message: "Plan generated with 27% protein deviation"         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Error 4: Database Error                                            │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Trigger: SQL error, connection failure                       │  │
│  │ Response:                                                     │  │
│  │   PlanError.StorageError(DatabaseError("..."))               │  │
│  │ HTTP: 500 Internal Server Error                              │  │
│  │ Message: "Database error: unable to save meal plan"          │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Performance Optimization Points

```
┌─────────────────────────────────────────────────────────────────────┐
│  Optimization Strategy                                               │
│                                                                      │
│  1. Recipe Scoring (Bottleneck: N recipes * scoring time)           │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ • Early Exit: Skip recipes with score < 0.3 threshold        │  │
│  │ • Batch Scoring: Score in parallel using list.map            │  │
│  │ • Cache NCP Calculations: Memoize deviation calculations     │  │
│  │ • Limit Input: Cap at 500 most recent recipes                │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  2. Diet Validation (Bottleneck: Database lookups)                  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ • Batch Query: Fetch compliance for all recipes at once      │  │
│  │ • Cache Duration: 7 days for validation results              │  │
│  │ • Lazy Validation: Only validate top 50 scored recipes       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  3. Database Queries (Bottleneck: Multiple round trips)             │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ • Single Transaction: Wrap entire operation in transaction   │  │
│  │ • Batch Inserts: If updating multiple compliance records     │  │
│  │ • Prepared Statements: Reuse query plans                     │  │
│  │ • Index Usage: Ensure indexes on frequently queried columns  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Expected Performance:                                               │
│  • 100 recipes: ~50ms                                                │
│  • 500 recipes: ~200ms                                               │
│  • 1000 recipes: ~500ms                                              │
└─────────────────────────────────────────────────────────────────────┘
```

---

**Document Version:** 1.0
**Created:** 2025-12-03
**Purpose:** Detailed component interaction diagrams for auto meal planner
