# Macro Progress Bars Component

## Overview

The `macro_progress` component provides visual progress indicators for macronutrient tracking with three display styles:
- **Linear** - Horizontal progress bars (default)
- **Circular** - SVG-based circular indicators
- **Compact** - Minimal space-efficient display

## Features

✅ **Color Coding**: Automatic status colors based on achievement
- 🟡 Yellow: Under target (<80%)
- 🟢 Green: On track (80-120%)
- 🟠 Orange: Over target (120-140%)
- 🔴 Red: Excess (>140%)

✅ **Responsive Design**: Works on mobile, tablet, and desktop

✅ **Accessibility**: Full ARIA support for screen readers

✅ **HTMX Integration**: Auto-refresh with server updates

✅ **Pure HTML/CSS**: No JavaScript required (CSS animations only)

## Installation

The component is located at:
```
gleam/src/meal_planner/ui/components/macro_progress.gleam
```

Import in your module:
```gleam
import meal_planner/ui/components/macro_progress
```

## Basic Usage

### 1. Single Macro Progress Bar

```gleam
import meal_planner/ui/components/macro_progress

// Create progress data
let protein_progress = macro_progress.macro_progress(
  "Protein",
  145.0,  // current value
  180.0,  // goal value
  "g"     // unit
)

// Render linear progress bar
macro_progress.render_progress_bar(protein_progress)
```

**Output:**
```html
<div class="macro-progress linear progress-on-target">
  <div class="progress-header">
    <span class="progress-label">Protein</span>
    <span class="progress-values">145g / 180g</span>
  </div>
  <div class="progress-bar-container" role="progressbar"
       aria-valuenow="80" aria-valuemin="0" aria-valuemax="100"
       aria-label="Protein: 145 of 180 g, 80 percent, On track">
    <div class="progress-bar-fill" style="width: 80%"></div>
  </div>
  <div class="progress-footer">
    <span class="progress-percentage">80%</span>
    <span class="progress-status">On track</span>
  </div>
</div>
```

### 2. Circular Progress Bar

```gleam
// Render as circular indicator
macro_progress.render_circular_progress(protein_progress)
```

**Output:**
- SVG circular progress indicator
- Center percentage display
- Animated stroke transitions
- Color-coded based on achievement

### 3. Compact Progress Bar

```gleam
// Render compact version (for cards)
macro_progress.render_compact_progress(protein_progress)
```

**Output:**
- Single-line display
- Abbreviated labels (P/F/C)
- Minimal space usage

## Complete Macro Set

### Create MacroSet

```gleam
let macros = macro_progress.macro_set(
  145.0, 180.0,  // protein: current, goal
  65.0, 70.0,    // fat: current, goal
  210.0, 250.0,  // carbs: current, goal
  1850.0, 2100.0 // calories: current, goal
)
```

### Linear Display (Default)

```gleam
macro_progress.render_macro_set_linear(macros)
```

Renders all four macros as linear progress bars in a grid layout.

### Circular Display

```gleam
macro_progress.render_macro_set_circular(macros)
```

Renders all four macros as circular indicators - great for dashboards.

### Compact Display

```gleam
macro_progress.render_macro_set_compact(macros)
```

Renders all four macros in minimal space - perfect for cards.

## HTMX Integration

### Auto-Refresh with HTMX

```gleam
macro_progress.render_macro_progress_with_refresh(
  macros,
  macro_progress.Linear,
  "/api/macros/today"
)
```

**Features:**
- Auto-updates every 30 seconds
- Triggers on custom "macroUpdate" event
- Shows loading indicator during updates
- Preserves scroll position

**Server Endpoint:**
```gleam
// /api/macros/today should return updated macro HTML
pub fn handle_macros_today(req: Request) -> Response {
  let macros = get_current_macros() // Fetch from database

  macro_progress.render_macro_set_linear(macros)
  |> element.to_string
  |> response.html
}
```

**Manual Trigger:**
```html
<!-- Trigger update from button -->
<button hx-post="/api/logs/food"
        hx-target="#log-list"
        hx-on::after-request="htmx.trigger('body', 'macroUpdate')">
  Log Food
</button>
```

## Server-Side Rendering

### Dashboard Page Example

```gleam
import meal_planner/ui/components/macro_progress
import meal_planner/types.{type DailyLog}

pub fn render_dashboard(log: DailyLog, targets: MacroTargets) -> Element(msg) {
  let macros = macro_progress.macro_set(
    log.total_macros.protein, targets.protein,
    log.total_macros.fat, targets.fat,
    log.total_macros.carbs, targets.carbs,
    types.macros_calories(log.total_macros), targets.calories
  )

  html.div([class("dashboard")], [
    html.h1([], [text("Today's Progress")]),

    // Linear progress bars with HTMX refresh
    macro_progress.render_macro_progress_with_refresh(
      macros,
      macro_progress.Linear,
      "/api/macros/today"
    ),

    // Other dashboard content...
  ])
}
```

