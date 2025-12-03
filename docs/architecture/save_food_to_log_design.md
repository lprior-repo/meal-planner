# Architecture Design: save_food_to_log with Source Tracking

**Status:** Design Phase
**Created:** 2025-12-03
**Author:** System Architecture Designer

## Executive Summary

This document specifies the architecture for implementing `save_food_to_log`, a unified food logging function that handles three distinct food sources (Recipes, Custom Foods, USDA Foods) with complete source tracking, micronutrient support, and user authorization.

## 1. Database Schema Design

### 1.1 Migration 006: Source Tracking Columns

**File:** `gleam/migrations_pg/006_add_source_tracking.sql`

```sql
-- Migration 006: Add source tracking to food_logs
-- Enables unified food logging from multiple sources

-- Source type: 'recipe', 'custom_food', 'usda_food'
ALTER TABLE food_logs ADD COLUMN source_type TEXT;

-- Source identifier (recipe_id, custom_food_id, or fdc_id as text)
ALTER TABLE food_logs ADD COLUMN source_id TEXT;

-- Create composite index for source lookups
CREATE INDEX IF NOT EXISTS idx_food_logs_source ON food_logs(source_type, source_id);

-- Add constraint to ensure source data consistency
ALTER TABLE food_logs ADD CONSTRAINT check_source_consistency
  CHECK (
    (source_type IS NULL AND source_id IS NULL) OR
    (source_type IS NOT NULL AND source_id IS NOT NULL AND
     source_type IN ('recipe', 'custom_food', 'usda_food'))
  );

-- Note: Existing rows will have NULL for backward compatibility
-- New logs MUST populate these fields
```

### 1.2 Column Type Decision: TEXT vs ENUM

**Decision:** Use `TEXT` with `CHECK` constraint

**Rationale:**
- PostgreSQL TEXT with CHECK provides sufficient type safety
- More flexible than ENUM for potential future source types
- Avoids ALTER TYPE complexity in production migrations
- Index performance is equivalent to ENUM
- Gleam pattern matching provides compile-time safety

**Trade-offs:**
| Approach | Pros | Cons |
|----------|------|------|
| TEXT + CHECK | Flexible, easy migration, Gleam type safety | No DB-level enum validation |
| PostgreSQL ENUM | Strong DB typing, explicit | Hard to modify, migration complexity |
| **Selected: TEXT + CHECK** | **Best balance** | **Acceptable trade-off** |

### 1.3 Index Strategy

**Primary Index:** Composite index on `(source_type, source_id)`
- **Use case:** Finding all logs from a specific food source
- **Query pattern:** "Show all times I've eaten this custom food"
- **Performance:** O(log n) lookup instead of O(n) scan

**Existing Indexes:**
- `idx_food_logs_date` - Date-based queries (dashboard)
- `idx_food_logs_recipe` - Recipe lookups (legacy, can be deprecated)
- `idx_food_logs_source` - New composite source tracking

## 2. Type System Architecture

### 2.1 FoodSource Union Type

**Location:** `shared/src/shared/types.gleam`

```gleam
/// Identifies the source of a food log entry
pub type FoodSource {
  /// Recipe source with recipe ID
  RecipeSource(recipe_id: String)

  /// Custom food source with custom food ID and user ID for auth
  CustomFoodSource(custom_food_id: String, user_id: String)

  /// USDA food source with FDC ID
  UsdaFoodSource(fdc_id: Int)
}

/// Convert FoodSource to database representation
pub fn food_source_to_db(source: FoodSource) -> #(String, String) {
  case source {
    RecipeSource(id) -> #("recipe", id)
    CustomFoodSource(id, _) -> #("custom_food", id)
    UsdaFoodSource(fdc_id) -> #("usda_food", int.to_string(fdc_id))
  }
}

/// Parse database representation back to FoodSource
pub fn food_source_from_db(
  source_type: String,
  source_id: String,
  user_id: String
) -> Result(FoodSource, String) {
  case source_type {
    "recipe" -> Ok(RecipeSource(source_id))
    "custom_food" -> Ok(CustomFoodSource(source_id, user_id))
    "usda_food" -> {
      case int.parse(source_id) {
        Ok(fdc_id) -> Ok(UsdaFoodSource(fdc_id))
        Error(_) -> Error("Invalid FDC ID: " <> source_id)
      }
    }
    _ -> Error("Unknown source type: " <> source_type)
  }
}
```

