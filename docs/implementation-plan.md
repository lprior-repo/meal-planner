# Meal Planner Implementation Plan

## Executive Summary

This plan details the implementation of custom food entry, comprehensive food search, food logging, and UI/UX redesign for the Gleam meal planner application. The work is broken down into atomic, testable beads (issues) with clear dependencies and priorities.

---

## Current System Analysis

### Existing Architecture
- **Backend**: Gleam with Wisp web framework
- **Database**: PostgreSQL with pog library
- **Frontend**: Server-side rendering with Lustre (Gleam HTML)
- **USDA Database**:
  - `foods` table: 400K+ food items with full-text search (GIN index)
  - `nutrients` table: Nutrient definitions
  - `food_nutrients` table: Nutrient values per food (micronutrients CONFIRMED available)

### Database Schema Overview
```sql
-- USDA Tables (existing)
foods (fdc_id, description, data_type, food_category)
nutrients (id, name, unit_name, rank)
food_nutrients (fdc_id, nutrient_id, amount)

-- App Tables (existing)
recipes (id, name, ingredients, macros, servings, etc.)
food_logs (id, date, recipe_id, servings, macros, meal_type)
user_profile (id, bodyweight, activity_level, goal)
nutrition_state (date, protein, fat, carbs, calories)
```

### Existing Storage Functions
✅ Already implemented:
- `search_foods()` - USDA food search with full-text
- `get_food_by_id()` - Single USDA food lookup
- `get_food_nutrients()` - Micronutrient retrieval (CONFIRMED)
- `save_food_log()` - Log food entries
- `get_food_logs_by_date()` - Daily log retrieval
- `delete_food_log()` - Remove log entries

❌ Missing:
- Custom food CRUD operations
- Unified search across USDA + custom foods
- Food-to-log conversion (currently recipe-only)

---

## Implementation Plan - Organized by Feature Area

## 🗄️ PHASE 1: Backend - Custom Foods Database Layer

### Bead 1.1: Database Migration for Custom Foods
**Priority**: P0 (Critical - Foundation)
**Dependencies**: None
**Estimated Effort**: 2 hours

**Technical Approach**:
- Create migration file: `004_custom_foods.sql`
- Add `custom_foods` table with schema:
  ```sql
  CREATE TABLE custom_foods (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL DEFAULT '1',
    name TEXT NOT NULL,
    description TEXT,
    serving_size REAL NOT NULL,
    serving_unit TEXT NOT NULL,
    protein REAL NOT NULL,
    fat REAL NOT NULL,
    carbs REAL NOT NULL,
    calories REAL NOT NULL,
    -- Micronutrients (optional)
    fiber REAL,
    sodium REAL,
    sugar REAL,
    vitamin_c REAL,
    iron REAL,
    calcium REAL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );
  CREATE INDEX idx_custom_foods_user ON custom_foods(user_id);
  CREATE INDEX idx_custom_foods_name ON custom_foods USING gin(to_tsvector('english', name));
  ```

**Files to Create**:
- `/gleam/migrations_pg/004_custom_foods.sql`

**Test Strategy**:
- Run migration against test database
- Verify indexes created
- Test full-text search on custom foods

---

### Bead 1.2: CustomFood Type Definition
**Priority**: P0 (Critical)
**Dependencies**: Bead 1.1
**Estimated Effort**: 1 hour

**Technical Approach**:
- Add to `gleam/src/meal_planner/types.gleam`:
  ```gleam
  pub type CustomFood {
    CustomFood(
      id: String,
      user_id: String,
      name: String,
      description: Option(String),
      serving_size: Float,
      serving_unit: String,
      macros: Macros,
      micronutrients: Option(Micronutrients),
      created_at: String,
      updated_at: String,
    )
  }

  pub type Micronutrients {
    Micronutrients(
      fiber: Option(Float),
      sodium: Option(Float),
      sugar: Option(Float),
      vitamin_c: Option(Float),
      iron: Option(Float),
      calcium: Option(Float),
    )
  }
  ```
- Add JSON encoders/decoders
- Add validation helpers

