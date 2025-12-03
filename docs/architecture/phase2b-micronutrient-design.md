# ARCHITECTURE DESIGN: MICRONUTRIENT FOOD LOGGING

**Phase 2B - Detailed System Architecture**

## Overview

This architecture adds micronutrient tracking to food logging with full backward compatibility. All 21 micronutrient fields are stored as individual nullable database columns for efficient querying and aggregation.

---

## 1. TYPE SYSTEM DESIGN

**File**: `shared/src/shared/types.gleam`

### 1.1 Update FoodLogEntry Type

**Location**: Around line 288

**Change**:
```gleam
/// A single food log entry with optional micronutrient data
pub type FoodLogEntry {
  FoodLogEntry(
    id: String,
    recipe_id: String,
    recipe_name: String,
    servings: Float,
    macros: Macros,
    micronutrients: Option(Micronutrients),  // NEW FIELD
    meal_type: MealType,
    logged_at: String,
  )
}
```

### 1.2 Update DailyLog Type

**Location**: Around line 301

**Change**:
```gleam
/// Daily food log with aggregated micronutrients
pub type DailyLog {
  DailyLog(
    date: String,
    entries: List(FoodLogEntry),
    total_macros: Macros,
    total_micronutrients: Option(Micronutrients),  // NEW FIELD
  )
}
```

### 1.3 Add Micronutrient Helper Functions

**Location**: After existing macros helpers (after line 51)

```gleam
// ============================================================================
// Micronutrient Helper Functions
// ============================================================================

/// Empty micronutrients (all None)
pub fn micronutrients_zero() -> Micronutrients {
  Micronutrients(
    fiber: None,
    sugar: None,
    sodium: None,
    cholesterol: None,
    vitamin_a: None,
    vitamin_c: None,
    vitamin_d: None,
    vitamin_e: None,
    vitamin_k: None,
    vitamin_b6: None,
    vitamin_b12: None,
    folate: None,
    thiamin: None,
    riboflavin: None,
    niacin: None,
    calcium: None,
    iron: None,
    magnesium: None,
    phosphorus: None,
    potassium: None,
    zinc: None,
  )
}

/// Scale micronutrients by a factor (for serving adjustments)
pub fn micronutrients_scale(m: Micronutrients, factor: Float) -> Micronutrients {
  Micronutrients(
    fiber: option.map(m.fiber, fn(v) { v *. factor }),
    sugar: option.map(m.sugar, fn(v) { v *. factor }),
    sodium: option.map(m.sodium, fn(v) { v *. factor }),
    cholesterol: option.map(m.cholesterol, fn(v) { v *. factor }),
    vitamin_a: option.map(m.vitamin_a, fn(v) { v *. factor }),
    vitamin_c: option.map(m.vitamin_c, fn(v) { v *. factor }),
    vitamin_d: option.map(m.vitamin_d, fn(v) { v *. factor }),
    vitamin_e: option.map(m.vitamin_e, fn(v) { v *. factor }),
    vitamin_k: option.map(m.vitamin_k, fn(v) { v *. factor }),
    vitamin_b6: option.map(m.vitamin_b6, fn(v) { v *. factor }),
    vitamin_b12: option.map(m.vitamin_b12, fn(v) { v *. factor }),
    folate: option.map(m.folate, fn(v) { v *. factor }),
    thiamin: option.map(m.thiamin, fn(v) { v *. factor }),
    riboflavin: option.map(m.riboflavin, fn(v) { v *. factor }),
    niacin: option.map(m.niacin, fn(v) { v *. factor }),
    calcium: option.map(m.calcium, fn(v) { v *. factor }),
    iron: option.map(m.iron, fn(v) { v *. factor }),
    magnesium: option.map(m.magnesium, fn(v) { v *. factor }),
    phosphorus: option.map(m.phosphorus, fn(v) { v *. factor }),
    potassium: option.map(m.potassium, fn(v) { v *. factor }),
    zinc: option.map(m.zinc, fn(v) { v *. factor }),
  )
}

/// Add two micronutrient values (handles None gracefully)
pub fn micronutrients_add(a: Micronutrients, b: Micronutrients) -> Micronutrients {
  Micronutrients(
    fiber: add_optional(a.fiber, b.fiber),
    sugar: add_optional(a.sugar, b.sugar),
    sodium: add_optional(a.sodium, b.sodium),
    cholesterol: add_optional(a.cholesterol, b.cholesterol),
    vitamin_a: add_optional(a.vitamin_a, b.vitamin_a),
    vitamin_c: add_optional(a.vitamin_c, b.vitamin_c),
    vitamin_d: add_optional(a.vitamin_d, b.vitamin_d),
    vitamin_e: add_optional(a.vitamin_e, b.vitamin_e),
    vitamin_k: add_optional(a.vitamin_k, b.vitamin_k),
    vitamin_b6: add_optional(a.vitamin_b6, b.vitamin_b6),
    vitamin_b12: add_optional(a.vitamin_b12, b.vitamin_b12),
    folate: add_optional(a.folate, b.folate),
    thiamin: add_optional(a.thiamin, b.thiamin),
    riboflavin: add_optional(a.riboflavin, b.riboflavin),
    niacin: add_optional(a.niacin, b.niacin),
    calcium: add_optional(a.calcium, b.calcium),
    iron: add_optional(a.iron, b.iron),
    magnesium: add_optional(a.magnesium, b.magnesium),
    phosphorus: add_optional(a.phosphorus, b.phosphorus),
    potassium: add_optional(a.potassium, b.potassium),
    zinc: add_optional(a.zinc, b.zinc),
  )
}

/// Sum a list of micronutrient values
pub fn micronutrients_sum(micros: List(Micronutrients)) -> Micronutrients {
  list.fold(micros, micronutrients_zero(), micronutrients_add)
}

/// Helper: Add two optional float values
fn add_optional(a: Option(Float), b: Option(Float)) -> Option(Float) {
  case a, b {
    Some(va), Some(vb) -> Some(va +. vb)
    Some(va), None -> Some(va)
    None, Some(vb) -> Some(vb)
    None, None -> None
  }
}
```