### 2.2 Extended FoodLogEntry Type

**Modification:** Extend existing `FoodLogEntry` in `shared/src/shared/types.gleam`

```gleam
/// A single food log entry with source tracking
pub type FoodLogEntry {
  FoodLogEntry(
    id: String,
    recipe_id: String,              // DEPRECATED: Use source instead
    recipe_name: String,             // Display name (kept for convenience)
    servings: Float,
    macros: Macros,
    micronutrients: Option(Micronutrients),
    meal_type: MealType,
    logged_at: String,
    source: Option(FoodSource),      // NEW: Source tracking
  )
}
```

**Migration Strategy:**
- `source: Option(FoodSource)` allows backward compatibility
- Existing code continues to work with `None`
- New code populates `Some(source)`
- Eventually deprecate `recipe_id` field

### 2.3 Nutrient Parsing Helper Types

**Location:** `gleam/src/meal_planner/nutrient_parser.gleam` (new module)

```gleam
import shared/types.{type Macros, type Micronutrients, Macros, Micronutrients}
import meal_planner/storage.{type FoodNutrientValue}

/// Parsed nutrition from USDA nutrient list
pub type ParsedNutrition {
  ParsedNutrition(
    macros: Macros,
    micronutrients: Micronutrients,
    calories: Float,
  )
}

/// Parse USDA nutrients into structured nutrition data
pub fn parse_usda_nutrients(
  nutrients: List(FoodNutrientValue)
) -> ParsedNutrition
```

## 3. Function Architecture

### 3.1 Main Function Signature

**Location:** `gleam/src/meal_planner/storage.gleam`

```gleam
/// Save a food log entry with unified source tracking
/// Handles recipes, custom foods, and USDA foods
pub fn save_food_to_log(
  conn: pog.Connection,
  user_id: String,
  date: String,
  source: FoodSource,
  servings: Float,
  meal_type: MealType,
) -> Result(FoodLogEntry, StorageError)
```

**Parameters:**
- `conn` - Database connection
- `user_id` - Current user ID (for authorization)
- `date` - Date in YYYY-MM-DD format
- `source` - Union type identifying food source
- `servings` - Number of servings
- `meal_type` - Breakfast, Lunch, Dinner, or Snack

**Returns:**
- `Ok(FoodLogEntry)` - Successfully created log entry
- `Error(StorageError)` - Database error, not found, or unauthorized

### 3.2 Function Call Flow

```
save_food_to_log(conn, user_id, date, source, servings, meal_type)
  │
  ├─ Generate unique ID (UUID)
  │
  ├─ Pattern match on FoodSource
  │  │
  │  ├─ RecipeSource(recipe_id)
  │  │  ├─ fetch_recipe_details(conn, recipe_id)
  │  │  ├─ scale_macros(recipe.macros, servings)
  │  │  └─ name = recipe.name
  │  │
  │  ├─ CustomFoodSource(food_id, expected_user)
  │  │  ├─ fetch_custom_food(conn, food_id)
  │  │  ├─ AUTHORIZATION: verify user_id == food.user_id
  │  │  ├─ scale_nutrition(food, servings)
  │  │  └─ name = food.name
  │  │
  │  └─ UsdaFoodSource(fdc_id)
  │     ├─ fetch_food_by_id(conn, fdc_id)
  │     ├─ fetch_food_nutrients(conn, fdc_id)
  │     ├─ parse_usda_nutrients(nutrients)
  │     ├─ scale_nutrition(parsed, servings)
  │     └─ name = food.description
  │
  ├─ Build FoodLogEntry with complete nutrition
  │
  ├─ INSERT INTO food_logs with source_type, source_id
  │
  └─ Return FoodLogEntry
```

### 3.3 Helper Functions

#### 3.3.1 Nutrient Parser