**Files to Modify**:
- `/gleam/src/meal_planner/types.gleam` (add ~100 lines)

**Test Strategy**:
- Unit tests for type constructors
- JSON round-trip tests (encode → decode)
- Validation edge cases

---

### Bead 1.3: Custom Food Storage Functions
**Priority**: P0 (Critical)
**Dependencies**: Bead 1.2
**Estimated Effort**: 4 hours

**Technical Approach**:
- Add to `gleam/src/meal_planner/storage.gleam`:
  ```gleam
  // CRUD operations
  pub fn create_custom_food(conn: pog.Connection, food: CustomFood) -> Result(Nil, StorageError)
  pub fn update_custom_food(conn: pog.Connection, food: CustomFood) -> Result(Nil, StorageError)
  pub fn delete_custom_food(conn: pog.Connection, id: String) -> Result(Nil, StorageError)
  pub fn get_custom_food_by_id(conn: pog.Connection, id: String) -> Result(CustomFood, StorageError)

  // Search and listing
  pub fn search_custom_foods(conn: pog.Connection, user_id: String, query: String, limit: Int) -> Result(List(CustomFood), StorageError)
  pub fn get_user_custom_foods(conn: pog.Connection, user_id: String) -> Result(List(CustomFood), StorageError)
  ```
- Use prepared statements with pog
- Implement full-text search on name field

**Files to Modify**:
- `/gleam/src/meal_planner/storage.gleam` (add ~200 lines)

**Test Strategy**:
- Create/read/update/delete tests
- Search functionality tests
- Error handling (not found, constraint violations)

---

### Bead 1.4: Unified Food Search
**Priority**: P1 (Important)
**Dependencies**: Bead 1.3
**Estimated Effort**: 3 hours

**Technical Approach**:
- Add to `storage.gleam`:
  ```gleam
  pub type SearchableFood {
    UsdaFoodResult(UsdaFood)
    CustomFoodResult(CustomFood)
  }

  pub fn search_all_foods(
    conn: pog.Connection,
    user_id: String,
    query: String,
    limit: Int
  ) -> Result(List(SearchableFood), StorageError) {
    // Execute both searches in parallel
    // Merge results with custom foods first
    // Limit total results
  }
  ```
- Prioritize custom foods in results
- Add relevance scoring

**Files to Modify**:
- `/gleam/src/meal_planner/storage.gleam` (add ~80 lines)

**Test Strategy**:
- Test with USDA-only matches
- Test with custom-only matches
- Test with mixed results
- Verify ordering (custom first)

---

## 🍽️ PHASE 2: Backend - Food Logging Enhancement

### Bead 2.1: Update Food Log Schema
**Priority**: P0 (Critical)
**Dependencies**: Bead 1.1
**Estimated Effort**: 1 hour

**Technical Approach**:
- Create migration: `005_enhance_food_logs.sql`
  ```sql
  ALTER TABLE food_logs ADD COLUMN food_source TEXT NOT NULL DEFAULT 'recipe';
  ALTER TABLE food_logs ADD COLUMN fdc_id INTEGER;
  ALTER TABLE food_logs ADD COLUMN custom_food_id TEXT;
  ALTER TABLE food_logs ADD COLUMN serving_size REAL;
  ALTER TABLE food_logs ADD COLUMN serving_unit TEXT;

  -- Add foreign key constraints
  ALTER TABLE food_logs ADD CONSTRAINT fk_fdc_id
    FOREIGN KEY (fdc_id) REFERENCES foods(fdc_id) ON DELETE SET NULL;
  ALTER TABLE food_logs ADD CONSTRAINT fk_custom_food
    FOREIGN KEY (custom_food_id) REFERENCES custom_foods(id) ON DELETE CASCADE;

  -- Check constraint: exactly one source must be set
  ALTER TABLE food_logs ADD CONSTRAINT chk_food_source
    CHECK (
      (food_source = 'recipe' AND recipe_id IS NOT NULL AND fdc_id IS NULL AND custom_food_id IS NULL) OR
      (food_source = 'usda' AND fdc_id IS NOT NULL AND recipe_id IS NULL AND custom_food_id IS NULL) OR
      (food_source = 'custom' AND custom_food_id IS NOT NULL AND recipe_id IS NULL AND fdc_id IS NULL)
    );
  ```