### 1.4 Update JSON Encoding

**food_log_entry_to_json** (around line 516):
```gleam
pub fn food_log_entry_to_json(e: FoodLogEntry) -> Json {
  let fields = [
    #("id", json.string(e.id)),
    #("recipe_id", json.string(e.recipe_id)),
    #("recipe_name", json.string(e.recipe_name)),
    #("servings", json.float(e.servings)),
    #("macros", macros_to_json(e.macros)),
    #("meal_type", json.string(meal_type_to_string(e.meal_type))),
    #("logged_at", json.string(e.logged_at)),
  ]

  let fields = case e.micronutrients {
    Some(micros) -> [#("micronutrients", micronutrients_to_json(micros)), ..fields]
    None -> fields
  }

  json.object(fields)
}
```

**daily_log_to_json** (around line 528):
```gleam
pub fn daily_log_to_json(d: DailyLog) -> Json {
  let fields = [
    #("date", json.string(d.date)),
    #("entries", json.array(d.entries, food_log_entry_to_json)),
    #("total_macros", macros_to_json(d.total_macros)),
  ]

  let fields = case d.total_micronutrients {
    Some(micros) -> [#("total_micronutrients", micronutrients_to_json(micros)), ..fields]
    None -> fields
  }

  json.object(fields)
}
```

### 1.5 Update JSON Decoding

**food_log_entry_decoder** (around line 779):
```gleam
pub fn food_log_entry_decoder() -> Decoder(FoodLogEntry) {
  use id <- decode.field("id", decode.string)
  use recipe_id <- decode.field("recipe_id", decode.string)
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.field("servings", decode.float)
  use macros <- decode.field("macros", macros_decoder())
  use micronutrients <- decode.field("micronutrients", decode.optional(micronutrients_decoder()))
  use meal_type <- decode.field("meal_type", meal_type_decoder())
  use logged_at <- decode.field("logged_at", decode.string)
  decode.success(FoodLogEntry(
    id: id,
    recipe_id: recipe_id,
    recipe_name: recipe_name,
    servings: servings,
    macros: macros,
    micronutrients: micronutrients,
    meal_type: meal_type,
    logged_at: logged_at,
  ))
}
```