```gleam
/// Parse USDA nutrients into structured Macros + Micronutrients
pub fn parse_usda_nutrients(
  nutrients: List(FoodNutrientValue)
) -> ParsedNutrition {
  let protein = find_nutrient(nutrients, "Protein") |> option.unwrap(0.0)
  let fat = find_nutrient(nutrients, "Total lipid (fat)") |> option.unwrap(0.0)
  let carbs = find_nutrient(nutrients, "Carbohydrate, by difference") |> option.unwrap(0.0)
  let calories = find_nutrient(nutrients, "Energy") |> option.unwrap(0.0)

  let macros = Macros(protein: protein, fat: fat, carbs: carbs)

  let micronutrients = Micronutrients(
    fiber: find_nutrient(nutrients, "Fiber, total dietary"),
    sugar: find_nutrient(nutrients, "Sugars, total including NLEA"),
    sodium: find_nutrient(nutrients, "Sodium, Na"),
    cholesterol: find_nutrient(nutrients, "Cholesterol"),
    vitamin_a: find_nutrient(nutrients, "Vitamin A, RAE"),
    vitamin_c: find_nutrient(nutrients, "Vitamin C, total ascorbic acid"),
    // ... all 21 micronutrients
  )

  ParsedNutrition(macros: macros, micronutrients: micronutrients, calories: calories)
}

fn find_nutrient(
  nutrients: List(FoodNutrientValue),
  name: String
) -> Option(Float) {
  list.find(nutrients, fn(n) { n.nutrient_name == name })
  |> option.from_result
  |> option.map(fn(n) { n.amount })
}
```

#### 3.3.2 Custom Food Fetcher

```gleam
/// Fetch and validate custom food
fn fetch_and_validate_custom_food(
  conn: pog.Connection,
  food_id: String,
  user_id: String,
) -> Result(CustomFood, StorageError) {
  use food <- result.try(get_custom_food_by_id(conn, food_id))

  // Authorization check
  case food.user_id == user_id {
    True -> Ok(food)
    False -> Error(Unauthorized("Cannot log another user's custom food"))
  }
}
```

#### 3.3.3 Nutrition Scaler

```gleam
/// Scale nutrition by serving size
fn scale_nutrition(
  base_macros: Macros,
  base_micros: Option(Micronutrients),
  base_serving_size: Float,
  actual_servings: Float,
) -> #(Macros, Option(Micronutrients)) {
  let factor = actual_servings /. base_serving_size
  let scaled_macros = types.macros_scale(base_macros, factor)
  let scaled_micros = option.map(base_micros, fn(m) {
    types.micronutrients_scale(m, factor)
  })
  #(scaled_macros, scaled_micros)
}
```

## 4. Security Architecture

### 4.1 Authorization Strategy

**Principle:** User data isolation at application layer

**Authorization Points:**

1. **Custom Foods:** Must verify `user_id` matches `food.user_id`
   ```gleam
   case food.user_id == user_id {
     True -> Ok(food)
     False -> Error(Unauthorized("Cannot access another user's custom food"))
   }
   ```

2. **Recipes:** Public data, no authorization needed

3. **USDA Foods:** Public data, no authorization needed

### 4.2 Input Validation

**Validation Rules:**

| Field | Validation | Error |
|-------|-----------|-------|
| `user_id` | Non-empty string | InvalidInput("user_id required") |
| `date` | YYYY-MM-DD format | InvalidInput("Invalid date format") |
| `servings` | Positive float > 0.0 | InvalidInput("Servings must be positive") |
| `source` | Valid FoodSource | InvalidInput("Invalid food source") |
| `meal_type` | Valid MealType enum | InvalidInput("Invalid meal type") |

**Implementation Location:** Before database operations

```gleam
fn validate_log_input(
  user_id: String,
  date: String,
  servings: Float,
) -> Result(Nil, StorageError) {
  use <- bool.guard(
    string.is_empty(user_id),
    Error(InvalidInput("user_id required"))
  )
  use <- bool.guard(
    servings <=. 0.0,
    Error(InvalidInput("Servings must be positive"))
  )
  use <- bool.guard(
    !is_valid_date_format(date),
    Error(InvalidInput("Invalid date format (use YYYY-MM-DD)"))
  )
  Ok(Nil)
}
```

### 4.3 SQL Injection Prevention

**Strategy:** pog library parameterized queries (automatic)

- All values passed via `pog.parameter()`
- No string concatenation in SQL
- pog handles escaping and type safety

**Example:**
```gleam
pog.query(sql)
|> pog.parameter(pog.text(user_id))      // Safe: parameterized
|> pog.parameter(pog.text(source_type))  // Safe: parameterized
|> pog.execute(conn)
```

## 5. Performance Architecture

### 5.1 Single Transaction Strategy

**Goal:** Minimize database round trips and ensure atomicity

**Approach:** Batch fetch + single INSERT

