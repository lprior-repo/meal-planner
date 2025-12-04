# Feature: Weekly Meal Planning ⭐ PRIMARY FOCUS

## Bead ID: meal-planner-0fq

## Parent Epic: meal-planner-g8s (Meal Planner Web Application MVP)

## Priority: P0 - Critical (PRIMARY FEATURE)

## Dependencies
- meal-planner-wwd: Recipe Management CRUD

## Feature Description
Enable users to plan meals for the upcoming week, with automatic shopping list generation and nutritional balance optimization.

**This is the PRIMARY FOCUS feature** for the MVP. All design and implementation effort should prioritize making weekly meal planning intuitive, powerful, and delightful to use.

## Capabilities

### Capability 1: Create Weekly Plan
**Behaviors:**
- GIVEN week view WHEN displayed THEN show 7 days with meal slots
- GIVEN meal slot WHEN clicking THEN show recipe selector
- GIVEN recipe WHEN selected THEN assign to day/meal slot
- GIVEN plan WHEN saved THEN persist to weekly_plans table

### Capability 2: Auto-Generate Plan
**Behaviors:**
- GIVEN user profile WHEN auto-generating THEN optimize for macro targets
- GIVEN recipes WHEN selecting THEN consider variety and preferences
- GIVEN FODMAP settings WHEN enabled THEN filter low-FODMAP only
- GIVEN generated plan WHEN presented THEN allow user modifications

### Capability 3: View Weekly Nutrition Summary
**Behaviors:**
- GIVEN weekly plan WHEN viewing THEN show daily macro totals
- GIVEN averages WHEN calculating THEN show weekly protein/fat/carb averages
- GIVEN targets WHEN comparing THEN highlight over/under days

### Capability 4: Generate Shopping List
**Behaviors:**
- GIVEN weekly plan WHEN generating list THEN aggregate all ingredients
- GIVEN duplicate ingredients WHEN combining THEN sum quantities
- GIVEN shopping list WHEN exporting THEN support text/PDF formats

### Capability 5: Copy and Modify Plans
**Behaviors:**
- GIVEN previous week WHEN copying THEN duplicate to new week
- GIVEN template plan WHEN applying THEN use as starting point
- GIVEN plan WHEN modifying THEN allow swap/remove/add meals

## Acceptance Criteria
- [ ] Users can manually plan meals for 7 days with drag-and-drop interface
- [ ] Auto-generate creates balanced weekly plan optimized for macro targets
- [ ] Weekly nutrition summary shows daily and average macro breakdown
- [ ] Shopping list aggregates ingredients correctly with quantities
- [ ] Plans can be copied and modified (previous weeks, templates)
- [ ] Mobile-responsive weekly view works on phones and tablets
- [ ] Visual feedback for macro balance (over/under target indicators)
- [ ] Export options: PDF shopping list, print weekly plan

## Test Criteria (BDD)
```gherkin
Scenario: Plan a week manually
  Given user is on weekly planning page
  When user assigns "Oatmeal" to Monday breakfast
  And assigns "Chicken Salad" to Monday lunch
  And saves the plan
  Then Monday shows both meals
  And daily macro total updates
  And weekly average updates

Scenario: Generate shopping list
  Given weekly plan has 14 meals assigned
  When user generates shopping list
  Then all unique ingredients appear
  And quantities are summed per ingredient
  And list is organized by category

Scenario: Auto-generate balanced week
  Given user has macro targets set (150g protein, 70g fat, 200g carbs)
  When user clicks "Auto-Generate Week"
  Then system creates 21 meals (7 days × 3 meals)
  And weekly average matches targets within 5%
  And recipes are varied (no recipe appears >3 times)

Scenario: Copy previous week
  Given user has a completed week plan for Jan 1-7
  When user navigates to Jan 8-14
  And clicks "Copy Previous Week"
  Then all 21 meals are duplicated to new week
  And user can modify individual meals

Scenario: Drag-and-drop meal assignment
  Given user is on weekly planning page
  When user drags "Turkey Chili" recipe
  And drops it on Wednesday dinner slot
  Then Wednesday dinner shows "Turkey Chili"
  And Wednesday macro totals update immediately

Scenario: Visual macro balance indicators
  Given Monday plan has 180g protein (target: 150g)
  When viewing Monday summary
  Then protein bar shows "120% of target" in warning color
  And visual indicator shows +30g over target
```

## UI/UX Requirements

### Weekly Calendar View
- 7-column grid (Monday-Sunday)
- 3 rows per day (Breakfast, Lunch, Dinner)
- Drag-and-drop recipe assignment
- Color-coded macro balance indicators
- Responsive: Stack to single column on mobile

### Macro Summary Panel
- Daily totals for each day
- Weekly average with target comparison
- Visual progress bars (protein/fat/carbs)
- Traffic light colors: green (on target), yellow (5-10% off), red (>10% off)

### Shopping List
- Grouped by category (Proteins, Vegetables, Grains, etc.)
- Quantities with units
- Checkboxes for shopping
- Export to PDF
- Print-friendly layout

## Database Schema

### weekly_plans table
```sql
CREATE TABLE weekly_plans (
  id UUID PRIMARY KEY,
  week_start_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### weekly_plan_meals table
```sql
CREATE TABLE weekly_plan_meals (
  id UUID PRIMARY KEY,
  weekly_plan_id UUID REFERENCES weekly_plans(id),
  day_of_week INT CHECK (day_of_week BETWEEN 0 AND 6),
  meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'dinner')),
  recipe_id UUID REFERENCES recipes(id),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(weekly_plan_id, day_of_week, meal_type)
);
```