**daily_log_decoder** (around line 799):
```gleam
pub fn daily_log_decoder() -> Decoder(DailyLog) {
  use date <- decode.field("date", decode.string)
  use entries <- decode.field("entries", decode.list(food_log_entry_decoder()))
  use total_macros <- decode.field("total_macros", macros_decoder())
  use total_micronutrients <- decode.field("total_micronutrients", decode.optional(micronutrients_decoder()))
  decode.success(DailyLog(
    date: date,
    entries: entries,
    total_macros: total_macros,
    total_micronutrients: total_micronutrients,
  ))
}
```

---

## 2. DATABASE SCHEMA DESIGN

### 2.1 SQLite Migration

**File**: `gleam/migrations_sqlite/005_add_micronutrients_to_food_logs.sql`

```sql
-- Add micronutrient columns to food_logs table
-- All columns are nullable as not all foods have complete micronutrient data

ALTER TABLE food_logs ADD COLUMN fiber REAL NULL;
ALTER TABLE food_logs ADD COLUMN sugar REAL NULL;
ALTER TABLE food_logs ADD COLUMN sodium REAL NULL;
ALTER TABLE food_logs ADD COLUMN cholesterol REAL NULL;
ALTER TABLE food_logs ADD COLUMN vitamin_a REAL NULL;
ALTER TABLE food_logs ADD COLUMN vitamin_c REAL NULL;
ALTER TABLE food_logs ADD COLUMN vitamin_d REAL NULL;
ALTER TABLE food_logs ADD COLUMN vitamin_e REAL NULL;
ALTER TABLE food_logs ADD COLUMN vitamin_k REAL NULL;
ALTER TABLE food_logs ADD COLUMN vitamin_b6 REAL NULL;
ALTER TABLE food_logs ADD COLUMN vitamin_b12 REAL NULL;
ALTER TABLE food_logs ADD COLUMN folate REAL NULL;
ALTER TABLE food_logs ADD COLUMN thiamin REAL NULL;
ALTER TABLE food_logs ADD COLUMN riboflavin REAL NULL;
ALTER TABLE food_logs ADD COLUMN niacin REAL NULL;
ALTER TABLE food_logs ADD COLUMN calcium REAL NULL;
ALTER TABLE food_logs ADD COLUMN iron REAL NULL;
ALTER TABLE food_logs ADD COLUMN magnesium REAL NULL;
ALTER TABLE food_logs ADD COLUMN phosphorus REAL NULL;
ALTER TABLE food_logs ADD COLUMN potassium REAL NULL;
ALTER TABLE food_logs ADD COLUMN zinc REAL NULL;
```

### 2.2 PostgreSQL Migration

**File**: `gleam/migrations_pg/005_add_micronutrients_to_food_logs.sql`

```sql
-- Add micronutrient columns to food_logs table
-- All columns are nullable as not all foods have complete micronutrient data

ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS fiber REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS sugar REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS sodium REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS cholesterol REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_a REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_c REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_d REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_e REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_k REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_b6 REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_b12 REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS folate REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS thiamin REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS riboflavin REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS niacin REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS calcium REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS iron REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS magnesium REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS phosphorus REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS potassium REAL NULL;
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS zinc REAL NULL;
```

**Key Design Decisions**:
- Individual columns (not JSON blob) for efficient querying
- All columns nullable for graceful degradation
- REAL type for floating-point precision
- IF NOT EXISTS for PostgreSQL idempotency

---

## 3. STORAGE LAYER DESIGN

**File**: `gleam/src/meal_planner/storage.gleam`