```gleam
pub fn save_food_to_log(...) -> Result(FoodLogEntry, StorageError) {
  // 1. Fetch source data (1 query)
  use nutrition_data <- result.try(fetch_nutrition_for_source(conn, source, user_id))

  // 2. Scale nutrition (in-memory operation)
  let #(scaled_macros, scaled_micros) = scale_nutrition(nutrition_data, servings)

  // 3. Insert log entry (1 query)
  use _ <- result.try(insert_food_log(conn, ...))

  // 4. Return constructed entry (no additional query)
  Ok(build_log_entry(...))
}
```

**Total Queries:** 2 (fetch + insert)

**Alternative (Rejected):** Transaction wrapper
- Pro: ACID guarantees
- Con: Connection overhead, potential deadlocks
- Decision: Not needed for single INSERT operation

### 5.2 Query Optimization

**Fetch Queries:**

1. **Recipe Fetch:**
   ```sql
   SELECT id, name, protein, fat, carbs, servings
   FROM recipes WHERE id = $1
   ```
   - Uses primary key (instant lookup)

2. **Custom Food Fetch:**
   ```sql
   SELECT id, user_id, name, serving_size, serving_unit,
          protein, fat, carbs, calories,
          fiber, sugar, sodium, ... (all micronutrients)
   FROM custom_foods WHERE id = $1
   ```
   - Uses primary key (instant lookup)
   - Fetches all nutrition in one query

3. **USDA Food Fetch:**
   ```sql
   -- Query 1: Food metadata
   SELECT fdc_id, description FROM foods WHERE fdc_id = $1

   -- Query 2: Nutrients
   SELECT n.name, fn.amount, n.unit_name
   FROM food_nutrients fn
   JOIN nutrients n ON fn.nutrient_id = n.id
   WHERE fn.fdc_id = $1
   ORDER BY n.rank NULLS LAST
   ```
   - Existing indexes on `fdc_id` (primary key)
   - JOIN optimized by foreign key relationship

### 5.3 Caching Considerations

**Future Optimization:** Recipe caching

```gleam
// Future: Cache frequently accessed recipes
// Not implemented in v1 to avoid premature optimization

// pub fn save_food_to_log_cached(
//   conn: pog.Connection,
//   cache: RecipeCache,
//   ...
// ) -> Result(FoodLogEntry, StorageError)
```

**Rationale for NOT caching in v1:**
- Recipes change infrequently (good cache candidate)
- Custom foods are user-specific (poor cache candidate)
- USDA foods are static (excellent cache candidate)
- Decision: Implement caching only if profiling shows bottleneck

## 6. Error Handling Strategy

### 6.1 Error Type Extensions

**Extend:** `pub type StorageError` in `storage.gleam`

```gleam
pub type StorageError {
  NotFound
  DatabaseError(String)
  InvalidInput(String)           // NEW: Validation errors
  Unauthorized(String)           // NEW: Authorization failures
  NutrientParseError(String)     // NEW: USDA parsing failures
}
```

### 6.2 Error Propagation Pattern

**Use `use` syntax for clean error handling:**

```gleam
pub fn save_food_to_log(...) -> Result(FoodLogEntry, StorageError) {
  // Validation
  use _ <- result.try(validate_log_input(user_id, date, servings))

  // Fetch nutrition data with error propagation
  use #(name, macros, micros) <- result.try(case source {
    RecipeSource(id) -> fetch_recipe_nutrition(conn, id)
    CustomFoodSource(id, _) -> fetch_custom_nutrition(conn, id, user_id)
    UsdaFoodSource(fdc_id) -> fetch_usda_nutrition(conn, fdc_id)
  })

  // Scale and build entry
  let scaled_macros = types.macros_scale(macros, servings)
  let scaled_micros = option.map(micros, fn(m) { types.micronutrients_scale(m, servings) })

  // Insert with error handling
  use log_id <- result.try(insert_food_log_entry(conn, ...))

  // Return success
  Ok(build_log_entry(log_id, name, scaled_macros, scaled_micros, ...))
}
```

### 6.3 Error Messages

**User-Facing Error Messages:**

| Error Code | Message Template | HTTP Status |
|------------|------------------|-------------|
| NotFound | "Food not found: {source_type} {source_id}" | 404 |
| Unauthorized | "Cannot log another user's custom food" | 403 |
| InvalidInput | "Invalid input: {field} - {reason}" | 400 |
| DatabaseError | "Database error occurred. Please try again." | 500 |
| NutrientParseError | "Unable to parse nutrition data for food {fdc_id}" | 500 |

