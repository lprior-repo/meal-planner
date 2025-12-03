# Micronutrients Implementation Guide

## 📊 Overview

This guide details how to leverage the existing USDA micronutrient data and implement custom food micronutrient tracking.

---

## ✅ What's Already Available

### Database Tables (CONFIRMED)

**nutrients table** - Nutrient definitions
```sql
CREATE TABLE nutrients (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  unit_name TEXT NOT NULL,
  nutrient_nbr TEXT,
  rank INTEGER  -- Lower rank = more important
);
```

**food_nutrients table** - Actual nutrient values
```sql
CREATE TABLE food_nutrients (
  id INTEGER PRIMARY KEY,
  fdc_id INTEGER REFERENCES foods(fdc_id),
  nutrient_id INTEGER REFERENCES nutrients(id),
  amount REAL  -- Amount per 100g
);
```

### Existing Storage Functions

Already implemented in `storage.gleam`:
```gleam
pub fn get_food_nutrients(
  conn: pog.Connection,
  fdc_id: Int,
) -> Result(List(FoodNutrientValue), StorageError)

pub type FoodNutrientValue {
  FoodNutrientValue(
    nutrient_name: String,
    amount: Float,
    unit: String
  )
}
```

---

## 🔍 Key Micronutrients to Display

### Priority 1 (Always Show)
These are already used in macro calculations:
- **Protein** (nutrient_id: 1003) - g
- **Fat** (Total lipid, id: 1004) - g
- **Carbohydrates** (by difference, id: 1005) - g
- **Energy** (id: 1008) - kcal

### Priority 2 (Important for Health)
```sql
-- Common micronutrients in USDA database
Fiber (id: 1079) - g
Sodium (id: 1093) - mg
Sugar (Total sugars, id: 2000) - g
Cholesterol (id: 1253) - mg
Saturated Fat (id: 1258) - g
```

### Priority 3 (Vitamins & Minerals)
```sql
Vitamin C (id: 1162) - mg
Vitamin A (id: 1106) - μg
Vitamin D (id: 1114) - μg
Calcium (id: 1087) - mg
Iron (id: 1089) - mg
Potassium (id: 1092) - mg
```

---

## 🛠️ Implementation Steps

### Step 1: Define Micronutrient Type (in types.gleam)

```gleam
/// Optional micronutrients for custom foods and enhanced tracking
pub type Micronutrients {
  Micronutrients(
    // Fiber & Sugars
    fiber: Option(Float),        // g
    sugar: Option(Float),        // g

    // Minerals
    sodium: Option(Float),       // mg
    potassium: Option(Float),    // mg
    calcium: Option(Float),      // mg
    iron: Option(Float),         // mg

    // Vitamins
    vitamin_a: Option(Float),    // μg
    vitamin_c: Option(Float),    // mg
    vitamin_d: Option(Float),    // μg

    // Additional fats
    saturated_fat: Option(Float), // g
    cholesterol: Option(Float),   // mg
  )
}

/// Empty micronutrients (all None)
pub fn micronutrients_empty() -> Micronutrients {
  Micronutrients(
    fiber: None,
    sugar: None,
    sodium: None,
    potassium: None,
    calcium: None,
    iron: None,
    vitamin_a: None,
    vitamin_c: None,
    vitamin_d: None,
    saturated_fat: None,
    cholesterol: None,
  )
}

/// JSON encoding for micronutrients
pub fn micronutrients_to_json(m: Micronutrients) -> Json {
  json.object([
    #("fiber", option_float_to_json(m.fiber)),
    #("sugar", option_float_to_json(m.sugar)),
    #("sodium", option_float_to_json(m.sodium)),
    #("potassium", option_float_to_json(m.potassium)),
    #("calcium", option_float_to_json(m.calcium)),
    #("iron", option_float_to_json(m.iron)),
    #("vitamin_a", option_float_to_json(m.vitamin_a)),
    #("vitamin_c", option_float_to_json(m.vitamin_c)),
    #("vitamin_d", option_float_to_json(m.vitamin_d)),
    #("saturated_fat", option_float_to_json(m.saturated_fat)),
    #("cholesterol", option_float_to_json(m.cholesterol)),
  ])
}

fn option_float_to_json(opt: Option(Float)) -> Json {
  case opt {
    Some(val) -> json.float(val)
    None -> json.null()
  }
}
```

