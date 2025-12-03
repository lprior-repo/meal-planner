# Visual Architecture Diagrams: save_food_to_log

## 1. System Context (C4 Level 1)

```
┌─────────────────────────────────────────────────────────────┐
│                      Meal Planner System                     │
│                                                              │
│  ┌──────────────┐              ┌──────────────────────────┐ │
│  │   Web UI     │─────────────▶│  save_food_to_log()      │ │
│  │  (Wisp/Web)  │  Log food    │  Unified Food Logging    │ │
│  └──────────────┘              └──────────────────────────┘ │
│                                         │                    │
│                        ┌────────────────┼───────────────┐    │
│                        ▼                ▼               ▼    │
│                ┌───────────┐    ┌──────────┐   ┌──────────┐ │
│                │  Recipes  │    │  Custom  │   │   USDA   │ │
│                │  Storage  │    │  Foods   │   │  Foods   │ │
│                └───────────┘    └──────────┘   └──────────┘ │
│                        │                │               │    │
│                        └────────────────┴───────────────┘    │
│                                    ▼                          │
│                          ┌──────────────────┐                │
│                          │   food_logs      │                │
│                          │   (PostgreSQL)   │                │
│                          └──────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

## 2. Data Flow Architecture

```
User Action
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. API Request                                              │
│    POST /api/log/food                                        │
│    {                                                         │
│      user_id: "user-1",                                      │
│      date: "2025-12-03",                                     │
│      source: { type: "recipe", id: "chicken-rice" },        │
│      servings: 1.5,                                          │
│      meal_type: "lunch"                                      │
│    }                                                         │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Validation Layer                                         │
│    ✓ user_id not empty                                      │
│    ✓ date format YYYY-MM-DD                                 │
│    ✓ servings > 0                                           │
│    ✓ source type valid                                      │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. save_food_to_log()                                       │
│                                                              │
│    Pattern match on source:                                 │
│    ┌────────────────┬──────────────────┬─────────────────┐ │
│    │ RecipeSource   │ CustomFoodSource │ UsdaFoodSource  │ │
│    └────────┬───────┴─────────┬────────┴────────┬────────┘ │
│             ▼                 ▼                  ▼          │
│    ┌───────────────┐  ┌──────────────┐  ┌──────────────┐  │
│    │ Fetch Recipe  │  │ Fetch Custom │  │ Fetch USDA   │  │
│    │ from recipes  │  │ + Authorize  │  │ + Parse      │  │
│    └───────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│            │                  │                  │          │
│            └──────────────────┴──────────────────┘          │
│                            ▼                                 │
│              ┌──────────────────────────┐                   │
│              │ Nutrition Data           │                   │
│              │ - name: String           │                   │
│              │ - macros: Macros         │                   │
│              │ - micros: Option(Micros) │                   │
│              └──────────┬───────────────┘                   │
│                         ▼                                    │
│              ┌──────────────────────────┐                   │
│              │ Scale by servings        │                   │
│              │ macros * servings        │                   │
│              │ micros * servings        │                   │
│              └──────────┬───────────────┘                   │
└─────────────────────────┼───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Database Insert                                          │
│    INSERT INTO food_logs (                                   │
│      id, date, recipe_name, servings,                        │
│      protein, fat, carbs,                                    │
│      fiber, sugar, sodium, ... (21 micronutrients),          │
│      meal_type, logged_at,                                   │
│      source_type, source_id        ← NEW COLUMNS            │
│    )                                                         │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Response                                                 │
│    200 OK                                                    │
│    {                                                         │
│      id: "log-123",                                          │
│      recipe_name: "Chicken and Rice",                        │
│      servings: 1.5,                                          │
│      macros: { protein: 67.5, fat: 12.0, carbs: 67.5 },     │
│      micronutrients: { ... },                                │
│      meal_type: "lunch",                                     │
│      logged_at: "2025-12-03T12:30:00Z",                      │
│      source: {                                               │
│        type: "recipe",                                       │
│        id: "chicken-rice"                                    │
│      }                                                       │
│    }                                                         │
└─────────────────────────────────────────────────────────────┘
```

## 3. Type System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      FoodSource (Union Type)                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  RecipeSource(recipe_id: String)                             │
│    │                                                          │
│    ├─ to_db(): #("recipe", recipe_id)                        │
│    └─ from_db("recipe", id): Ok(RecipeSource(id))           │
│                                                              │
│  CustomFoodSource(custom_food_id: String, user_id: String)   │
│    │                                                          │
│    ├─ to_db(): #("custom_food", custom_food_id)             │
│    ├─ from_db("custom_food", id, user): Ok(CustomFood...)   │
│    └─ Authorization: Embed user_id for security check       │
│                                                              │
│  UsdaFoodSource(fdc_id: Int)                                 │
│    │                                                          │
│    ├─ to_db(): #("usda_food", int.to_string(fdc_id))        │
│    └─ from_db("usda_food", id): parse int → Ok(Usda...)     │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    FoodLogEntry (Extended)                   │
├─────────────────────────────────────────────────────────────┤
│  id: String                         (UUID)                   │
│  recipe_id: String                  (DEPRECATED)             │
│  recipe_name: String                (display name)           │
│  servings: Float                    (serving count)          │
│  macros: Macros                     (P/F/C + calories)       │
│  micronutrients: Option(Micros)     (21 vitamins/minerals)   │
│  meal_type: MealType                (Breakfast/Lunch/etc)    │
│  logged_at: String                  (ISO timestamp)          │
│  source: Option(FoodSource)         ← NEW: Source tracking   │
└─────────────────────────────────────────────────────────────┘
```