**Logging Strategy:**
- Log full error details server-side
- Return sanitized messages to client
- Include correlation ID for support debugging

## 7. Testing Strategy

### 7.1 Unit Tests

**Location:** `gleam/test/meal_planner/storage_test.gleam`

**Test Cases:**

1. **Type System Tests**
   ```gleam
   pub fn food_source_to_db_recipe_test() {
     let source = RecipeSource("recipe-123")
     let #(type, id) = food_source_to_db(source)
     should.equal(type, "recipe")
     should.equal(id, "recipe-123")
   }

   pub fn food_source_from_db_custom_food_test() {
     let result = food_source_from_db("custom_food", "food-456", "user-1")
     should.be_ok(result)
     let assert Ok(CustomFoodSource(id, user)) = result
     should.equal(id, "food-456")
     should.equal(user, "user-1")
   }
   ```

2. **Nutrient Parser Tests**
   ```gleam
   pub fn parse_usda_nutrients_complete_test() {
     let nutrients = [
       FoodNutrientValue("Protein", 25.0, "g"),
       FoodNutrientValue("Total lipid (fat)", 10.0, "g"),
       FoodNutrientValue("Carbohydrate, by difference", 5.0, "g"),
       FoodNutrientValue("Fiber, total dietary", 2.0, "g"),
     ]
     let parsed = parse_usda_nutrients(nutrients)
     should.equal(parsed.macros.protein, 25.0)
     should.equal(parsed.micronutrients.fiber, Some(2.0))
   }

   pub fn parse_usda_nutrients_missing_optional_test() {
     let nutrients = [
       FoodNutrientValue("Protein", 25.0, "g"),
     ]
     let parsed = parse_usda_nutrients(nutrients)
     should.equal(parsed.micronutrients.fiber, None)
   }
   ```

3. **Authorization Tests**
   ```gleam
   pub fn save_food_custom_authorized_test() {
     // Setup: Create custom food for user-1
     let food = create_test_custom_food(conn, "user-1")

     // Act: user-1 logs their own food
     let result = save_food_to_log(
       conn, "user-1", "2025-12-03",
       CustomFoodSource(food.id, "user-1"), 1.0, Breakfast
     )

     // Assert: Success
     should.be_ok(result)
   }

   pub fn save_food_custom_unauthorized_test() {
     // Setup: Create custom food for user-1
     let food = create_test_custom_food(conn, "user-1")

     // Act: user-2 tries to log user-1's food
     let result = save_food_to_log(
       conn, "user-2", "2025-12-03",
       CustomFoodSource(food.id, "user-2"), 1.0, Breakfast
     )

     // Assert: Unauthorized error
     should.be_error(result)
     let assert Error(Unauthorized(_)) = result
   }
   ```

### 7.2 Integration Tests

**Scenario-Based Testing:**

1. **Happy Path: Recipe Logging**
   - Create recipe in database
   - Log 1.5 servings for breakfast
   - Verify scaled macros in food_logs table
   - Verify source_type = "recipe"

2. **Happy Path: Custom Food with Micronutrients**
   - Create custom food with full nutrition
   - Log 2.0 servings for lunch
   - Verify all 21 micronutrients scaled correctly
   - Verify source_type = "custom_food"

3. **Happy Path: USDA Food**
   - Use existing USDA food (fdc_id from test data)
   - Log 100g serving for dinner
   - Verify nutrient parsing worked
   - Verify source_type = "usda_food"

4. **Error Path: Not Found**
   - Attempt to log non-existent recipe
   - Verify NotFound error returned
   - Verify no row inserted

5. **Error Path: Unauthorized**
   - Create custom food for user A
   - User B attempts to log it
   - Verify Unauthorized error
   - Verify no row inserted

### 7.3 Performance Tests

**Benchmarks:**

```gleam
pub fn benchmark_save_food_to_log_recipe() {
  // Measure: Recipe lookup + insert
  // Target: < 10ms (excluding network)
}

pub fn benchmark_save_food_to_log_usda() {
  // Measure: USDA food + nutrients lookup + parse + insert
  // Target: < 50ms (more complex, acceptable)
}
```

## 8. Migration Path

### 8.1 Database Migration