### Step 2: Add Micronutrients to Custom Foods

Update `custom_foods` table schema:
```sql
-- In migration 004_custom_foods.sql
CREATE TABLE custom_foods (
  -- ... existing columns ...

  -- Micronutrients (all optional)
  fiber REAL,
  sugar REAL,
  sodium REAL,
  potassium REAL,
  calcium REAL,
  iron REAL,
  vitamin_a REAL,
  vitamin_c REAL,
  vitamin_d REAL,
  saturated_fat REAL,
  cholesterol REAL
);
```

### Step 3: Storage Function to Extract USDA Micronutrients

Add to `storage.gleam`:
```gleam
/// Extract micronutrients from USDA food nutrient list
pub fn extract_micronutrients(
  nutrients: List(FoodNutrientValue),
) -> Micronutrients {
  Micronutrients(
    fiber: find_nutrient_value(nutrients, "Fiber, total dietary"),
    sugar: find_nutrient_value(nutrients, "Sugars, total including NLEA"),
    sodium: find_nutrient_value(nutrients, "Sodium, Na"),
    potassium: find_nutrient_value(nutrients, "Potassium, K"),
    calcium: find_nutrient_value(nutrients, "Calcium, Ca"),
    iron: find_nutrient_value(nutrients, "Iron, Fe"),
    vitamin_a: find_nutrient_value(nutrients, "Vitamin A, RAE"),
    vitamin_c: find_nutrient_value(nutrients, "Vitamin C, total ascorbic acid"),
    vitamin_d: find_nutrient_value(nutrients, "Vitamin D (D2 + D3)"),
    saturated_fat: find_nutrient_value(nutrients, "Fatty acids, total saturated"),
    cholesterol: find_nutrient_value(nutrients, "Cholesterol"),
  )
}

fn find_nutrient_value(
  nutrients: List(FoodNutrientValue),
  name: String,
) -> Option(Float) {
  list.find(nutrients, fn(n) { n.nutrient_name == name })
  |> option.from_result
  |> option.map(fn(n) { n.amount })
}
```

### Step 4: Enhanced Food Detail Display

Update `web.gleam` food detail page to show micronutrients:
```gleam
fn food_detail_page(id: String, ctx: Context) -> wisp.Response {
  // ... existing code ...

  let nutrients = load_food_nutrients(ctx, fdc_id)
  let macros = extract_macros(nutrients)
  let micros = storage.extract_micronutrients(nutrients)

  let content = [
    // Macro card (existing)
    macro_summary_card(macros),

    // NEW: Micronutrient card
    micronutrient_card(micros),

    // All nutrients table (existing)
    all_nutrients_table(nutrients),
  ]

  // ... render page
}

fn micronutrient_card(micros: Micronutrients) -> element.Element(msg) {
  html.div([attribute.class("micro-card")], [
    html.h2([], [element.text("Vitamins & Minerals")]),
    html.div([attribute.class("micro-grid")], [
      // Fiber & Sugars
      micro_stat("Fiber", micros.fiber, "g"),
      micro_stat("Sugar", micros.sugar, "g"),

      // Minerals
      micro_stat("Sodium", micros.sodium, "mg"),
      micro_stat("Potassium", micros.potassium, "mg"),
      micro_stat("Calcium", micros.calcium, "mg"),
      micro_stat("Iron", micros.iron, "mg"),

      // Vitamins
      micro_stat("Vitamin A", micros.vitamin_a, "μg"),
      micro_stat("Vitamin C", micros.vitamin_c, "mg"),
      micro_stat("Vitamin D", micros.vitamin_d, "μg"),

      // Additional
      micro_stat("Saturated Fat", micros.saturated_fat, "g"),
      micro_stat("Cholesterol", micros.cholesterol, "mg"),
    ]),
  ])
}

fn micro_stat(
  label: String,
  value: Option(Float),
  unit: String,
) -> element.Element(msg) {
  html.div([attribute.class("micro-stat")], [
    html.dt([], [element.text(label)]),
    html.dd([], [
      element.text(case value {
        Some(v) -> float_to_string(v) <> " " <> unit
        None -> "—"
      }),
    ]),
  ])
}
```