## 4. Database Schema Evolution

### Before (Migration 005):
```
food_logs
├─ id (PK)
├─ date
├─ recipe_id              ← Only recipes supported
├─ recipe_name
├─ servings
├─ protein, fat, carbs
├─ meal_type
├─ logged_at
└─ [21 micronutrient columns]
```

### After (Migration 006):
```
food_logs
├─ id (PK)
├─ date
├─ recipe_id              ← DEPRECATED (kept for backward compat)
├─ recipe_name
├─ servings
├─ protein, fat, carbs
├─ meal_type
├─ logged_at
├─ [21 micronutrient columns]
├─ source_type            ← NEW: 'recipe' | 'custom_food' | 'usda_food'
└─ source_id              ← NEW: Source-specific identifier
   │
   └─ INDEX: (source_type, source_id)
   └─ CHECK: Both NULL or both NOT NULL + type IN (...)
```

## 5. Function Call Flow (Detailed)

```
save_food_to_log(conn, user_id, date, source, servings, meal_type)
│
├─ [1] Generate UUID
│   log_id = uuid.v4()
│
├─ [2] Validate inputs
│   validate_log_input(user_id, date, servings)
│   ├─ user_id not empty? ✓
│   ├─ date format valid? ✓
│   └─ servings > 0? ✓
│
├─ [3] Pattern match source → Fetch nutrition
│   │
│   ├─ RecipeSource(recipe_id)
│   │   ├─ Query: SELECT * FROM recipes WHERE id = $1
│   │   ├─ Return: (name, macros, None)
│   │   └─ Time: ~2ms (PK lookup)
│   │
│   ├─ CustomFoodSource(food_id, expected_user)
│   │   ├─ Query: SELECT * FROM custom_foods WHERE id = $1
│   │   ├─ Authorize: food.user_id == user_id?
│   │   │   ├─ Yes → Continue
│   │   │   └─ No → Error(Unauthorized)
│   │   ├─ Return: (name, macros, Some(micros))
│   │   └─ Time: ~3ms (PK lookup + auth check)
│   │
│   └─ UsdaFoodSource(fdc_id)
│       ├─ Query 1: SELECT * FROM foods WHERE fdc_id = $1
│       ├─ Query 2: SELECT n.name, fn.amount, n.unit
│       │            FROM food_nutrients fn
│       │            JOIN nutrients n ON fn.nutrient_id = n.id
│       │            WHERE fn.fdc_id = $1
│       ├─ parse_usda_nutrients(nutrients)
│       │   ├─ Find "Protein" → macros.protein
│       │   ├─ Find "Total lipid (fat)" → macros.fat
│       │   ├─ Find "Carbohydrate..." → macros.carbs
│       │   ├─ Find "Fiber..." → micros.fiber
│       │   └─ ... 17 more micronutrients
│       ├─ Return: (name, macros, Some(micros))
│       └─ Time: ~15ms (2 queries + parsing)
│
├─ [4] Scale nutrition by servings
│   scaled_macros = macros_scale(base_macros, servings)
│   scaled_micros = option.map(micros, scale by servings)
│   Time: <1ms (in-memory math)
│
├─ [5] Extract source metadata
│   #(source_type, source_id) = food_source_to_db(source)
│
├─ [6] Insert into database
│   INSERT INTO food_logs (
│     id, date, recipe_name, servings,
│     protein, fat, carbs,
│     fiber, sugar, ... (all micronutrients),
│     meal_type, logged_at,
│     source_type, source_id
│   ) VALUES ($1, $2, ..., $30, $31)
│   Time: ~5ms
│
└─ [7] Build and return FoodLogEntry
    Time: <1ms (constructor)

Total Time: 8-25ms depending on source type
```