### 3.1 Update FoodLog Internal Type

**Location**: Around line 691

```gleam
pub type FoodLog {
  FoodLog(
    id: String,
    date: String,
    recipe_id: String,
    recipe_name: String,
    servings: Float,
    protein: Float,
    fat: Float,
    carbs: Float,
    meal_type: String,
    logged_at: String,
    // NEW MICRONUTRIENT FIELDS
    fiber: Option(Float),
    sugar: Option(Float),
    sodium: Option(Float),
    cholesterol: Option(Float),
    vitamin_a: Option(Float),
    vitamin_c: Option(Float),
    vitamin_d: Option(Float),
    vitamin_e: Option(Float),
    vitamin_k: Option(Float),
    vitamin_b6: Option(Float),
    vitamin_b12: Option(Float),
    folate: Option(Float),
    thiamin: Option(Float),
    riboflavin: Option(Float),
    niacin: Option(Float),
    calcium: Option(Float),
    iron: Option(Float),
    magnesium: Option(Float),
    phosphorus: Option(Float),
    potassium: Option(Float),
    zinc: Option(Float),
  )
}
```

### 3.2 Update save_food_log_entry Function

**Location**: Around line 831

**Signature**:
```gleam
pub fn save_food_log_entry(
  conn: pog.Connection,
  date: String,
  entry: FoodLogEntry,
) -> Result(Nil, StorageError)
```

**SQL Statement**:
```sql
INSERT INTO food_logs
 (id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at,
  fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
  vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin,
  calcium, iron, magnesium, phosphorus, potassium, zinc)
 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(),
         $10, $11, $12, $13, $14, $15, $16, $17, $18,
         $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30)
 ON CONFLICT (id) DO UPDATE SET
   [all fields updated including micronutrients]
```

**Parameters**: 30 total (9 existing + 21 micronutrients)

### 3.3 Update get_daily_log Function

**Location**: Around line 925

**SQL Statement**:
```sql
SELECT id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at::text,
       fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
       vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin,
       calcium, iron, magnesium, phosphorus, potassium, zinc
FROM food_logs WHERE date = $1 ORDER BY logged_at
```

**Decoder**: 31 fields (10 existing + 21 micronutrients)

**Micronutrient Logic**:
```gleam
// Build micronutrients if any field is present
let micronutrients = case
  fiber, sugar, sodium, cholesterol,
  vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
  vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin,
  calcium, iron, magnesium, phosphorus, potassium, zinc
{
  None, None, None, None, None, None, None, None, None,
  None, None, None, None, None, None, None, None, None, None, None, None -> None
  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ ->
    Some(types.Micronutrients(...))
}
```

### 3.4 Add calculate_total_micronutrients Helper

**Location**: After calculate_total_macros (around line 987)

```gleam
/// Calculate total micronutrients from food log entries
fn calculate_total_micronutrients(entries: List(FoodLogEntry)) -> Option(types.Micronutrients) {
  let micros_list = list.filter_map(entries, fn(entry) {
    entry.micronutrients
  })

  case micros_list {
    [] -> None
    _ -> Some(types.micronutrients_sum(micros_list))
  }
}
```

---

## 4. ALGORITHMS

### 4.1 Save Food Log Entry Algorithm

```
1. Accept FoodLogEntry with optional micronutrients
2. Convert meal_type enum to string
3. Extract micronutrients or use micronutrients_zero()
4. Build SQL INSERT with 30 parameters:
   - Parameters 1-9: existing fields (id, date, macros, etc.)
   - Parameters 10-30: micronutrient fields
5. Use pog.nullable for all micronutrient parameters
6. ON CONFLICT updates all fields including micronutrients
7. Return Result(Nil, StorageError)
```

### 4.2 Retrieve Daily Log Algorithm