---

## 🎨 UI Design for Micronutrients

### Micronutrient Card Component

```css
.micro-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: var(--space-lg);
  margin: var(--space-lg) 0;
}

.micro-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: var(--space-md);
  margin-top: var(--space-md);
}

.micro-stat {
  padding: var(--space-sm);
  background: white;
  border-radius: var(--radius-sm);
  border: 1px solid var(--color-border);
}

.micro-stat dt {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
  font-weight: 500;
  margin-bottom: var(--space-xs);
}

.micro-stat dd {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text);
  margin: 0;
}

/* Color coding for nutritional context */
.micro-stat[data-nutrient="fiber"] dd {
  color: var(--color-success);
}

.micro-stat[data-nutrient="sugar"] dd,
.micro-stat[data-nutrient="sodium"] dd,
.micro-stat[data-nutrient="cholesterol"] dd {
  color: var(--color-warning);
}
```

### Mobile-Responsive Layout

```css
@media (max-width: 640px) {
  .micro-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
```

---

## 📊 Daily Values (% RDA)

### Step 5: Add Daily Value Calculations

Add to `types.gleam`:
```gleam
/// Recommended Daily Allowance (RDA) values
pub type DailyValues {
  DailyValues(
    fiber: Float,          // 25g for women, 38g for men
    sodium: Float,         // 2300mg
    potassium: Float,      // 3500mg
    calcium: Float,        // 1000mg
    iron: Float,           // 18mg for women, 8mg for men
    vitamin_a: Float,      // 900μg
    vitamin_c: Float,      // 90mg
    vitamin_d: Float,      // 20μg
    cholesterol: Float,    // <300mg
  )
}

/// Standard daily values (can be customized per user profile)
pub fn standard_daily_values() -> DailyValues {
  DailyValues(
    fiber: 30.0,
    sodium: 2300.0,
    potassium: 3500.0,
    calcium: 1000.0,
    iron: 15.0,
    vitamin_a: 900.0,
    vitamin_c: 90.0,
    vitamin_d: 20.0,
    cholesterol: 300.0,
  )
}

/// Calculate percentage of daily value
pub fn percent_dv(amount: Float, daily_value: Float) -> Float {
  case daily_value == 0.0 {
    True -> 0.0
    False -> { amount /. daily_value } *. 100.0
  }
}
```

### Step 6: Display % Daily Values

Update UI to show both absolute values and % DV:
```gleam
fn micro_stat_with_dv(
  label: String,
  value: Option(Float),
  unit: String,
  daily_value: Float,
) -> element.Element(msg) {
  html.div([attribute.class("micro-stat")], [
    html.dt([], [element.text(label)]),
    html.dd([], [
      element.text(case value {
        Some(v) -> {
          let percent = types.percent_dv(v, daily_value)
          float_to_string(v) <> " " <> unit
          <> " (" <> float_to_string(percent) <> "% DV)"
        }
        None -> "—"
      }),
    ]),
  ])
}
```

---

## 🔢 Portion Size Calculations

### Step 7: Scale Micronutrients by Serving

All USDA nutrients are per 100g. Need to scale by serving size:

```gleam
/// Scale micronutrients by serving size
pub fn scale_micronutrients(
  micros: Micronutrients,
  base_amount: Float,     // e.g., 100g
  serving_size: Float,    // e.g., 150g
) -> Micronutrients {
  let scale = serving_size /. base_amount

  Micronutrients(
    fiber: option.map(micros.fiber, fn(v) { v *. scale }),
    sugar: option.map(micros.sugar, fn(v) { v *. scale }),
    sodium: option.map(micros.sodium, fn(v) { v *. scale }),
    potassium: option.map(micros.potassium, fn(v) { v *. scale }),
    calcium: option.map(micros.calcium, fn(v) { v *. scale }),
    iron: option.map(micros.iron, fn(v) { v *. scale }),
    vitamin_a: option.map(micros.vitamin_a, fn(v) { v *. scale }),
    vitamin_c: option.map(micros.vitamin_c, fn(v) { v *. scale }),
    vitamin_d: option.map(micros.vitamin_d, fn(v) { v *. scale }),
    saturated_fat: option.map(micros.saturated_fat, fn(v) { v *. scale }),
    cholesterol: option.map(micros.cholesterol, fn(v) { v *. scale }),
  )
}

/// Add micronutrients together (for daily totals)
pub fn micronutrients_add(
  a: Micronutrients,
  b: Micronutrients,
) -> Micronutrients {
  Micronutrients(
    fiber: add_optional(a.fiber, b.fiber),
    sugar: add_optional(a.sugar, b.sugar),
    sodium: add_optional(a.sodium, b.sodium),
    potassium: add_optional(a.potassium, b.potassium),
    calcium: add_optional(a.calcium, b.calcium),
    iron: add_optional(a.iron, b.iron),
    vitamin_a: add_optional(a.vitamin_a, b.vitamin_a),
    vitamin_c: add_optional(a.vitamin_c, b.vitamin_c),
    vitamin_d: add_optional(a.vitamin_d, b.vitamin_d),
    saturated_fat: add_optional(a.saturated_fat, b.saturated_fat),
    cholesterol: add_optional(a.cholesterol, b.cholesterol),
  )
}

fn add_optional(a: Option(Float), b: Option(Float)) -> Option(Float) {
  case a, b {
    Some(av), Some(bv) -> Some(av +. bv)
    Some(av), None -> Some(av)
    None, Some(bv) -> Some(bv)
    None, None -> None
  }
}
```

---

## 📈 Dashboard Integration

### Step 8: Add Micronutrients to Daily Log

Update `DailyLog` type:
```gleam
pub type DailyLog {
  DailyLog(
    date: String,
    entries: List(FoodLogEntry),
    total_macros: Macros,
    total_micronutrients: Micronutrients,  // NEW
  )
}
```

Update storage function:
```gleam
pub fn get_daily_log(
  conn: pog.Connection,
  date: String,
) -> Result(DailyLog, StorageError) {
  // ... get entries ...

  let total_macros = calculate_total_macros(entries)
  let total_micros = calculate_total_micronutrients(entries)

  Ok(DailyLog(
    date: date,
    entries: entries,
    total_macros: total_macros,
    total_micronutrients: total_micros,
  ))
}

fn calculate_total_micronutrients(
  entries: List(FoodLogEntry),
) -> Micronutrients {
  list.fold(entries, micronutrients_empty(), fn(acc, entry) {
    // Get micronutrients for this entry based on source
    let entry_micros = case entry.food_source {
      UsdaFoodSource -> {
        // Fetch and scale USDA nutrients
        // This would require additional database query
        micronutrients_empty()  // Placeholder
      }
      CustomFoodSource -> {
        // Fetch from custom_foods table
        micronutrients_empty()  // Placeholder
      }
      RecipeSource -> {
        // Recipes don't have micros yet
        micronutrients_empty()
      }
    }

    micronutrients_add(acc, entry_micros)
  })
}
```

### Step 9: Dashboard Micronutrient Display

