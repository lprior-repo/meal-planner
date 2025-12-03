# Quick Reference: save_food_to_log Implementation

**Quick access guide for implementing the save_food_to_log function**

## Files to Create/Modify

```
gleam/
├── migrations_pg/
│   └── 006_add_source_tracking.sql          [CREATE]
├── src/meal_planner/
│   ├── nutrient_parser.gleam                [CREATE]
│   ├── storage.gleam                        [MODIFY]
│   └── web.gleam                            [MODIFY]
├── test/meal_planner/
│   ├── nutrient_parser_test.gleam           [CREATE]
│   └── storage_test.gleam                   [MODIFY]
shared/src/shared/
└── types.gleam                              [MODIFY]
```

## Migration SQL (006_add_source_tracking.sql)

```sql
-- Add source tracking columns
ALTER TABLE food_logs ADD COLUMN source_type TEXT;
ALTER TABLE food_logs ADD COLUMN source_id TEXT;

-- Index for efficient source lookups
CREATE INDEX IF NOT EXISTS idx_food_logs_source
  ON food_logs(source_type, source_id);

-- Constraint: both NULL or both NOT NULL with valid type
ALTER TABLE food_logs ADD CONSTRAINT check_source_consistency
  CHECK (
    (source_type IS NULL AND source_id IS NULL) OR
    (source_type IS NOT NULL AND source_id IS NOT NULL AND
     source_type IN ('recipe', 'custom_food', 'usda_food'))
  );
```

## Type Definitions (shared/types.gleam)

```gleam
/// Food source union type
pub type FoodSource {
  RecipeSource(recipe_id: String)
  CustomFoodSource(custom_food_id: String, user_id: String)
  UsdaFoodSource(fdc_id: Int)
}

/// Convert to database representation
pub fn food_source_to_db(source: FoodSource) -> #(String, String) {
  case source {
    RecipeSource(id) -> #("recipe", id)
    CustomFoodSource(id, _) -> #("custom_food", id)
    UsdaFoodSource(fdc_id) -> #("usda_food", int.to_string(fdc_id))
  }
}

/// Parse from database
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
        Error(_) -> Error("Invalid FDC ID")
      }
    }
    _ -> Error("Unknown source type")
  }
}

/// Extended FoodLogEntry
pub type FoodLogEntry {
  FoodLogEntry(
    id: String,
    recipe_id: String,                        // DEPRECATED
    recipe_name: String,
    servings: Float,
    macros: Macros,
    micronutrients: Option(Micronutrients),
    meal_type: MealType,
    logged_at: String,
    source: Option(FoodSource),               // NEW
  )
}
```

## Storage Error Extensions (storage.gleam)

```gleam
pub type StorageError {
  NotFound
  DatabaseError(String)
  InvalidInput(String)           // NEW
  Unauthorized(String)           // NEW
  NutrientParseError(String)     // NEW
}
```

## Main Function Signature (storage.gleam)

```gleam
pub fn save_food_to_log(
  conn: pog.Connection,
  user_id: String,
  date: String,
  source: FoodSource,
  servings: Float,
  meal_type: MealType,
) -> Result(FoodLogEntry, StorageError)
```

## Implementation Skeleton (storage.gleam)

```gleam
pub fn save_food_to_log(
  conn: pog.Connection,
  user_id: String,
  date: String,
  source: FoodSource,
  servings: Float,
  meal_type: MealType,
) -> Result(FoodLogEntry, StorageError) {
  // 1. Generate log ID
  let log_id = generate_uuid()

  // 2. Validate inputs
  use _ <- result.try(validate_log_input(user_id, date, servings))

  // 3. Fetch nutrition based on source
  use #(name, base_macros, base_micros) <- result.try(
    case source {
      RecipeSource(recipe_id) -> fetch_recipe_nutrition(conn, recipe_id)
      CustomFoodSource(food_id, _) -> fetch_custom_nutrition(conn, food_id, user_id)
      UsdaFoodSource(fdc_id) -> fetch_usda_nutrition(conn, fdc_id)
    }
  )

  // 4. Scale nutrition by servings
  let scaled_macros = types.macros_scale(base_macros, servings)
  let scaled_micros = option.map(base_micros, fn(m) {
    types.micronutrients_scale(m, servings)
  })

  // 5. Get source metadata
  let #(source_type, source_id) = food_source_to_db(source)

  // 6. Insert into database
  use _ <- result.try(insert_food_log_with_source(
    conn, log_id, date, name, servings,
    scaled_macros, scaled_micros, meal_type,
    source_type, source_id
  ))

  // 7. Return FoodLogEntry
  Ok(FoodLogEntry(
    id: log_id,
    recipe_id: source_id,  // For backward compatibility
    recipe_name: name,
    servings: servings,
    macros: scaled_macros,
    micronutrients: scaled_micros,
    meal_type: meal_type,
    logged_at: get_current_timestamp(),
    source: Some(source),
  ))
}
```