**Files to Create**:
- `/gleam/migrations_pg/005_enhance_food_logs.sql`

**Test Strategy**:
- Test constraint enforcement
- Verify backward compatibility with existing logs

---

### Bead 2.2: Enhanced FoodLogEntry Type
**Priority**: P0 (Critical)
**Dependencies**: Bead 2.1, Bead 1.2
**Estimated Effort**: 2 hours

**Technical Approach**:
- Update `types.gleam`:
  ```gleam
  pub type FoodSource {
    RecipeSource
    UsdaFoodSource
    CustomFoodSource
  }

  pub type FoodLogEntry {
    FoodLogEntry(
      id: String,
      date: String,
      food_source: FoodSource,
      // Union type approach - only one will be set
      recipe_id: Option(String),
      fdc_id: Option(Int),
      custom_food_id: Option(String),
      // Display name (denormalized for performance)
      food_name: String,
      servings: Float,
      serving_size: Option(Float),
      serving_unit: Option(String),
      macros: Macros,
      meal_type: MealType,
      logged_at: String,
    )
  }
  ```

**Files to Modify**:
- `/gleam/src/meal_planner/types.gleam` (modify ~50 lines)

**Test Strategy**:
- Type construction tests for each source type
- JSON encoding/decoding tests

---

### Bead 2.3: Food Log Creation Functions
**Priority**: P0 (Critical)
**Dependencies**: Bead 2.2, Bead 1.3
**Estimated Effort**: 4 hours

**Technical Approach**:
- Add to `storage.gleam`:
  ```gleam
  pub fn log_usda_food(
    conn: pog.Connection,
    fdc_id: Int,
    servings: Float,
    serving_size: Float,
    meal_type: MealType,
    date: String,
  ) -> Result(FoodLogEntry, StorageError)

  pub fn log_custom_food(
    conn: pog.Connection,
    custom_food_id: String,
    servings: Float,
    meal_type: MealType,
    date: String,
  ) -> Result(FoodLogEntry, StorageError)

  pub fn log_recipe(
    conn: pog.Connection,
    recipe_id: String,
    servings: Float,
    meal_type: MealType,
    date: String,
  ) -> Result(FoodLogEntry, StorageError)
  ```
- Calculate macros from nutrients
- Generate unique log entry ID

**Files to Modify**:
- `/gleam/src/meal_planner/storage.gleam` (add ~150 lines)

**Test Strategy**:
- Test each food source type
- Verify macro calculations
- Test constraint violations

---

## 🎨 PHASE 3: Frontend - Modern UI Framework

### Bead 3.1: Modern CSS Design System
**Priority**: P1 (Important)
**Dependencies**: None
**Estimated Effort**: 6 hours

**Technical Approach**:
- Create `priv/static/styles.css` with:
  - CSS custom properties for theming
  - Modern color palette (use system-ui font stack)
  - Responsive grid system
  - Card components
  - Form styling
  - Button variants
  - Modal/dialog styling
  - Micro-interactions and transitions

**Design System**:
```css
:root {
  /* Colors - Modern neutral palette */
  --color-primary: #0066ff;
  --color-primary-dark: #0052cc;
  --color-success: #00c853;
  --color-warning: #ff9800;
  --color-error: #f44336;

  --color-bg: #ffffff;
  --color-surface: #f8f9fa;
  --color-border: #e0e0e0;
  --color-text: #1a1a1a;
  --color-text-secondary: #666666;

  /* Spacing scale */
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;

  /* Typography */
  --font-sans: system-ui, -apple-system, sans-serif;
  --font-mono: 'SF Mono', Monaco, monospace;

  /* Borders */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;

  /* Shadows */
  --shadow-sm: 0 1px 3px rgba(0,0,0,0.1);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.1);
  --shadow-lg: 0 10px 25px rgba(0,0,0,0.15);
}
```

**Files to Create**:
- `/gleam/priv/static/styles.css` (~800 lines)
- `/gleam/priv/static/components.css` (~400 lines)

