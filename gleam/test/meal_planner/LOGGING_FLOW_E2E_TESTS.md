# End-to-End Logging Flow Tests

This document describes the comprehensive E2E test suite for the meal planner logging flow.

## Test Files

### 1. `logging_flow_e2e_test.gleam`

**Purpose**: Unit tests for the complete logging flow covering all business logic

**Test Coverage**:

#### Test Group 1: Single Meal Logging
- `log_single_recipe_breakfast_test()` - Log a single recipe at breakfast
- `log_recipe_with_scaled_servings_test()` - Log recipe with 1.5 servings
- `log_usda_food_with_grams_test()` - Log USDA food by grams (150g chicken)

#### Test Group 2: Multiple Meals in One Day
- `log_complete_day_test()` - Log breakfast, lunch, dinner, snack (4 entries)
- `log_same_recipe_multiple_times_test()` - Log same recipe twice in one day

#### Test Group 3: Source Tracking
- `recipe_source_tracking_test()` - Verify recipe sources are tracked
- `usda_food_source_tracking_test()` - Verify USDA sources (FDC ID) are tracked
- `entry_has_complete_source_fields_test()` - All source fields present

#### Test Group 4: Macro Calculations
- `macro_scaling_proportional_test()` - Verify proportional scaling (1x vs 2x)
- `daily_macro_totals_calculation_test()` - Sum macros across 3 entries
- `zero_serving_macros_test()` - Handle zero-calorie items

#### Test Group 5: Meal Type Distribution
- `entries_assigned_correct_meal_types_test()` - 4 meal types distributed correctly
- `multiple_entries_same_meal_type_test()` - Multiple snacks in one day

#### Test Group 6: Entry Timestamps and Logging
- `entry_has_valid_timestamp_test()` - ISO format timestamps
- `daily_log_has_date_test()` - Date information present

#### Test Group 7: Edge Cases
- `fractional_serving_size_test()` - Log 0.1 servings
- `large_serving_size_test()` - Log 3.0 servings
- `empty_daily_log_test()` - Handle empty log
- `single_entry_daily_log_test()` - Handle single entry

#### Test Group 8: Complete E2E Flow Scenarios
- `e2e_search_select_log_usda_food_test()` - Full flow: search → select → log USDA food
- `e2e_recipe_creation_and_logging_test()` - Create recipe → log with scaling
- `e2e_complete_day_logging_test()` - Full day: 5 entries across meal types
- `e2e_modify_meal_add_second_portion_test()` - Add second portion and verify totals

### 2. `logging_flow_api_integration_test.gleam`

**Purpose**: API handler and integration tests for logging endpoints

**Test Coverage**:

#### Search Query Validation (5 tests)
- Minimum length requirement (2 characters)
- Valid query acceptance
- Whitespace trimming
- Maximum length limit
- Special character handling

#### Search Filter Validation (8 tests)
- Boolean filter: true/false values
- Boolean filter: numeric (1/0) values
- Case-insensitive filter parsing
- Invalid filter value error handling

#### Filter Combination Tests (8 tests)
- All filters default
- Verified only filter
- Branded only filter
- Category filter
- Combined filters (all 3)
- Empty category handling
- "all" category as None

#### Food Search Response Structure (2 tests)
- Search results structure validation
- Filter application verification

#### Logging Request Validation (6 tests)
- Recipe logging: valid parameters
- Recipe logging: missing recipe_id
- Recipe logging: invalid servings
- USDA logging: valid parameters
- USDA logging: missing fdc_id
- USDA logging: invalid grams

#### Logging Response Validation (2 tests)
- Successful response structure
- Failed response error messages

#### Data Persistence Tests (3 tests)
- Entry persists to database
- Multiple entries sum correctly
- Entry date recorded correctly

#### Source Tracking in API (2 tests)
- Recipe source tracking in response
- USDA source tracking in response

#### Error Handling (4 tests)
- Nonexistent recipe returns 404
- Nonexistent USDA food returns 404
- Database error returns 500
- Invalid meal type handling

#### End-to-End Request/Response (3 tests)
- Search API response headers
- Logging API redirect behavior
- Daily log endpoint aggregation

#### Macro Calculation Accuracy (2 tests)
- Recipe macro scaling accuracy
- USDA macro scaling accuracy

#### Performance and Reliability (3 tests)
- Search API performance
- Concurrent logging requests
- Daily totals calculation performance

## Test Workflow

### Complete User Journey

```
1. SEARCH PHASE
   User types "chicken"
   └─ API validates query (min 2 chars, max 255 chars)
   └─ API filters by (verified_only, branded_only, category)
   └─ API returns list of foods

2. SELECT PHASE
   User selects "Chicken Breast"
   └─ API loads USDA food details (31g protein, 3.6g fat per 100g)
   └─ UI displays nutrition info

3. INPUT PHASE
   User enters 150g portion size
   └─ API calculates scaling factor (150 / 100 = 1.5)
   └─ API calculates scaled macros (46.5g protein, 5.4g fat)

4. CONFIRM PHASE
   User selects "Lunch" meal type
   └─ API validates meal_type is valid

5. LOG PHASE
   User clicks "Save to Log"
   └─ POST /api/logs/food with JSON body
   └─ API creates FoodLogEntry
   └─ API saves to database
   └─ API returns entry details or redirects

6. DISPLAY PHASE
   User views dashboard
   └─ GET /api/logs or /dashboard
   └─ API retrieves daily log for today
   └─ API sums all entries → daily totals
   └─ UI displays all meals + daily totals
```