## 6. Authorization Flow

```
CustomFoodSource Authorization Check
│
├─ User A creates custom food
│   INSERT INTO custom_foods (id, user_id, name, ...)
│   VALUES ('food-123', 'user-A', 'My Protein Shake', ...)
│
├─ User A logs their food (AUTHORIZED ✓)
│   save_food_to_log(
│     conn, 'user-A', '2025-12-03',
│     CustomFoodSource('food-123', 'user-A'),
│     2.0, Breakfast
│   )
│   │
│   ├─ Fetch: SELECT * FROM custom_foods WHERE id = 'food-123'
│   │   Returns: { id: 'food-123', user_id: 'user-A', ... }
│   │
│   ├─ Check: 'user-A' == 'user-A'? ✓ YES
│   │
│   └─ Continue: Insert log entry
│
└─ User B tries to log User A's food (UNAUTHORIZED ✗)
    save_food_to_log(
      conn, 'user-B', '2025-12-03',
      CustomFoodSource('food-123', 'user-B'),
      1.0, Lunch
    )
    │
    ├─ Fetch: SELECT * FROM custom_foods WHERE id = 'food-123'
    │   Returns: { id: 'food-123', user_id: 'user-A', ... }
    │
    ├─ Check: 'user-B' == 'user-A'? ✗ NO
    │
    └─ Error: Unauthorized("Cannot log another user's custom food")
        ├─ HTTP 403 Forbidden
        ├─ No database insert
        └─ Log security event
```

## 7. Nutrient Parsing Flow (USDA Foods)

```
USDA Food: "Chicken, breast, grilled" (fdc_id: 171477)
│
├─ Database Query
│   SELECT n.name, fn.amount, n.unit_name
│   FROM food_nutrients fn
│   JOIN nutrients n ON fn.nutrient_id = n.id
│   WHERE fn.fdc_id = 171477
│   ORDER BY n.rank
│
├─ Returns: List(FoodNutrientValue)
│   [
│     { name: "Protein", amount: 31.0, unit: "g" },
│     { name: "Total lipid (fat)", amount: 3.6, unit: "g" },
│     { name: "Carbohydrate, by difference", amount: 0.0, unit: "g" },
│     { name: "Fiber, total dietary", amount: 0.0, unit: "g" },
│     { name: "Sugars, total", amount: 0.0, unit: "g" },
│     { name: "Calcium, Ca", amount: 15.0, unit: "mg" },
│     ... (60+ nutrients)
│   ]
│
├─ parse_usda_nutrients(nutrients)
│   │
│   ├─ Extract Macros
│   │   ├─ protein = find("Protein") = 31.0g
│   │   ├─ fat = find("Total lipid (fat)") = 3.6g
│   │   ├─ carbs = find("Carbohydrate, by difference") = 0.0g
│   │   └─ calories = find("Energy") = 165 kcal
│   │
│   ├─ Extract Micronutrients (21 fields)
│   │   ├─ fiber = find("Fiber, total dietary") = Some(0.0)
│   │   ├─ sugar = find("Sugars, total") = Some(0.0)
│   │   ├─ sodium = find("Sodium, Na") = Some(74.0)
│   │   ├─ calcium = find("Calcium, Ca") = Some(15.0)
│   │   ├─ vitamin_c = find("Vitamin C") = None (not in list)
│   │   └─ ... 16 more
│   │
│   └─ Return ParsedNutrition
│       {
│         macros: { protein: 31.0, fat: 3.6, carbs: 0.0 },
│         micronutrients: { fiber: Some(0.0), sugar: Some(0.0), ... },
│         calories: 165.0
│       }
│
└─ Scale by servings (if user logs 200g instead of 100g)
    scaled_macros = macros_scale(macros, 2.0)
    → { protein: 62.0, fat: 7.2, carbs: 0.0 }
```