**Test Strategy**:
- Visual regression testing
- Responsive breakpoint testing
- Accessibility contrast checks

---

### Bead 3.2: Redesign Dashboard Page
**Priority**: P1 (Important)
**Dependencies**: Bead 3.1
**Estimated Effort**: 5 hours

**Technical Approach**:
- Update `web.gleam` dashboard_page():
  - Card-based layout with CSS Grid
  - Today's macros progress bars
  - Recent food log entries
  - Quick action buttons
  - Daily streak indicator
  - Goal progress visualization

**Layout Structure**:
```
[Hero Card - Daily Summary]
  ├─ Progress rings for P/F/C
  └─ Calorie count

[Grid 2-column]
  ├─ [Recent Foods Card]
  │   └─ Last 5 entries with edit/delete
  └─ [Quick Actions Card]
      ├─ Log Food button
      ├─ Add Custom Food button
      └─ View History button

[Goals Card]
  └─ Weekly trends chart
```

**Files to Modify**:
- `/gleam/src/meal_planner/web.gleam` (modify dashboard_page, ~150 lines)

**Test Strategy**:
- Integration test for page rendering
- Test with empty log
- Test with multiple entries

---

### Bead 3.3: Custom Food Entry Form
**Priority**: P0 (Critical)
**Dependencies**: Bead 3.1, Bead 1.3
**Estimated Effort**: 4 hours

**Technical Approach**:
- Add route: `/foods/custom/new` and `/foods/custom/:id/edit`
- Create form component in `web.gleam`:
  ```gleam
  fn custom_food_form(food: Option(CustomFood)) -> element.Element(msg) {
    html.form([...], [
      // Basic info
      text_input("name", "Food Name", required: True),
      textarea_input("description", "Description"),

      // Serving info
      number_input("serving_size", "Serving Size"),
      text_input("serving_unit", "Unit (e.g., g, oz, cup)"),

      // Macros (required)
      number_input("protein", "Protein (g)", step: 0.1),
      number_input("fat", "Fat (g)", step: 0.1),
      number_input("carbs", "Carbs (g)", step: 0.1),

      // Micronutrients (optional)
      collapsible_section("Advanced Nutrients", [
        number_input("fiber", "Fiber (g)"),
        number_input("sodium", "Sodium (mg)"),
        // ... more nutrients
      ]),

      // Actions
      button("Save", type: "submit"),
      button("Cancel", href: "/foods"),
    ])
  }
  ```

**Files to Modify**:
- `/gleam/src/meal_planner/web.gleam` (add ~200 lines)

**Test Strategy**:
- Form validation tests
- Create custom food workflow
- Edit existing custom food

---

### Bead 3.4: Unified Food Search Interface
**Priority**: P1 (Important)
**Dependencies**: Bead 3.1, Bead 1.4
**Estimated Effort**: 6 hours

**Technical Approach**:
- Enhance `/foods` page:
  - Tab navigation (All / USDA / My Foods)
  - Live search with debouncing
  - Result cards showing:
    - Food name
    - Source badge (USDA/Custom)
    - Macro preview
    - "Add to Log" button
  - Pagination for large result sets

**Component Structure**:
```gleam
fn search_interface(query: String, results: List(SearchableFood)) {
  div([
    search_tabs(["All", "USDA", "My Foods"]),
    search_input_with_icon(query),
    filters_row([
      filter_chip("High Protein"),
      filter_chip("Low Carb"),
    ]),
    results_grid(results),
  ])
}

fn food_result_card(food: SearchableFood) {
  card([
    food_header(name, source_badge),
    macro_row(protein, fat, carbs),
    action_buttons([
      button("Add to Log", onClick: show_log_modal),
      button("View Details", href: detail_url),
    ]),
  ])
}
```

**Files to Modify**:
- `/gleam/src/meal_planner/web.gleam` (modify foods_page, ~250 lines)

**Test Strategy**:
- Search with different filters
- Tab switching
- Add to log workflow

---