## Running the Tests

### Run all E2E tests
```bash
cd gleam
gleam test logging_flow_e2e_test
```

### Run all API integration tests
```bash
cd gleam
gleam test logging_flow_api_integration_test
```

### Run both test suites
```bash
cd gleam
gleam test
# Or filter:
gleam test | grep "logging_flow"
```

## Test Data Patterns

### Single Recipe
```gleam
Recipe(
  id: "recipe-1",
  name: "Chicken Salad",
  macros: Macros(protein: 35.0, fat: 8.0, carbs: 0.0),
  ...
)

// Logged with 1.5 servings:
FoodLogEntry(
  servings: 1.5,
  macros: Macros(protein: 52.5, fat: 12.0, carbs: 0.0),
  source_type: "recipe",
  source_id: "recipe-1",
  ...
)
```

### USDA Food
```gleam
// USDA: Chicken Breast (per 100g)
// 165 kcal, 31g protein, 3.6g fat

// User logs 150g:
FoodLogEntry(
  servings: 1.5,  // 150g / 100g
  macros: Macros(protein: 46.5, fat: 5.4, carbs: 0.0),
  source_type: "usda_food",
  source_id: "171477",  // FDC ID
  ...
)
```

### Daily Log Aggregation
```gleam
DailyLog(
  date: "2025-12-05",
  entries: [
    FoodLogEntry(..., macros: Macros(30.0, 10.0, 50.0), ...),  // Breakfast
    FoodLogEntry(..., macros: Macros(52.5, 12.0, 45.0), ...),  // Lunch
    FoodLogEntry(..., macros: Macros(40.0, 10.0, 60.0), ...),  // Dinner
  ],
  daily_totals: Macros(protein: 122.5, fat: 32.0, carbs: 155.0)
)
```

## Key Assertions

### Macro Scaling
```gleam
// Single serving: 35g protein
// 1.5 servings: 35 * 1.5 = 52.5g protein
entry.macros.protein |> should.equal(52.5)
```

### Source Tracking
```gleam
// Recipe source
entry.source_type |> should.equal("recipe")
entry.source_id |> should.equal(recipe.id)

// USDA source
entry.source_type |> should.equal("usda_food")
entry.source_id |> should.equal("171477")  // FDC ID as string
```

### Daily Totals
```gleam
// Three entries: 30, 40, 25g protein
daily_log.daily_totals.protein |> should.equal(95.0)
```

### Entry Retrieval
```gleam
// Filter entries by meal type
let breakfast_entries = list.filter(
  daily_log.entries,
  fn(e) { e.meal_type == Breakfast }
)
list.length(breakfast_entries) |> should.equal(1)
```

## Edge Cases Covered

1. **Zero Servings** - Valid for zero-calorie items
2. **Fractional Servings** - 0.1 servings (expensive spice)
3. **Large Servings** - 3.0 servings (sharing a meal)
4. **Small Gram Amounts** - 10g (sauce, dressing)
5. **Large Gram Amounts** - 300g (main dish)
6. **Empty Daily Log** - No entries for a date
7. **Multiple Same Recipe** - Same recipe logged twice
8. **Mixed Sources** - Both recipe and USDA food in same day

## Performance Considerations

- **Search**: Should complete within 1 second, even with 100k+ foods
- **Logging**: Should complete within 500ms, including macro calculation
- **Daily Totals**: Should calculate instantly, even with 30+ entries
- **Concurrent Requests**: Multiple users logging simultaneously should not interfere

## Future Enhancements

1. **Custom Food Support** - Allow users to create custom foods
2. **Food Editing** - Modify logged entry (change servings, meal type)
3. **Food Deletion** - Remove logged entry
4. **Micronutrient Tracking** - Full micronutrient logging and totals
5. **Export/Import** - Export daily logs as CSV/PDF
6. **Mobile API** - Mobile-optimized endpoints
7. **Real-time Updates** - WebSocket for dashboard updates
8. **Barcode Scanning** - Scan barcode to find food

## Test Maintenance

- Update tests whenever logging flow changes
- Add new test cases for new features
- Verify edge cases before release
- Run full test suite before merging PRs
- Monitor test performance (should complete in < 5 seconds)

## Related Files

- `/gleam/src/meal_planner/storage.gleam` - Database functions
- `/gleam/src/meal_planner/web/handlers/food_log.gleam` - Logging endpoints
- `/gleam/src/meal_planner/web/handlers/search.gleam` - Search endpoints
- `/gleam/src/meal_planner/types.gleam` - Type definitions