## 8. Error Handling Decision Tree

```
save_food_to_log() called
│
├─ Validation Error?
│   ├─ Empty user_id → Error(InvalidInput("user_id required"))
│   ├─ Invalid date → Error(InvalidInput("Invalid date format"))
│   └─ servings ≤ 0 → Error(InvalidInput("Servings must be positive"))
│
├─ Source Fetch Error?
│   ├─ Recipe not found → Error(NotFound)
│   ├─ Custom food not found → Error(NotFound)
│   └─ USDA food not found → Error(NotFound)
│
├─ Authorization Error?
│   └─ user_id ≠ food.user_id → Error(Unauthorized("..."))
│
├─ Nutrient Parse Error?
│   └─ USDA missing required nutrients → Error(NutrientParseError("..."))
│
├─ Database Insert Error?
│   ├─ Connection lost → Error(DatabaseError("..."))
│   ├─ Constraint violation → Error(DatabaseError("..."))
│   └─ Timeout → Error(DatabaseError("..."))
│
└─ Success
    → Ok(FoodLogEntry { ... })

Error Propagation: use syntax for clean error handling
```

## 9. Performance Characteristics

```
Operation Timing Analysis (avg):
│
├─ Recipe Logging
│   ├─ Validation: 0.1ms
│   ├─ Recipe fetch (PK): 2ms
│   ├─ Scale nutrition: 0.1ms
│   ├─ Insert log: 5ms
│   └─ Total: ~7ms ✓ Excellent
│
├─ Custom Food Logging
│   ├─ Validation: 0.1ms
│   ├─ Custom food fetch (PK): 2ms
│   ├─ Authorization check: 0.1ms
│   ├─ Scale nutrition: 0.1ms
│   ├─ Insert log: 5ms
│   └─ Total: ~7ms ✓ Excellent
│
└─ USDA Food Logging
    ├─ Validation: 0.1ms
    ├─ Food metadata fetch: 3ms
    ├─ Nutrients fetch (JOIN): 8ms
    ├─ Parse nutrients: 1ms
    ├─ Scale nutrition: 0.1ms
    ├─ Insert log: 5ms
    └─ Total: ~17ms ✓ Good

Database Queries:
├─ Recipe: 1 SELECT + 1 INSERT = 2 queries
├─ Custom: 1 SELECT + 1 INSERT = 2 queries
└─ USDA: 2 SELECTs + 1 INSERT = 3 queries

Optimization Opportunities:
├─ [Future] Cache frequently used recipes
├─ [Future] Cache USDA food metadata
└─ [Future] Batch logging API (multiple foods at once)
```

## 10. Security Architecture

```
Defense in Depth Layers:
│
├─ Layer 1: Input Validation
│   ├─ Type safety (Gleam compiler)
│   ├─ Runtime checks (non-empty, positive, format)
│   └─ SQL injection: Prevented by pog parameterization
│
├─ Layer 2: Authorization
│   ├─ Custom foods: user_id verification
│   ├─ Recipes: Public (no auth needed)
│   └─ USDA foods: Public (no auth needed)
│
├─ Layer 3: Database Constraints
│   ├─ CHECK constraint on source_type
│   ├─ PRIMARY KEY on id (uniqueness)
│   ├─ NOT NULL on required fields
│   └─ Foreign keys (future: user_profile)
│
└─ Layer 4: Error Handling
    ├─ No sensitive data in error messages
    ├─ Sanitized errors sent to client
    └─ Full errors logged server-side

Threat Model:
├─ SQL Injection: ✓ Mitigated (parameterized queries)
├─ Unauthorized Access: ✓ Mitigated (user_id check)
├─ Data Leakage: ✓ Mitigated (sanitized errors)
└─ DoS: ⚠ Partial (rate limiting at API gateway level)
```

---

**Note:** All timing estimates based on local PostgreSQL instance.
Production performance may vary based on network latency and database load.