### Bead 3.5: Food Logging Modal
**Priority**: P0 (Critical)
**Dependencies**: Bead 3.1, Bead 2.3
**Estimated Effort**: 5 hours

**Technical Approach**:
- Create modal component:
  ```gleam
  fn log_food_modal(food: SearchableFood) {
    modal([
      modal_header("Log " <> food_name),
      modal_body([
        // Portion calculator
        number_input("servings", "Servings", default: 1.0),
        select_input("meal_type", "Meal", options: [
          "Breakfast", "Lunch", "Dinner", "Snack"
        ]),
        date_input("date", "Date", default: today()),

        // Live macro preview
        macro_preview_card(calculated_macros),
      ]),
      modal_footer([
        button("Cancel"),
        button("Log Food", type: "submit", variant: "primary"),
      ]),
    ])
  }
  ```
- JavaScript for portion calculation (progressive enhancement)
- HTMX or Alpine.js for interactivity

**Files to Modify**:
- `/gleam/src/meal_planner/web.gleam` (add ~150 lines)
- `/gleam/priv/static/modal.js` (new file, ~100 lines)

**Test Strategy**:
- Modal open/close
- Portion calculation accuracy
- Form submission

---

## 🔌 PHASE 4: API Endpoints

### Bead 4.1: Custom Food API Endpoints
**Priority**: P0 (Critical)
**Dependencies**: Bead 1.3
**Estimated Effort**: 3 hours

**Technical Approach**:
- Add to `web.gleam` handle_api():
  ```gleam
  case rest {
    ["foods", "custom"] -> api_custom_foods(req, ctx)
    ["foods", "custom", id] -> api_custom_food(req, id, ctx)
    // ... existing routes
  }
  ```
- Implement handlers:
  - `POST /api/foods/custom` - Create custom food
  - `GET /api/foods/custom/:id` - Get custom food
  - `PUT /api/foods/custom/:id` - Update custom food
  - `DELETE /api/foods/custom/:id` - Delete custom food
  - `GET /api/foods/custom` - List user's custom foods

**Files to Modify**:
- `/gleam/src/meal_planner/web.gleam` (add ~200 lines in handle_api section)

**Test Strategy**:
- API integration tests
- Request validation tests
- Error response tests

---

### Bead 4.2: Enhanced Food Log API
**Priority**: P0 (Critical)
**Dependencies**: Bead 2.3
**Estimated Effort**: 3 hours

**Technical Approach**:
- Add endpoints:
  - `POST /api/log/food` - Log any food type
  - `GET /api/log/:date` - Get daily log
  - `DELETE /api/log/:id` - Delete log entry
  - `PUT /api/log/:id` - Update log entry

**Request Format**:
```json
POST /api/log/food
{
  "food_source": "usda|custom|recipe",
  "food_id": "...",
  "servings": 1.5,
  "serving_size": 100,
  "meal_type": "lunch",
  "date": "2025-12-03"
}
```

**Files to Modify**:
- `/gleam/src/meal_planner/web.gleam` (add ~150 lines)

**Test Strategy**:
- Test each food source type
- Test validation errors
- Test concurrent logging

---

### Bead 4.3: Unified Search API
**Priority**: P1 (Important)
**Dependencies**: Bead 1.4
**Estimated Effort**: 2 hours

**Technical Approach**:
- Endpoint: `GET /api/search?q=chicken&source=all|usda|custom&limit=20`
- Return unified results with source indicator
- Support filtering and sorting

**Files to Modify**:
- `/gleam/src/meal_planner/web.gleam` (modify api_foods, ~50 lines)

**Test Strategy**:
- Search with different filters
- Performance testing with large result sets

---

## ✅ PHASE 5: Testing & Quality Assurance

### Bead 5.1: Unit Tests for Custom Foods
**Priority**: P0 (Critical)
**Dependencies**: All Phase 1 beads
**Estimated Effort**: 4 hours

**Technical Approach**:
- Create `test/meal_planner/custom_foods_test.gleam`:
  - Type construction tests
  - Validation tests
  - JSON encoding/decoding
  - Storage CRUD operations
  - Search functionality

**Files to Create**:
- `/gleam/test/meal_planner/custom_foods_test.gleam` (~300 lines)