### Meal Card Example

```gleam
pub fn render_meal_card(meal: Meal) -> Element(msg) {
  let meal_macros = macro_progress.macro_set(
    meal.protein, daily_targets.protein /. 3.0,  // 1/3 of daily
    meal.fat, daily_targets.fat /. 3.0,
    meal.carbs, daily_targets.carbs /. 3.0,
    meal.calories, daily_targets.calories /. 3.0
  )

  html.div([class("meal-card")], [
    html.h3([], [text(meal.name)]),

    // Compact progress for space efficiency
    macro_progress.render_macro_set_compact(meal_macros)
  ])
}
```

## CSS Styling

The component requires CSS classes for styling. Add to your stylesheet:

```css
/* Linear Progress Bar */
.macro-progress.linear {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  padding: 1rem;
  border-radius: 0.5rem;
  background: white;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.progress-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.875rem;
}

.progress-label {
  font-weight: 600;
  color: #374151;
}

.progress-values {
  color: #6b7280;
}

.progress-bar-container {
  width: 100%;
  height: 1.5rem;
  background: #e5e7eb;
  border-radius: 9999px;
  overflow: hidden;
  position: relative;
}

.progress-bar-fill {
  height: 100%;
  background: currentColor;
  border-radius: 9999px;
  transition: width 0.5s ease-in-out;
}

.progress-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.75rem;
}

.progress-percentage {
  font-weight: 600;
}

.progress-status {
  color: #6b7280;
}

/* Color Coding */
.progress-under {
  color: #f59e0b; /* yellow */
}

.progress-on-target {
  color: #10b981; /* green */
}

.progress-over {
  color: #ef4444; /* orange */
}

.progress-excess {
  color: #dc2626; /* red */
}

/* Circular Progress */
.macro-progress.circular {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 1rem;
  position: relative;
}

.progress-circle-svg {
  width: 120px;
  height: 120px;
}

.progress-circle-text {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-align: center;
}

.progress-percentage-large {
  font-size: 1.5rem;
  font-weight: 700;
}

.progress-circle-info {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
  margin-top: 0.5rem;
}

/* Compact Progress */
.macro-progress.compact {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem;
}

.progress-label-compact {
  font-weight: 600;
  min-width: 1.5rem;
}

.progress-bar-compact {
  flex: 1;
  height: 0.5rem;
  background: #e5e7eb;
  border-radius: 9999px;
  overflow: hidden;
}

.progress-values-compact {
  font-size: 0.75rem;
  color: #6b7280;
  white-space: nowrap;
}

/* Grid Layouts */
.macro-progress-set.linear {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1rem;
}

@media (min-width: 768px) {
  .macro-progress-set.linear {
    grid-template-columns: repeat(2, 1fr);
  }
}

.macro-progress-set.circular {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.5rem;
}

@media (min-width: 768px) {
  .macro-progress-set.circular {
    grid-template-columns: repeat(4, 1fr);
  }
}

.macro-progress-set.compact {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

/* HTMX Loading Indicator */
.htmx-indicator {
  display: none;
  color: #6b7280;
  font-size: 0.875rem;
  padding: 0.5rem;
  text-align: center;
}

.htmx-request .htmx-indicator {
  display: block;
}

/* Smooth Animations */
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.htmx-request .progress-bar-fill {
  animation: pulse 2s ease-in-out infinite;
}
```

## Color Thresholds

Color coding is determined by percentage of goal achieved:

| Range | Status | Color | Description |
|-------|--------|-------|-------------|
| 0-79% | Under | Yellow | Below target (deficiency warning) |
| 80-120% | On Track | Green | Within healthy range |
| 121-140% | Over | Orange | Above target (moderate excess) |
| 141%+ | Excess | Red | Significant excess |

These thresholds are defined in `meal_planner/nutrition_constants.gleam`:
- `macro_under_threshold`: 80.0
- `macro_on_target_upper`: 120.0
- `macro_over_threshold`: 140.0

## Accessibility

All progress components include:

✅ **ARIA Attributes:**
- `role="progressbar"`
- `aria-valuenow`: Current percentage
- `aria-valuemin`: 0
- `aria-valuemax`: 100
- `aria-label`: Descriptive label with values and status

✅ **Screen Reader Support:**
- Descriptive labels for all values
- Status announcements (On track, Under target, etc.)
- Unit labels (grams, kilocalories)

✅ **Keyboard Navigation:**
- All interactive elements focusable
- Clear focus indicators

