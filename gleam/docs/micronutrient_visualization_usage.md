# Micronutrient Visualization Component

## Overview

The micronutrient visualization component provides a comprehensive, visually appealing way to display vitamin and mineral data with color-coded progress bars, daily value percentages, and responsive design.

## Component Location

- **Component**: `/gleam/src/meal_planner/ui/components/micronutrient_panel.gleam`
- **Styling**: `/gleam/priv/static/css/components.css`
- **Tests**: `/gleam/test/meal_planner/ui_components_micronutrient_panel_test.gleam`

## Features

### 1. Visual Progress Bars
- Each nutrient displayed with a horizontal progress bar
- Animated shimmer effect for visual appeal
- Smooth width transitions (500ms cubic-bezier)

### 2. Color Coding System
- **Yellow** (< 50% DV): Deficiency warning
- **Green** (50-100% DV): Optimal range
- **Orange** (100-150% DV): High but acceptable
- **Red** (> 150% DV): Excessive intake warning

### 3. Daily Value Tracking
FDA-recommended daily values for adults:
- Vitamins: A, C, D, E, K, B6, B12, Folate, Thiamin, Riboflavin, Niacin
- Minerals: Calcium, Iron, Magnesium, Phosphorus, Potassium, Zinc
- Other: Fiber, Sodium, Cholesterol, Sugar

### 4. Responsive Design
- Desktop: Full layout with all details
- Mobile: Stacked layout with adjusted spacing
- Dark mode support (prefers-color-scheme)

## Usage Examples

### Basic Usage

```gleam
import meal_planner/ui/components/micronutrient_panel
import meal_planner/types.{type Micronutrients, Micronutrients}
import gleam/option.{Some}

// Create micronutrient data
let micros = Micronutrients(
  vitamin_c: Some(45.0),
  calcium: Some(650.0),
  iron: Some(9.0),
  // ... other nutrients
)

// Render full panel
let html = micronutrient_panel.micronutrient_panel(Some(micros))
```

### Compact Summary (for cards)

```gleam
// Show brief summary: "11 vitamins, 6 minerals"
let summary = micronutrient_panel.micronutrient_summary(Some(micros))
```

### Custom Section Rendering

```gleam
let dv = micronutrient_panel.standard_daily_values()
let vitamins = micronutrient_panel.extract_vitamins(micros, dv)

let html = micronutrient_panel.micronutrient_section("Vitamins", vitamins)
```

### Individual Nutrient Bar

```gleam
let item = micronutrient_panel.MicronutrientItem(
  name: "Vitamin C",
  amount: 45.0,
  unit: "mg",
  daily_value: 90.0,
  percentage: 50.0,
  category: "vitamin",
)

let bar = micronutrient_panel.micronutrient_bar(item)
```

## HTML Structure

### Full Panel
```html
<div class="micronutrient-panel">
  <div class="micro-section">
    <h3 class="micro-section-title">Vitamins</h3>
    <div class="micro-list">
      <div class="micronutrient-bar status-optimal">
        <div class="micro-header">
          <span class="micro-name">Vitamin C</span>
          <span class="micro-value">45.0mg / 90.0mg</span>
        </div>
        <div class="micro-progress">
          <div class="micro-fill" style="width: 50%"></div>
        </div>
        <div class="micro-percentage">50% DV</div>
      </div>
      <!-- More nutrients... -->
    </div>
  </div>
  <!-- Minerals and Other sections... -->
</div>
```

### Compact Summary
```html
<div class="micro-summary">
  <span class="badge badge-vitamin">11 vitamins</span>
  <span class="badge badge-mineral">6 minerals</span>
</div>
```

## CSS Classes

### Main Container
- `.micronutrient-panel` - Main panel container
- `.micronutrient-panel.empty` - Empty state styling

### Section Grouping
- `.micro-section` - Section container (Vitamins, Minerals, Other)
- `.micro-section-title` - Section header
- `.micro-list` - List of nutrients in section

### Individual Nutrients
- `.micronutrient-bar` - Single nutrient container
- `.micro-header` - Name and value row
- `.micro-name` - Nutrient name
- `.micro-value` - Amount/daily value display
- `.micro-progress` - Progress bar container
- `.micro-fill` - Filled portion of progress bar
- `.micro-percentage` - Percentage label

### Status Colors
- `.status-low` - Yellow (< 50% DV)
- `.status-optimal` - Green (50-100% DV)
- `.status-high` - Orange (100-150% DV)
- `.status-excess` - Red (> 150% DV)

### Summary
- `.micro-summary` - Summary container
- `.badge-vitamin` - Vitamin count badge
- `.badge-mineral` - Mineral count badge

## Integration Points

### Dashboard Page
```gleam
// Add to daily log view
card_with_header(
  "Micronutrients",
  [micronutrient_panel.micronutrient_panel(daily_log.total_micronutrients)]
)
```

### Food Log Entry
```gleam
// Show in food detail card
food_card_with_micros(
  food_name: "Grilled Chicken Breast",
  summary: micronutrient_panel.micronutrient_summary(micros)
)
```

### Recipe Detail
```gleam
// Full panel in recipe view
section([
  h2("Nutritional Information"),
  micronutrient_panel.micronutrient_panel(recipe.micronutrients)
])
```

## Customization

### Custom Daily Values
```gleam
// Create custom DV for specific user needs
let custom_dv = micronutrient_panel.DailyValues(
  vitamin_c_mg: 120.0,  // Higher for athletes
  calcium_mg: 1500.0,   // Higher for elderly
  // ... other values
)

let vitamins = micronutrient_panel.extract_vitamins(micros, custom_dv)
```

### Color Theme Override
```css
/* Override status colors in your CSS */
.micronutrient-bar.status-optimal {
  border-left-color: #00c853; /* Custom green */
}

.status-optimal .micro-fill {
  background-color: #00c853;
}
```

## Testing

Run the comprehensive test suite:

```bash
gleam test --target erlang
```

Test coverage includes:
- Daily value calculations
- Data extraction (vitamins, minerals, other)
- Component rendering
- Color coding logic
- Empty state handling
- Summary component
- Edge cases (0%, 100%, 200% DV)

## Performance Considerations

1. **Data Extraction**: Nutrients with `None` values are filtered out automatically
2. **Rendering**: All components return HTML strings (SSR-compatible)
3. **Animations**: CSS-based, no JavaScript required
4. **Responsive**: Uses CSS media queries, no JS event listeners

## Accessibility

- Semantic HTML structure
- Color is not the only indicator (text percentages provided)
- Hover states for better interactivity
- Mobile-friendly touch targets
- Screen reader friendly (consider adding ARIA labels)

## Future Enhancements

Potential improvements (not yet implemented):
- [ ] Radial/circular progress charts
- [ ] Comparison view (actual vs target side-by-side)
- [ ] Historical tracking (trends over time)
- [ ] Export as image/PDF
- [ ] Custom nutrient groupings
- [ ] Tooltips with additional info
- [ ] Keyboard navigation support

## Related Documentation

- `/gleam/src/meal_planner/types.gleam` - Micronutrients type definition
- `/gleam/priv/static/css/design_tokens.css` - Color and spacing tokens
- `/docs/component_signatures.md` - Component architecture
- `/docs/ui_architecture.md` - Overall UI structure

## Support

For issues or questions:
1. Check test file for usage examples
2. Review type definitions in `types.gleam`
3. Inspect CSS for customization options
4. Refer to FDA daily value guidelines for context