**Test Coverage**:
- Happy paths
- Edge cases (empty strings, negative numbers)
- Constraint violations
- Concurrent access

---

### Bead 5.2: Integration Tests for Food Logging
**Priority**: P0 (Critical)
**Dependencies**: All Phase 2 beads
**Estimated Effort**: 5 hours

**Technical Approach**:
- Create `test/meal_planner/food_log_integration_test.gleam`:
  - End-to-end logging workflow
  - Multi-source logging in same day
  - Daily log aggregation
  - Macro calculation accuracy

**Files to Create**:
- `/gleam/test/meal_planner/food_log_integration_test.gleam` (~400 lines)

**Test Scenarios**:
- Log breakfast (USDA), lunch (custom), dinner (recipe)
- Verify total macros calculation
- Test log deletion and recalculation
- Test date boundaries

---

### Bead 5.3: Web UI Tests
**Priority**: P1 (Important)
**Dependencies**: All Phase 3 beads
**Estimated Effort**: 4 hours

**Technical Approach**:
- Update `test/meal_planner/web_test.gleam`:
  - Page rendering tests
  - Form submission tests
  - API endpoint tests
  - Error handling

**Files to Modify**:
- `/gleam/test/meal_planner/web_test.gleam` (add ~300 lines)

**Test Coverage**:
- Custom food form
- Search interface
- Log modal
- Dashboard rendering

---

## 📊 PHASE 6: Performance & Polish

### Bead 6.1: Database Indexing Optimization
**Priority**: P2 (Nice to have)
**Dependencies**: All Phase 1 & 2 beads
**Estimated Effort**: 2 hours

**Technical Approach**:
- Analyze query patterns with EXPLAIN
- Add composite indexes for common queries
- Add covering indexes for high-traffic queries

**Example Optimizations**:
```sql
-- Optimize food log daily queries
CREATE INDEX idx_food_logs_date_meal ON food_logs(date, meal_type);

-- Optimize custom food search
CREATE INDEX idx_custom_foods_user_name ON custom_foods(user_id, name);
```

**Files to Create**:
- `/gleam/migrations_pg/006_performance_indexes.sql`

---

### Bead 6.2: Caching Layer for USDA Foods
**Priority**: P2 (Nice to have)
**Dependencies**: Bead 1.4
**Estimated Effort**: 3 hours

**Technical Approach**:
- Add ETS-based caching for frequent USDA food queries
- Cache search results for 15 minutes
- Implement cache invalidation strategy

**Files to Modify**:
- `/gleam/src/meal_planner/storage.gleam` (add caching layer, ~100 lines)

---

### Bead 6.3: Accessibility Audit
**Priority**: P1 (Important)
**Dependencies**: All Phase 3 beads
**Estimated Effort**: 4 hours

**Technical Approach**:
- Add ARIA labels to interactive elements
- Ensure keyboard navigation works
- Add focus indicators
- Test with screen readers
- Ensure color contrast meets WCAG AA

**Files to Modify**:
- `/gleam/src/meal_planner/web.gleam` (accessibility improvements)
- `/gleam/priv/static/styles.css` (focus styles)

---

### Bead 6.4: Mobile Responsive Design
**Priority**: P1 (Important)
**Dependencies**: Bead 3.1
**Estimated Effort**: 5 hours

**Technical Approach**:
- Mobile-first responsive breakpoints
- Touch-friendly button sizes (min 44px)
- Optimize forms for mobile keyboards
- Test on iOS Safari and Chrome Android

**Breakpoints**:
```css
/* Mobile first */
@media (min-width: 640px) { /* Tablet */ }
@media (min-width: 1024px) { /* Desktop */ }
@media (min-width: 1280px) { /* Wide */ }
```

**Files to Modify**:
- `/gleam/priv/static/styles.css` (add responsive utilities)

---

## 📋 Implementation Dependencies Graph