```
1. SELECT all 31 columns (10 existing + 21 micronutrients)
2. Decode each micronutrient as optional(float)
3. Check if any micronutrient field is Some:
   - If all None → micronutrients = None
   - If any Some → micronutrients = Some(Micronutrients(...))
4. Build FoodLogEntry with micronutrients field
5. Aggregate entries:
   - total_macros = calculate_total_macros(entries)
   - total_micronutrients = calculate_total_micronutrients(entries)
6. Return DailyLog with both totals
```

### 4.3 Aggregate Micronutrients Algorithm

```
micronutrients_sum(list: List(Micronutrients)) -> Micronutrients:
  1. Start with micronutrients_zero() (all None)
  2. For each micronutrient in list:
     3. Call micronutrients_add(accumulator, current)
  4. Return final accumulator

micronutrients_add(a: Micronutrients, b: Micronutrients) -> Micronutrients:
  1. For each of 21 fields:
     2. Call add_optional(a.field, b.field)
  3. Return new Micronutrients with summed values

add_optional(a: Option(Float), b: Option(Float)) -> Option(Float):
  case a, b:
    Some(va), Some(vb) -> Some(va + vb)  // Both present: sum
    Some(va), None     -> Some(va)        // Only a: keep a
    None, Some(vb)     -> Some(vb)        // Only b: keep b
    None, None         -> None            // Both absent: None
```

**Example**:
```
Entry 1: fiber=Some(5.0), vitamin_c=Some(10.0), rest=None
Entry 2: fiber=Some(3.0), iron=Some(2.0), rest=None
Entry 3: fiber=None, vitamin_c=Some(15.0), rest=None

Sum:
  fiber: Some(5.0) + Some(3.0) + None = Some(8.0)
  vitamin_c: Some(10.0) + None + Some(15.0) = Some(25.0)
  iron: None + Some(2.0) + None = Some(2.0)
  rest: None
```

---

## 5. MIGRATION STRATEGY

### 5.1 Backward Compatibility

**Guarantees**:
- Existing food_logs rows remain valid (all micronutrients = NULL)
- Queries return None for micronutrients when all NULL
- JSON encoding omits micronutrients field when None
- No breaking changes to existing API

### 5.2 Deployment Steps

```
1. Database Migration:
   - Run 005_add_micronutrients_to_food_logs.sql on SQLite
   - Run 005_add_micronutrients_to_food_logs.sql on PostgreSQL
   - Verify schema with \d food_logs

2. Type System Update:
   - Update shared/types.gleam:
     * Add micronutrients field to FoodLogEntry
     * Add total_micronutrients to DailyLog
     * Add helper functions (zero, scale, add, sum)
   - Update JSON encoding/decoding

3. Storage Layer Update:
   - Update storage.gleam:
     * Expand FoodLog internal type
     * Update save_food_log_entry (30 parameters)
     * Update get_daily_log (31 fields)
     * Add calculate_total_micronutrients

4. Testing:
   - Test with NULL micronutrients (existing data)
   - Test with partial micronutrients
   - Test with full micronutrients
   - Test aggregation across entries

5. Gradual Rollout:
   - Deploy without micronutrient data
   - Verify backward compatibility
   - Begin populating micronutrients from USDA data
```

### 5.3 Testing Strategy

**Test Cases**:

1. **Backward Compatibility**:
   - Query existing food_logs → micronutrients = None
   - Save new entry without micronutrients → NULL in DB
   - Daily log with no micronutrients → total_micronutrients = None

2. **Partial Data**:
   - Save entry with only fiber and vitamin_c
   - Verify other fields are NULL
   - Aggregate handles mix of Some/None

3. **Full Data**:
   - Save entry with all 21 micronutrients
   - Verify all fields persisted correctly
   - Aggregate sums all fields

4. **Edge Cases**:
   - Empty daily log → total_micronutrients = None
   - Single entry with micronutrients → total equals entry
   - Multiple entries with disjoint fields → union of fields

---

## 6. DATA FLOW DIAGRAM