**Step 1:** Run migration 006
```bash
psql -d meal_planner -f gleam/migrations_pg/006_add_source_tracking.sql
```

**Step 2:** Backfill existing logs (optional)
```sql
-- Backfill recipe sources for existing logs
UPDATE food_logs
SET source_type = 'recipe',
    source_id = recipe_id
WHERE source_type IS NULL AND recipe_id IS NOT NULL;
```

### 8.2 Code Migration

**Phase 1:** Add new functions (non-breaking)
- Implement `save_food_to_log` with source tracking
- Existing code continues using old patterns
- No API changes required

**Phase 2:** Deprecate old patterns (gradual)
- Mark `save_food_log` as deprecated
- Update web handlers to use new function
- Client code updated incrementally

**Phase 3:** Remove deprecated code (future)
- After 100% migration, remove old function
- Drop `recipe_id` column (if desired)

### 8.3 API Versioning

**No Breaking Changes Required:**
- New function is additive
- Existing endpoints continue working
- New endpoint: `POST /api/log/food` (source-aware)
- Old endpoint: `POST /api/log/recipe` (still works)

## 9. Architecture Decision Records (ADRs)

### ADR-001: Use TEXT for source_type instead of ENUM

**Status:** Accepted

**Context:** Need to store food source type in database

**Decision:** Use TEXT with CHECK constraint

**Consequences:**
- Positive: Easy to add new source types
- Positive: Simple migration path
- Negative: No database-level enum validation
- Mitigation: Gleam types provide compile-time safety

### ADR-002: Single transaction without explicit BEGIN/COMMIT

**Status:** Accepted

**Context:** Need ACID guarantees for food logging

**Decision:** Use two separate queries (fetch + insert) without explicit transaction

**Consequences:**
- Positive: Simpler code, no connection overhead
- Positive: pog auto-commits, sufficient for single INSERT
- Negative: Source data could change between fetch and insert
- Mitigation: Race condition is acceptable (food data rarely changes)

### ADR-003: Embed user_id in CustomFoodSource for authorization

**Status:** Accepted

**Context:** Need to authorize custom food access

**Decision:** Include user_id in CustomFoodSource variant

**Consequences:**
- Positive: Authorization intent explicit in type
- Positive: Caller must provide user context
- Negative: Redundant data (user_id stored in CustomFood table)
- Mitigation: Type safety outweighs minor redundancy

## 10. Implementation Checklist

- [ ] Write migration 006 SQL file
- [ ] Run migration on development database
- [ ] Add FoodSource union type to shared/types.gleam
- [ ] Extend FoodLogEntry with source field
- [ ] Create nutrient_parser.gleam module
- [ ] Implement parse_usda_nutrients function
- [ ] Extend StorageError with new variants
- [ ] Implement save_food_to_log function
- [ ] Write unit tests for type conversions
- [ ] Write unit tests for nutrient parsing
- [ ] Write integration tests for all three sources
- [ ] Write authorization tests
- [ ] Add API endpoint handler
- [ ] Update web UI to use new function
- [ ] Performance benchmark
- [ ] Documentation update
- [ ] Code review
- [ ] Deploy to staging
- [ ] Run backfill script
- [ ] Deploy to production

## 11. Future Enhancements

### 11.1 Caching Layer
- Cache frequently accessed recipes (80/20 rule)
- Cache USDA food metadata (static data)
- Use in-memory ETS table for Erlang/BEAM efficiency

### 11.2 Batch Logging
- `save_multiple_foods_to_log` for meal planning
- Single transaction for multiple entries
- Better UX for logging full meals

### 11.3 Nutrition Versioning
- Track when food nutrition data changes
- Historical accuracy for past logs
- Snapshot nutrition at log time

### 11.4 Advanced Authorization
- Shared custom foods (family/team accounts)
- Public custom foods (community recipes)
- Permission system (view, log, edit)

## 12. References

- **Existing Migrations:** `gleam/migrations_pg/001-005`
- **Type System:** `shared/src/shared/types.gleam`
- **Storage Layer:** `gleam/src/meal_planner/storage.gleam`
- **Web Layer:** `gleam/src/meal_planner/web.gleam`
- **USDA Database:** FoodData Central schema
- **pog Documentation:** https://hexdocs.pm/pog/

---

**Document Version:** 1.0
**Last Updated:** 2025-12-03
**Next Review:** After implementation phase