## Helper Functions

### Validation

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
    Error(InvalidInput("Invalid date format"))
  )
  Ok(Nil)
}

fn is_valid_date_format(date: String) -> Bool {
  // Check YYYY-MM-DD format
  case string.length(date) {
    10 -> {
      let parts = string.split(date, "-")
      case parts {
        [year, month, day] ->
          string.length(year) == 4 &&
          string.length(month) == 2 &&
          string.length(day) == 2
        _ -> False
      }
    }
    _ -> False
  }
}
```

### Recipe Nutrition Fetcher

```gleam
fn fetch_recipe_nutrition(
  conn: pog.Connection,
  recipe_id: String,
) -> Result(#(String, Macros, Option(Micronutrients)), StorageError) {
  use recipe <- result.try(get_recipe_by_id(conn, recipe_id))
  Ok(#(recipe.name, recipe.macros, None))
}
```

### Custom Food Nutrition Fetcher

```gleam
fn fetch_custom_nutrition(
  conn: pog.Connection,
  food_id: String,
  user_id: String,
) -> Result(#(String, Macros, Option(Micronutrients)), StorageError) {
  use food <- result.try(get_custom_food_by_id(conn, food_id))

  // Authorization check
  use <- bool.guard(
    food.user_id != user_id,
    Error(Unauthorized("Cannot log another user's custom food"))
  )

  Ok(#(food.name, food.macros, food.micronutrients))
}
```

### USDA Nutrition Fetcher

```gleam
fn fetch_usda_nutrition(
  conn: pog.Connection,
  fdc_id: Int,
) -> Result(#(String, Macros, Option(Micronutrients)), StorageError) {
  use food <- result.try(get_food_by_id(conn, fdc_id))
  use nutrients <- result.try(get_food_nutrients(conn, fdc_id))

  let parsed = nutrient_parser.parse_usda_nutrients(nutrients)

  Ok(#(food.description, parsed.macros, Some(parsed.micronutrients)))
}
```

## Nutrient Parser (nutrient_parser.gleam)

```gleam
import shared/types.{type Macros, type Micronutrients, Macros, Micronutrients}
import meal_planner/storage.{type FoodNutrientValue}
import gleam/list
import gleam/option.{type Option, Some, None}

pub type ParsedNutrition {
  ParsedNutrition(
    macros: Macros,
    micronutrients: Micronutrients,
    calories: Float,
  )
}

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
    vitamin_d: find_nutrient(nutrients, "Vitamin D (D2 + D3)"),
    vitamin_e: find_nutrient(nutrients, "Vitamin E (alpha-tocopherol)"),
    vitamin_k: find_nutrient(nutrients, "Vitamin K (phylloquinone)"),
    vitamin_b6: find_nutrient(nutrients, "Vitamin B-6"),
    vitamin_b12: find_nutrient(nutrients, "Vitamin B-12"),
    folate: find_nutrient(nutrients, "Folate, total"),
    thiamin: find_nutrient(nutrients, "Thiamin"),
    riboflavin: find_nutrient(nutrients, "Riboflavin"),
    niacin: find_nutrient(nutrients, "Niacin"),
    calcium: find_nutrient(nutrients, "Calcium, Ca"),
    iron: find_nutrient(nutrients, "Iron, Fe"),
    magnesium: find_nutrient(nutrients, "Magnesium, Mg"),
    phosphorus: find_nutrient(nutrients, "Phosphorus, P"),
    potassium: find_nutrient(nutrients, "Potassium, K"),
    zinc: find_nutrient(nutrients, "Zinc, Zn"),
  )

  ParsedNutrition(
    macros: macros,
    micronutrients: micronutrients,
    calories: calories,
  )
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

## Test Cases (storage_test.gleam)

```gleam
import gleeunit/should
import meal_planner/storage
import shared/types.{RecipeSource, CustomFoodSource, UsdaFoodSource, Breakfast}

pub fn save_recipe_log_test() {
  let conn = setup_test_db()
  let recipe = create_test_recipe(conn)

  let result = storage.save_food_to_log(
    conn, "user-1", "2025-12-03",
    RecipeSource(recipe.id), 1.5, Breakfast
  )

  should.be_ok(result)
  let assert Ok(log) = result
  should.equal(log.servings, 1.5)
  should.equal(log.source, Some(RecipeSource(recipe.id)))
}

pub fn save_custom_food_authorized_test() {
  let conn = setup_test_db()
  let food = create_test_custom_food(conn, "user-1")

  let result = storage.save_food_to_log(
    conn, "user-1", "2025-12-03",
    CustomFoodSource(food.id, "user-1"), 2.0, Breakfast
  )

  should.be_ok(result)
}

pub fn save_custom_food_unauthorized_test() {
  let conn = setup_test_db()
  let food = create_test_custom_food(conn, "user-1")

  let result = storage.save_food_to_log(
    conn, "user-2", "2025-12-03",
    CustomFoodSource(food.id, "user-2"), 1.0, Breakfast
  )

  should.be_error(result)
  let assert Error(storage.Unauthorized(_)) = result
}

pub fn save_usda_food_test() {
  let conn = setup_test_db()

  let result = storage.save_food_to_log(
    conn, "user-1", "2025-12-03",
    UsdaFoodSource(171477), 1.0, Breakfast
  )

  should.be_ok(result)
  let assert Ok(log) = result
  should.equal(log.source, Some(UsdaFoodSource(171477)))
  // Verify nutrients were parsed
  should.be_some(log.micronutrients)
}
```

## API Endpoint (web.gleam)

```gleam
/// POST /api/log/food
/// Body: { user_id, date, source: { type, id }, servings, meal_type }
fn api_log_food(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // Parse JSON body
  use body <- wisp.require_json(req)

  // Decode request
  use log_request <- result.try(decode_log_food_request(body))

  // Save to database
  case storage.save_food_to_log(
    ctx.db,
    log_request.user_id,
    log_request.date,
    log_request.source,
    log_request.servings,
    log_request.meal_type,
  ) {
    Ok(entry) -> {
      let json_data = food_log_entry_to_json(entry)
      wisp.json_response(json.to_string(json_data), 201)
    }
    Error(storage.NotFound) -> {
      wisp.json_response(
        json.to_string(json.object([
          #("error", json.string("Food not found"))
        ])),
        404
      )
    }
    Error(storage.Unauthorized(msg)) -> {
      wisp.json_response(
        json.to_string(json.object([
          #("error", json.string(msg))
        ])),
        403
      )
    }
    Error(storage.InvalidInput(msg)) -> {
      wisp.json_response(
        json.to_string(json.object([
          #("error", json.string(msg))
        ])),
        400
      )
    }
    Error(_) -> {
      wisp.json_response(
        json.to_string(json.object([
          #("error", json.string("Internal server error"))
        ])),
        500
      )
    }
  }
}
```

## Implementation Order

1. ✅ Run migration 006
2. ✅ Add FoodSource type to shared/types.gleam
3. ✅ Extend StorageError in storage.gleam
4. ✅ Create nutrient_parser.gleam
5. ✅ Implement parse_usda_nutrients
6. ✅ Write tests for nutrient_parser
7. ✅ Implement save_food_to_log in storage.gleam
8. ✅ Implement helper fetch functions
9. ✅ Write unit tests for save_food_to_log
10. ✅ Add API endpoint in web.gleam
11. ✅ Integration tests
12. ✅ Performance benchmark
13. ✅ Deploy to staging
14. ✅ Production deployment

## Common Pitfalls to Avoid

❌ **Don't** use string concatenation in SQL
✅ **Do** use pog.parameter() for all values

❌ **Don't** skip authorization check for custom foods
✅ **Do** verify user_id == food.user_id

❌ **Don't** assume all micronutrients are present
✅ **Do** use Option(Float) for micronutrients

❌ **Don't** forget to scale nutrition by servings
✅ **Do** scale macros AND micronutrients

❌ **Don't** return full error details to client
✅ **Do** sanitize errors, log full details server-side

## Performance Targets

| Operation | Target | Measurement |
|-----------|--------|-------------|
| Recipe log | < 10ms | PK lookup + insert |
| Custom food log | < 10ms | PK lookup + auth + insert |
| USDA food log | < 50ms | 2 queries + parse + insert |
| Database queries | ≤ 3 | Minimize round trips |

## Security Checklist

- [ ] All SQL uses parameterized queries
- [ ] Custom food authorization implemented
- [ ] Input validation before database access
- [ ] Error messages don't leak sensitive data
- [ ] User IDs verified on every custom food access
- [ ] CHECK constraint on source_type in database
- [ ] Audit logging for security events (optional)

---

**Quick Links:**
- [Full Architecture Design](/home/lewis/src/meal-planner/docs/architecture/save_food_to_log_design.md)
- [Visual Diagrams](/home/lewis/src/meal-planner/docs/architecture/save_food_to_log_diagrams.md)