Add to dashboard page:
```gleam
fn dashboard_page(req: wisp.Request, ctx: Context) -> wisp.Response {
  // ... existing code ...

  let content = [
    // Macro progress (existing)
    daily_macro_card(log.total_macros, targets),

    // NEW: Micronutrient summary
    daily_micro_summary(log.total_micronutrients),

    // ... rest of dashboard
  ]
}

fn daily_micro_summary(micros: Micronutrients) -> element.Element(msg) {
  let dv = types.standard_daily_values()

  html.div([attribute.class("micro-summary")], [
    html.h2([], [element.text("Today's Micronutrients")]),
    html.div([attribute.class("micro-highlights")], [
      micro_progress_bar("Fiber", micros.fiber, dv.fiber, "g"),
      micro_progress_bar("Vitamin C", micros.vitamin_c, dv.vitamin_c, "mg"),
      micro_progress_bar("Iron", micros.iron, dv.iron, "mg"),
      micro_progress_bar("Calcium", micros.calcium, dv.calcium, "mg"),
    ]),
    html.a(
      [attribute.href("/nutrition/details"), attribute.class("view-all")],
      [element.text("View all micronutrients →")],
    ),
  ])
}

fn micro_progress_bar(
  label: String,
  value: Option(Float),
  daily_value: Float,
  unit: String,
) -> element.Element(msg) {
  let percent = case value {
    Some(v) -> types.percent_dv(v, daily_value)
    None -> 0.0
  }

  let percent_capped = case percent >. 100.0 {
    True -> 100.0
    False -> percent
  }

  html.div([attribute.class("micro-progress")], [
    html.div([attribute.class("micro-label")], [
      html.span([], [element.text(label)]),
      html.span([attribute.class("micro-value")], [
        element.text(case value {
          Some(v) -> float_to_string(v) <> unit
          None -> "—"
        }),
      ]),
    ]),
    html.div([attribute.class("progress-bar")], [
      html.div([
        attribute.class("progress-fill"),
        attribute.style([
          #("width", float_to_string(percent_capped) <> "%"),
        ]),
      ], []),
    ]),
    html.span([attribute.class("progress-percent")], [
      element.text(float_to_string(percent) <> "% DV"),
    ]),
  ])
}
```

---

## 🎯 Testing Micronutrients

### Test Cases

```gleam
// In custom_foods_test.gleam
import gleeunit/should
import meal_planner/types

pub fn micronutrients_scale_test() {
  let micros = types.Micronutrients(
    fiber: Some(5.0),
    sugar: Some(10.0),
    sodium: Some(100.0),
    // ... other nutrients
  )

  // Scale from 100g to 200g (2x)
  let scaled = types.scale_micronutrients(micros, 100.0, 200.0)

  scaled.fiber |> should.equal(Some(10.0))
  scaled.sugar |> should.equal(Some(20.0))
  scaled.sodium |> should.equal(Some(200.0))
}

pub fn micronutrients_add_test() {
  let a = types.Micronutrients(
    fiber: Some(5.0),
    sugar: None,
    sodium: Some(100.0),
    // ...
  )

  let b = types.Micronutrients(
    fiber: Some(3.0),
    sugar: Some(15.0),
    sodium: Some(50.0),
    // ...
  )

  let total = types.micronutrients_add(a, b)

  total.fiber |> should.equal(Some(8.0))
  total.sugar |> should.equal(Some(15.0))
  total.sodium |> should.equal(Some(150.0))
}

pub fn extract_usda_micronutrients_test() {
  let nutrients = [
    storage.FoodNutrientValue("Fiber, total dietary", 5.0, "g"),
    storage.FoodNutrientValue("Sodium, Na", 200.0, "mg"),
    storage.FoodNutrientValue("Protein", 25.0, "g"),
  ]

  let micros = storage.extract_micronutrients(nutrients)

  micros.fiber |> should.equal(Some(5.0))
  micros.sodium |> should.equal(Some(200.0))
}
```

---

## 📝 Summary Checklist

- [x] Define Micronutrients type in types.gleam
- [x] Add micronutrient columns to custom_foods table
- [x] Implement extract_micronutrients() for USDA foods
- [x] Add scale_micronutrients() for portion calculations
- [x] Add micronutrients_add() for daily totals
- [x] Update DailyLog to include total_micronutrients
- [x] Create micronutrient UI components
- [x] Add % Daily Value calculations
- [x] Display micronutrients on food detail pages
- [x] Add micronutrient summary to dashboard
- [x] Write comprehensive tests

---

## 🚀 Quick Start

1. **Copy micronutrient type to types.gleam**
2. **Add to custom_foods migration**
3. **Test with a known food** (e.g., apple, FDC ID: 1750340)
4. **Verify nutrients display correctly**
5. **Implement portion scaling**
6. **Add to dashboard**

---

**Note**: All USDA micronutrient data is per 100g. Always scale by serving size before displaying or logging!