```
┌──────────────────────────────────────────────────────────────┐
│                     Client Application                        │
│  (FoodLogEntry with micronutrients: Option(Micronutrients))  │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                  save_food_log_entry()                        │
│  - Extract micronutrients or use zero()                       │
│  - Build 30-parameter INSERT                                  │
│  - Use pog.nullable for micronutrient fields                  │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                   PostgreSQL Database                         │
│  food_logs table:                                             │
│  - 9 existing columns (id, date, macros, etc.)               │
│  - 21 micronutrient columns (fiber, sugar, vitamins, etc.)   │
│  - All micronutrients REAL NULL                               │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    get_daily_log()                            │
│  - SELECT 31 columns                                          │
│  - Decode each micronutrient as optional(float)               │
│  - Build micronutrients if any field is Some                  │
│  - Aggregate with micronutrients_sum()                        │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                     Client Application                        │
│  DailyLog with:                                               │
│  - total_macros: Macros                                       │
│  - total_micronutrients: Option(Micronutrients)              │
└──────────────────────────────────────────────────────────────┘
```

---

## 7. PERFORMANCE CONSIDERATIONS

### 7.1 Database Performance

**Benefits of Individual Columns**:
- Efficient indexing on specific micronutrients
- SQL aggregation functions (SUM, AVG) work natively
- Query planner can optimize micronutrient filters
- Partial data requires no JSON parsing

**Query Patterns**:
```sql
-- Find entries high in vitamin C
SELECT * FROM food_logs WHERE vitamin_c > 50.0;

-- Aggregate fiber for the week
SELECT SUM(fiber) FROM food_logs WHERE date BETWEEN '2025-01-01' AND '2025-01-07';

-- Find entries with complete micronutrient data
SELECT * FROM food_logs WHERE fiber IS NOT NULL AND vitamin_c IS NOT NULL ...;
```

### 7.2 Memory Usage

**Micronutrients Type Size**:
- 21 fields × (1 byte tag + 8 bytes float) = ~189 bytes when all Some
- Minimal overhead when None (just Option tags)

**Daily Log with 10 Entries**:
- Without micronutrients: ~500 bytes
- With full micronutrients: ~2.4 KB
- Acceptable for typical usage

### 7.3 Network Transfer

**JSON Size**:
```json
// Without micronutrients (existing)
{
  "id": "...",
  "macros": {...},
  ...
}
// ~200 bytes

// With full micronutrients
{
  "id": "...",
  "macros": {...},
  "micronutrients": {
    "fiber": 5.0,
    "vitamin_c": 10.0,
    ...
  }
}
// ~600 bytes (3x larger)
```

**Optimization**: Micronutrients field omitted when None, so no overhead for existing data.

---

## 8. FUTURE ENHANCEMENTS

### 8.1 Micronutrient Goals

```gleam
pub type MicronutrientGoals {
  MicronutrientGoals(
    daily_fiber: Option(Float),
    daily_vitamin_c: Option(Float),
    // ... other goals
  )
}
```

### 8.2 Micronutrient Insights

```gleam
pub fn micronutrient_deficiencies(
  consumed: Micronutrients,
  goals: MicronutrientGoals,
) -> List(String)
```

### 8.3 USDA Integration

- Fetch micronutrients from USDA FoodData Central
- Map USDA nutrient IDs to our schema
- Store in custom_foods.micronutrients

### 8.4 Analytics

```sql
-- Weekly vitamin trends
SELECT
  DATE_TRUNC('week', date::date) as week,
  AVG(vitamin_c) as avg_vitamin_c,
  AVG(fiber) as avg_fiber
FROM food_logs
GROUP BY week
ORDER BY week DESC;
```

---

## SUMMARY

This architecture provides:
- **Type Safety**: Option(Micronutrients) for partial data
- **Backward Compatibility**: All existing data works unchanged
- **Performance**: Individual columns for efficient querying
- **Scalability**: Additive migration with no data backfill
- **Flexibility**: Helper functions for scaling and aggregation
- **Maintainability**: Clear separation of concerns across layers

**Next Steps**: Phase 2C - Implementation (Create migrations, update types, modify storage layer)
