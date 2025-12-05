# Food Log Page Component Usage

## Overview

The `food_log` page component provides a complete food log interface with date navigation, entry management, and real-time updates via HTMX.

**File**: `gleam/src/meal_planner/ui/pages/food_log.gleam`

**Related Components**:
- `food_log_entry_card.gleam` - Individual entry cards with edit/delete
- `layout.gleam` - Container and layout utilities

**Bead**: meal-planner-51y

## Features

✅ **Date Navigation**: Previous/next day with URL updates
✅ **Daily Totals**: Aggregated calories and macros
✅ **Entry List**: Scrollable list with auto-refresh
✅ **Add Entry**: Modal form via HTMX
✅ **Edit/Delete**: Individual card actions
✅ **Empty State**: Friendly message when no entries
✅ **Mobile Support**: Compact variant for small screens
✅ **Accessibility**: ARIA landmarks, semantic HTML

## Basic Usage

```gleam
import meal_planner/ui/pages/food_log
import meal_planner/ui/types/ui_types

// Sample data
let page_data = food_log.FoodLogPageData(
  date: "2025-12-05",
  entries: [
    ui_types.LogEntryCard(
      entry_id: "log-1",
      food_name: "Grilled Chicken Breast",
      portion: 6.0,
      unit: "oz",
      protein: 52.0,
      fat: 6.0,
      carbs: 0.0,
      calories: 276.0,
      meal_type: "lunch",
      logged_at: "12:30 PM",
    ),
    ui_types.LogEntryCard(
      entry_id: "log-2",
      food_name: "Brown Rice",
      portion: 1.0,
      unit: "cup",
      protein: 5.0,
      fat: 2.0,
      carbs: 45.0,
      calories: 218.0,
      meal_type: "lunch",
      logged_at: "12:30 PM",
    ),
  ],
  total_calories: 494.0,
  total_protein: 57.0,
  total_fat: 8.0,
  total_carbs: 45.0,
)

// Render full page
let page_html = food_log.render_food_log_page(page_data)

// Or render compact mobile version
let mobile_html = food_log.render_food_log_page_compact(page_data)
```

## HTMX Integration

### Date Navigation

**Previous Day**:
```html
<button hx-get="/logs?date=prev&current=2025-12-05"
        hx-target="main"
        hx-swap="innerHTML"
        hx-push-url="true">
  ← Previous Day
</button>
```

**Next Day**:
```html
<button hx-get="/logs?date=next&current=2025-12-05"
        hx-target="main"
        hx-swap="innerHTML"
        hx-push-url="true">
  Next Day →
</button>
```

### Add Entry

**Modal Trigger**:
```html
<button hx-get="/logs/new"
        hx-target="#modal-container"
        hx-swap="innerHTML">
  + Add Entry
</button>
```

**Server Response**: Returns modal form HTML

### Auto-Refresh Entries

**Polling Container**:
```html
<div id="entries-list"
     hx-get="/logs/entries?date=2025-12-05"
     hx-trigger="every 30s"
     hx-swap="innerHTML">
  <!-- Entry cards here -->
</div>
```

**Server Response**: Returns updated list of entry cards

### Individual Entry Actions

Handled by `food_log_entry_card.gleam`:

**Edit**:
```html
<button hx-get="/logs/log-123/edit"
        hx-target="#log-123"
        hx-swap="outerHTML">
  Edit
</button>
```

**Delete**:
```html
<button hx-delete="/logs/log-123"
        hx-target="#log-123"
        hx-swap="outerHTML swap:1s"
        hx-confirm="Delete this entry?">
  Delete
</button>
```

## Server-Side Implementation

### Route: GET /logs

**Query Parameters**:
- `date` - Specific date (YYYY-MM-DD) or "prev"/"next"
- `current` - Current date (when using prev/next)

**Response**: Full page HTML

```gleam
import meal_planner/ui/pages/food_log
import meal_planner/storage

pub fn handle_food_log_page(req: Request) -> Response {
  // Parse date from query or use today
  let date = parse_date_param(req) |> result.unwrap(today())

  // Fetch entries from database
  let entries = storage.get_log_entries_for_date(db, date)
    |> list.map(to_log_entry_card)

  // Calculate totals
  let totals = calculate_daily_totals(entries)

  // Build page data
  let page_data = food_log.FoodLogPageData(
    date: date,
    entries: entries,
    total_calories: totals.calories,
    total_protein: totals.protein,
    total_fat: totals.fat,
    total_carbs: totals.carbs,
  )

  // Render and respond
  food_log.render_food_log_page(page_data)
  |> element.to_string()
  |> response.html(200)
}
```

### Route: GET /logs/entries

**Query Parameters**:
- `date` - Date to fetch entries for

**Response**: Entry cards HTML (for polling)

```gleam
pub fn handle_entries_fragment(req: Request) -> Response {
  let date = parse_date_param(req)
  let entries = storage.get_log_entries_for_date(db, date)
    |> list.map(to_log_entry_card)

  // Return just the entries (no wrapper)
  case entries {
    [] ->
      // Empty state
      div([class("empty-state")], [...])
      |> element.to_string()
    _ ->
      entries
      |> list.map(food_log_entry_card.render_log_entry_card)
      |> div([])
      |> element.to_string()
  }
  |> response.html(200)
}
```

### Route: GET /logs/new

**Response**: Modal form HTML