```
Phase 1: Database Layer
Bead 1.1 (Custom Foods Migration)
  └─> Bead 1.2 (CustomFood Type)
       └─> Bead 1.3 (Storage Functions)
            └─> Bead 1.4 (Unified Search)

Phase 2: Food Logging
Bead 2.1 (Food Log Migration)
  └─> Bead 2.2 (Enhanced FoodLogEntry Type)
       └─> Bead 2.3 (Log Creation Functions)

Phase 3: Frontend
Bead 3.1 (CSS Design System) [Independent]
  ├─> Bead 3.2 (Dashboard Redesign)
  ├─> Bead 3.3 (Custom Food Form) [also needs 1.3]
  ├─> Bead 3.4 (Search Interface) [also needs 1.4]
  └─> Bead 3.5 (Log Modal) [also needs 2.3]

Phase 4: API
Bead 4.1 (Custom Food API) [needs 1.3]
Bead 4.2 (Food Log API) [needs 2.3]
Bead 4.3 (Search API) [needs 1.4]

Phase 5: Testing
Bead 5.1 (Custom Food Tests) [needs Phase 1]
Bead 5.2 (Food Log Tests) [needs Phase 2]
Bead 5.3 (Web UI Tests) [needs Phase 3]

Phase 6: Polish
Bead 6.1 (DB Optimization) [needs Phase 1 & 2]
Bead 6.2 (Caching) [needs 1.4]
Bead 6.3 (Accessibility) [needs Phase 3]
Bead 6.4 (Mobile) [needs 3.1]
```

---

## 🎯 Priority Levels Explained

- **P0 (Critical)**: Must-have for MVP functionality
  - Database migrations
  - Core CRUD operations
  - Basic UI for custom foods
  - Food logging functionality

- **P1 (Important)**: Enhances UX significantly
  - Unified search
  - Modern UI design
  - Accessibility
  - Mobile responsive

- **P2 (Nice to have)**: Performance and polish
  - Caching
  - Advanced optimizations
  - Analytics

---

## 🚀 Recommended Implementation Order

### Sprint 1 (Week 1): Database Foundation
1. Bead 1.1 - Custom Foods Migration
2. Bead 1.2 - CustomFood Type
3. Bead 1.3 - Storage Functions
4. Bead 2.1 - Food Log Migration
5. Bead 2.2 - Enhanced FoodLogEntry Type
6. Bead 5.1 - Unit Tests

**Deliverable**: Functional database layer with tests

### Sprint 2 (Week 2): Core Functionality
1. Bead 2.3 - Food Log Creation
2. Bead 1.4 - Unified Search
3. Bead 4.1 - Custom Food API
4. Bead 4.2 - Food Log API
5. Bead 5.2 - Integration Tests

**Deliverable**: Working API for all core features

### Sprint 3 (Week 3): UI/UX
1. Bead 3.1 - CSS Design System
2. Bead 3.3 - Custom Food Form
3. Bead 3.4 - Search Interface
4. Bead 3.5 - Log Modal
5. Bead 4.3 - Search API

**Deliverable**: Modern, functional UI

### Sprint 4 (Week 4): Polish & Launch
1. Bead 3.2 - Dashboard Redesign
2. Bead 6.3 - Accessibility
3. Bead 6.4 - Mobile Responsive
4. Bead 5.3 - Web UI Tests
5. Bead 6.1 - Performance Optimization

**Deliverable**: Production-ready application

---

## 📊 Effort Summary

| Phase | Beads | Total Hours |
|-------|-------|-------------|
| Phase 1: Database | 4 | 10 hours |
| Phase 2: Food Logging | 3 | 7 hours |
| Phase 3: Frontend | 5 | 26 hours |
| Phase 4: API | 3 | 8 hours |
| Phase 5: Testing | 3 | 13 hours |
| Phase 6: Polish | 4 | 14 hours |
| **TOTAL** | **22 beads** | **78 hours** |

**Estimated Timeline**: 4 weeks (20 hours/week)

---

## ✅ Definition of Done (Per Bead)

A bead is considered complete when:
1. ✅ Code is written and follows Gleam best practices
2. ✅ Unit tests pass with >80% coverage
3. ✅ Integration tests pass (if applicable)
4. ✅ Code is peer-reviewed
5. ✅ Documentation is updated
6. ✅ No compiler warnings
7. ✅ Database migrations are reversible
8. ✅ UI is accessible (WCAG AA for frontend beads)
9. ✅ Changes are committed with descriptive messages