✅ **Color Contrast:**
- All colors meet WCAG AA standards
- Status indicated by text, not just color

## Performance

- **No JavaScript**: Pure CSS animations
- **SSR-Friendly**: Renders on server
- **Lightweight**: Minimal HTML output
- **Cached**: HTMX caches responses
- **Fast Updates**: Only swaps changed elements

## Examples

### Dashboard with Live Updates

```gleam
pub fn dashboard_page(user_id: Int) -> Element(msg) {
  let today = get_today_date()
  let log = storage.get_daily_log(db, user_id, today)
  let targets = get_user_targets(user_id)

  let macros = macro_progress.macro_set(
    log.total_macros.protein, targets.protein,
    log.total_macros.fat, targets.fat,
    log.total_macros.carbs, targets.carbs,
    types.macros_calories(log.total_macros), targets.calories
  )

  html.div([class("page-container")], [
    // Header with date
    html.header([], [
      html.h1([], [text("Daily Progress")]),
      html.p([], [text(today)]),
    ]),

    // Macro progress with auto-refresh
    macro_progress.render_macro_progress_with_refresh(
      macros,
      macro_progress.Linear,
      "/api/macros/today"
    ),

    // Food log with HTMX
    html.div([attribute("id", "food-log")], [
      // Food entries...
    ]),
  ])
}
```

### Mobile-Friendly Card

```gleam
pub fn meal_summary_card(meal: Meal) -> Element(msg) {
  let meal_macros = calculate_meal_macros(meal)
  let meal_progress = macro_progress.MacroSet(
    protein: macro_progress.macro_progress("Protein", meal_macros.protein, 60.0, "g"),
    fat: macro_progress.macro_progress("Fat", meal_macros.fat, 25.0, "g"),
    carbs: macro_progress.macro_progress("Carbs", meal_macros.carbs, 80.0, "g"),
    calories: macro_progress.macro_progress("Calories",
      types.macros_calories(meal_macros), 700.0, " kcal"),
  )

  html.div([class("meal-card")], [
    html.h3([], [text(meal.name)]),
    html.p([class("meal-time")], [text(meal.time)]),

    // Compact display for mobile
    macro_progress.render_macro_set_compact(meal_progress),

    // Actions
    html.div([class("card-actions")], [
      html.button(
        [
          attribute("hx-delete", "/api/meals/" <> int.to_string(meal.id)),
          attribute("hx-target", "closest .meal-card"),
          attribute("hx-swap", "outerHTML swap:1s"),
        ],
        [text("Delete")],
      ),
    ]),
  ])
}
```

## Testing

Comprehensive test suite included at:
```
test/meal_planner/ui/components/macro_progress_test.gleam
```

Run tests:
```bash
gleam test --target erlang --module macro_progress_test
```

Tests cover:
- Component rendering
- Color coding logic
- Accessibility attributes
- HTMX integration
- Edge cases (zero goals, exceeding caps)
- Fractional value handling

## API Reference

### Types

#### `MacroProgress`
```gleam
pub type MacroProgress {
  MacroProgress(
    macro_name: String,  // Display name (e.g., "Protein")
    current: Float,      // Current value
    goal: Float,         // Target value
    unit: String,        // Unit (e.g., "g", " kcal")
  )
}
```

#### `MacroSet`
```gleam
pub type MacroSet {
  MacroSet(
    protein: MacroProgress,
    fat: MacroProgress,
    carbs: MacroProgress,
    calories: MacroProgress,
  )
}
```

#### `ProgressStyle`
```gleam
pub type ProgressStyle {
  Linear    // Horizontal bars
  Circular  // SVG circles
  Compact   // Minimal display
}
```

### Functions

#### `macro_progress(name, current, goal, unit) -> MacroProgress`
Create a single macro progress instance.

#### `macro_set(p_cur, p_goal, f_cur, f_goal, c_cur, c_goal, cal_cur, cal_goal) -> MacroSet`
Create complete macro set with P/F/C/Calories.

#### `render_progress_bar(progress) -> Element(msg)`
Render linear progress bar.

#### `render_circular_progress(progress) -> Element(msg)`
Render circular SVG progress indicator.

#### `render_compact_progress(progress) -> Element(msg)`
Render compact single-line progress.

#### `render_macro_set_linear(macros) -> Element(msg)`
Render all macros as linear bars.

#### `render_macro_set_circular(macros) -> Element(msg)`
Render all macros as circles.

#### `render_macro_set_compact(macros) -> Element(msg)`
Render all macros compactly.

#### `render_macro_progress_with_refresh(macros, style, url) -> Element(msg)`
Render with HTMX auto-refresh enabled.

## Browser Support

- ✅ Chrome/Edge 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

SVG and CSS transitions are widely supported.

## License

Part of the meal-planner project.