```gleam
pub fn handle_new_entry_form(req: Request) -> Response {
  // Return modal with form
  div([class("modal active")], [
    div([class("modal-content")], [
      h2([], [text("Add Food Entry")]),
      form([
        attribute("hx-post", "/logs"),
        attribute("hx-target", "#entries-list"),
        attribute("hx-swap", "afterbegin"),
      ], [
        // Form fields
        input([name("food_id"), required()]),
        input([name("portion"), type_("number")]),
        select([name("meal_type")], [...]),
        button([type_("submit")], [text("Add Entry")]),
      ])
    ])
  ])
  |> element.to_string()
  |> response.html(200)
}
```

### Route: POST /logs

**Form Data**:
- `food_id` - FDC ID of food
- `portion` - Portion size
- `meal_type` - breakfast/lunch/dinner/snack

**Response**: New entry card HTML (prepended to list)

```gleam
pub fn handle_create_entry(req: Request) -> Response {
  // Parse form data
  let form = parse_form(req)

  // Create log entry
  let entry = storage.create_food_log_entry(db, form)

  // Convert to card data
  let card = to_log_entry_card(entry)

  // Return new card HTML
  food_log_entry_card.render_log_entry_card(card)
  |> element.to_string()
  |> response.html(201)
}
```

## Responsive Design

### Desktop (1024px+)

- Full layout with all features
- Three-column grid for entries
- Full-size cards with macro bars
- All buttons with labels

### Tablet (768px)

- Two-column grid
- Standard cards
- Abbreviated labels

### Mobile (320px)

- Single column
- Compact cards (no macro bars)
- Icon-only buttons
- Floating action button for add entry

**Usage**:
```gleam
// Detect viewport and render appropriate version
case viewport_width {
  w if w < 768 -> food_log.render_food_log_page_compact(data)
  _ -> food_log.render_food_log_page(data)
}
```

## Accessibility

### Keyboard Navigation

- Tab through all interactive elements
- Enter/Space to activate buttons
- Arrow keys for date navigation

### Screen Readers

- Proper heading hierarchy (h1 → h2)
- ARIA landmarks (`role="main"`, `role="navigation"`)
- ARIA labels on icon buttons
- Live region announcements for updates

### WCAG Compliance

- ✅ Semantic HTML5
- ✅ Color contrast (AA minimum)
- ✅ Focus indicators
- ✅ Alt text for empty state icon

## Styling

### CSS Classes

**Layout**:
- `.page-title` - Page heading
- `.date-navigation` - Date nav container
- `.daily-totals-summary` - Totals card
- `.add-entry-section` - Add button container
- `.entries-list` - Scrollable entries container
- `.empty-state` - Empty state message

**Components**:
- `.current-date` - Selected date display
- `.totals-grid` - Four-column totals grid
- `.total-item` - Individual total (calories/macros)
- `.btn-fab` - Floating action button (mobile)

**State Classes**:
- `.compact` - Mobile/compact variant
- `.empty` - Empty state
- `.modal-root` - Modal container

### Sample CSS

```css
/* Date Navigation */
.date-navigation {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem;
}

/* Daily Totals */
.daily-totals-summary {
  background: var(--surface);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.totals-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
}

.total-item {
  text-align: center;
}

.total-value {
  font-size: 1.5rem;
  font-weight: bold;
  color: var(--text-primary);
}

/* Entries List */
.entries-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 1.5rem;
  max-height: 600px;
  overflow-y: auto;
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 4rem 2rem;
  color: var(--text-secondary);
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

/* Mobile Compact */
@media (max-width: 768px) {
  .entries-list {
    grid-template-columns: 1fr;
  }

  .totals-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .btn-fab {
    position: fixed;
    bottom: 2rem;
    right: 2rem;
    width: 56px;
    height: 56px;
    border-radius: 50%;
    box-shadow: var(--shadow-lg);
  }
}
```

## Testing

### Manual Testing Checklist

- [ ] Date navigation updates URL and content
- [ ] Add entry button opens modal
- [ ] Form submission adds new entry
- [ ] Edit button loads edit form
- [ ] Delete button shows confirmation
- [ ] Auto-refresh polls every 30s
- [ ] Empty state shows when no entries
- [ ] Totals update with entries
- [ ] Responsive layout works on mobile
- [ ] Keyboard navigation works
- [ ] Screen reader announces changes

### Integration Testing

```gleam
import gleeunit
import gleeunit/should

pub fn render_food_log_page_test() {
  let data = food_log.FoodLogPageData(
    date: "2025-12-05",
    entries: [],
    total_calories: 0.0,
    total_protein: 0.0,
    total_fat: 0.0,
    total_carbs: 0.0,
  )

  let html = food_log.render_food_log_page(data)
    |> element.to_string()

  // Should contain page title
  html
  |> string.contains("Food Log - 2025-12-05")
  |> should.be_true()

  // Should contain empty state
  html
  |> string.contains("No food entries yet")
  |> should.be_true()
}
```

## Next Steps

1. **Backend Routes**: Implement all HTMX endpoints
2. **Modal Forms**: Create add/edit entry forms
3. **Database Integration**: Wire up to storage layer
4. **CSS Styling**: Add design system styles
5. **Testing**: Write comprehensive test suite
6. **Analytics**: Track user interactions

## Related Files

- `gleam/src/meal_planner/ui/pages/food_log.gleam` - This component
- `gleam/src/meal_planner/ui/components/food_log_entry_card.gleam` - Entry cards
- `gleam/src/meal_planner/ui/types/ui_types.gleam` - Type definitions
- `gleam/src/meal_planner/ui/components/layout.gleam` - Layout utilities

## Support

See: Bead meal-planner-51y for task details and discussion.