---

## 🔍 Key Design Decisions

### 1. Custom Foods vs USDA Foods
- **Decision**: Separate tables, unified search
- **Rationale**: Different data ownership, allows user customization
- **Trade-off**: More complex queries, but better data integrity

### 2. Food Log Schema
- **Decision**: Single table with discriminated union (food_source column)
- **Rationale**: Simplifies querying daily logs
- **Trade-off**: Nullable foreign keys, but cleaner API

### 3. Frontend Architecture
- **Decision**: Server-side rendering with minimal JavaScript
- **Rationale**: Leverages Lustre's SSR, better performance on low-end devices
- **Trade-off**: Less interactivity, but faster initial load

### 4. Micronutrients Storage
- **Decision**: Optional columns in custom_foods, use food_nutrients for USDA
- **Rationale**: Flexibility for users who want detailed tracking
- **Trade-off**: Schema complexity, but meets power-user needs

---

## 🎨 UI/UX Design Principles

1. **Mobile-First**: Design for smallest screen, enhance for larger
2. **Progressive Enhancement**: Works without JavaScript, better with it
3. **Accessible by Default**: ARIA labels, keyboard navigation, high contrast
4. **Data Density**: Show maximum useful info without overwhelming
5. **Quick Actions**: Common tasks (log food) within 2 taps
6. **Visual Hierarchy**: Typography and spacing guide the eye
7. **Feedback**: Every action has visible confirmation

---

## 🔧 Technical Stack Summary

- **Language**: Gleam 1.0+
- **Web Framework**: Wisp 2.0
- **Server**: Mist 5.0
- **Database**: PostgreSQL 14+
- **ORM**: pog (PostgreSQL for Gleam)
- **Frontend**: Lustre 5.0 (SSR)
- **CSS**: Custom CSS with modern features
- **Testing**: gleeunit + qcheck
- **Deployment**: BEAM VM (Erlang runtime)

---

## 📝 Notes for Implementation

### Database Considerations
- ✅ Micronutrients are available in `food_nutrients` table
- Use `nutrient.rank` for ordering display (most important nutrients first)
- Full-text search is already optimized with GIN indexes
- Consider materialized views for daily log aggregations if performance issues arise

### Code Organization
- Keep storage functions focused (single responsibility)
- Use Result types for error handling
- Leverage Gleam's pattern matching for food source discrimination
- Add helper functions for common conversions (USDA nutrients → Macros)

### Frontend Performance
- Lazy-load USDA food nutrients (only fetch on detail view)
- Use pagination for search results (50 items per page)
- Cache rendered components where possible
- Minimize JavaScript bundle size

### Security Considerations
- Validate all user input server-side
- Use parameterized queries (already done with pog)
- Sanitize custom food names (prevent XSS)
- Implement rate limiting for API endpoints
- Add CSRF protection for forms

---

## 🎯 Success Metrics

After implementation, we should be able to:
1. ✅ Create custom foods with full macro and micronutrient data
2. ✅ Search across 400K+ USDA foods + custom foods in <100ms
3. ✅ Log foods from any source (USDA, custom, recipe) in 3 taps
4. ✅ View daily nutrition breakdown with micronutrients
5. ✅ Edit and delete custom foods and log entries
6. ✅ Use the app on mobile devices without friction
7. ✅ Navigate entirely with keyboard
8. ✅ Handle 1000+ concurrent users (scalability test)

---

## 📚 References

- [Gleam Documentation](https://gleam.run/documentation/)
- [Wisp Web Framework](https://hexdocs.pm/wisp/)
- [pog PostgreSQL Library](https://hexdocs.pm/pog/)
- [Lustre SSR Guide](https://lustre.build/)
- [USDA FoodData Central API](https://fdc.nal.usda.gov/api-guide.html)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

**Plan Version**: 1.0
**Created**: 2025-12-03
**Author**: Strategic Planning Agent
**Status**: Ready for Implementation

