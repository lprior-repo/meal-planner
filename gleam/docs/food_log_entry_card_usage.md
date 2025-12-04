# Food Log Entry Card Component Usage Guide

## Overview

The `food_log_entry_card` component provides beautiful, interactive food log entry cards with full HTMX integration. This component implements **meal-planner-51y: Build Food Log Entry UI Cards**.

## Features

- ✅ **Beautiful Design**: Card-based layout with clean typography
- ✅ **Macro Visualization**: Color-coded bar chart showing protein/fat/carbs distribution
- ✅ **HTMX Integration**: Edit and delete actions without JavaScript
- ✅ **Responsive**: Mobile-friendly design with compact variant
- ✅ **Smooth Animations**: HTMX swap transitions (1s fade)
- ✅ **Accessible**: Proper ARIA labels and semantic HTML

## Component API

### Main Component

```gleam
pub fn render_log_entry_card(card: ui_types.LogEntryCard) -> Element(msg)
```

Renders a full food log entry card with:
- Food name and meal type badge
- Portion size and calories
- Macro breakdown visualization (bar + stats)
- Edit button (HTMX)
- Delete button with confirmation (HTMX)

### Compact Variant

```gleam
pub fn render_log_entry_card_compact(card: ui_types.LogEntryCard) -> Element(msg)
```

Renders a compact version ideal for mobile or dense layouts:
- No macro bar (stats only)
- Icon-only action buttons
- Reduced spacing

### List Wrapper

```gleam
pub fn render_log_entry_list(cards: List(ui_types.LogEntryCard)) -> Element(msg)
```

Wraps multiple cards in a container with proper spacing.

## Data Type

```gleam
pub type LogEntryCard {
  LogEntryCard(
    entry_id: String,       // Unique ID (e.g., "log-123")
    food_name: String,       // Food description
    portion: Float,          // Portion amount
    unit: String,            // Unit (oz, cups, g, etc.)
    protein: Float,          // Protein in grams
    fat: Float,              // Fat in grams
    carbs: Float,            // Carbs in grams
    calories: Float,         // Total calories
    meal_type: String,       // breakfast, lunch, dinner, snack
    logged_at: String,       // Timestamp display string
  )
}
```

## Usage Examples

### Basic Usage

```gleam
import meal_planner/ui/components/food_log_entry_card
import meal_planner/ui/types/ui_types

pub fn render_lunch_entry() {
  let card = ui_types.LogEntryCard(
    entry_id: "log-456",
    food_name: "Grilled Chicken Breast",
    portion: 6.0,
    unit: "oz",
    protein: 52.0,
    fat: 6.0,
    carbs: 0.0,
    calories: 276.0,
    meal_type: "lunch",
    logged_at: "2025-12-04 12:30",
  )

  food_log_entry_card.render_log_entry_card(card)
}
```

### Multiple Entries

```gleam
pub fn render_daily_log(entries: List(FoodLogEntry)) {
  let cards = entries
    |> list.map(fn(entry) {
      ui_types.LogEntryCard(
        entry_id: entry.id,
        food_name: entry.recipe_name,
        portion: entry.servings,
        unit: "servings",
        protein: entry.macros.protein,
        fat: entry.macros.fat,
        carbs: entry.macros.carbs,
        calories: macros_calories(entry.macros),
        meal_type: meal_type_to_string(entry.meal_type),
        logged_at: format_timestamp(entry.logged_at),
      )
    })

  food_log_entry_card.render_log_entry_list(cards)
}
```

### Compact Mobile View

```gleam
pub fn render_mobile_log(cards: List(ui_types.LogEntryCard)) {
  div([class("mobile-log-view")],
    cards |> list.map(food_log_entry_card.render_log_entry_card_compact)
  )
}
```

## HTMX Integration

### Server Endpoints Required

Your Gleam web server needs to implement these endpoints:

#### Edit Endpoint
```gleam
// GET /logs/{id}/edit
// Returns: HTMX fragment with edit form
pub fn handle_edit_log_entry(req: Request, id: String) -> Response {
  // Fetch log entry by id
  // Return edit form as HTML fragment
  // The form will replace the card (hx-target="#log-{id}")
}
```

#### Delete Endpoint
```gleam
// DELETE /logs/{id}
// Returns: Empty response (causes card removal via swap)
pub fn handle_delete_log_entry(req: Request, id: String) -> Response {
  // Delete log entry by id
  // Return empty or success message
  // The card will be removed (hx-swap="outerHTML swap:1s")
}
```

### HTMX Attributes Explained

**Edit Button:**
```html
<button
  hx-get="/logs/log-123/edit"
  hx-target="#log-log-123"
  hx-swap="outerHTML"
  aria-label="Edit entry">
  Edit
</button>
```
- `hx-get`: Fetches edit form from server
- `hx-target`: Replaces entire card with form
- `hx-swap="outerHTML"`: Replace card element completely

**Delete Button:**
```html
<button
  hx-delete="/logs/log-123"
  hx-target="#log-log-123"
  hx-swap="outerHTML swap:1s"
  hx-confirm="Delete this entry?"
  aria-label="Delete entry">
  Delete
</button>
```
- `hx-delete`: Sends DELETE request
- `hx-confirm`: Shows browser confirmation dialog
- `hx-swap="outerHTML swap:1s"`: Fades out over 1 second

## CSS Classes

The component uses these CSS classes (implement in your stylesheet):

### Card Structure
- `.food-log-entry-card` - Main card container
- `.card-header` - Header section
- `.card-body` - Body section
- `.card-actions` - Action button container

### Content Elements
- `.food-name` - Food title
- `.meal-type-badge` - Meal type indicator
- `.meal-type-breakfast`, `.meal-type-lunch`, etc. - Meal-specific colors
- `.logged-time` - Timestamp
- `.portion-info` - Portion display
- `.calorie-count` - Calorie display

### Macro Visualization
- `.macro-breakdown` - Macro section container
- `.macro-breakdown-bar` - Horizontal bar container
- `.macro-segment` - Individual bar segment
- `.macro-protein`, `.macro-fat`, `.macro-carbs` - Color classes
- `.macro-stats` - Stats row container
- `.macro-stat` - Individual stat

### Buttons
- `.btn-edit` - Edit button
- `.btn-delete` - Delete button
- `.btn-danger` - Danger variant (red)

### Compact Variant
- `.compact` - Compact modifier class
- `.compact-header` - Compact header
- `.compact-details` - Compact details row
- `.btn-icon` - Icon-only button

## Styling Examples

```css
/* Card base styles */
.food-log-entry-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  padding: 16px;
  margin-bottom: 12px;
}

/* Macro visualization */
.macro-breakdown-bar {
  display: flex;
  height: 8px;
  border-radius: 4px;
  overflow: hidden;
  margin: 8px 0;
}

.macro-segment {
  transition: all 0.3s ease;
}

.macro-protein { background: #3b82f6; } /* Blue */
.macro-fat { background: #fbbf24; }     /* Yellow */
.macro-carbs { background: #10b981; }   /* Green */

/* Meal type badges */
.meal-type-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 600;
}

.meal-type-breakfast { background: #fef3c7; color: #92400e; }
.meal-type-lunch { background: #dbeafe; color: #1e40af; }
.meal-type-dinner { background: #e9d5ff; color: #6b21a8; }
.meal-type-snack { background: #d1fae5; color: #065f46; }

/* Action buttons */
.btn-edit {
  background: #f3f4f6;
  color: #374151;
}

.btn-delete.btn-danger {
  background: #fef2f2;
  color: #dc2626;
}

/* HTMX swap animation */
.htmx-swapping {
  opacity: 0;
  transition: opacity 1s ease-out;
}
```

## Testing

Tests are included in `/gleam/test/food_log_entry_card_test.gleam`:

```bash
cd gleam
gleam test --target erlang
```

Tests cover:
- Type construction
- Rendering (full, compact, list)
- Edge cases (zero macros, high protein)

## Mobile Responsiveness

For mobile devices, use the compact variant or add responsive CSS:

```css
@media (max-width: 640px) {
  .food-log-entry-card {
    padding: 12px;
  }

  .card-actions {
    flex-direction: column;
  }

  .macro-stats {
    font-size: 12px;
  }
}
```

## Accessibility

The component includes:
- Semantic HTML structure
- `aria-label` attributes on action buttons
- Color contrast for WCAG compliance (implement in CSS)
- Keyboard navigation support (via native buttons)

## Related Components

- `daily_log.gleam` - Daily log timeline with meal sections
- `card.gleam` - Base card components
- `button.gleam` - Button components

## Next Steps

To use this component in your app:

1. ✅ Add CSS styles for all classes
2. ✅ Implement `/logs/{id}/edit` endpoint
3. ✅ Implement `/logs/{id}` DELETE endpoint
4. ✅ Include HTMX library in base template
5. ✅ Integrate with food log page

## Example Server Integration

```gleam
import meal_planner/ui/components/food_log_entry_card
import meal_planner/storage
import wisp

pub fn log_page(req: Request, user_id: String) -> Response {
  // Fetch user's food log entries
  case storage.get_daily_log(db, user_id, today()) {
    Ok(daily_log) -> {
      // Convert to UI cards
      let cards = daily_log.entries
        |> list.map(fn(entry) {
          ui_types.LogEntryCard(
            entry_id: entry.id,
            // ... map fields ...
          )
        })

      // Render page with cards
      let content = food_log_entry_card.render_log_entry_list(cards)
      wisp.html_response(render_page(content), 200)
    }
    Error(_) -> wisp.internal_server_error()
  }
}
```

## Support

For issues or questions about this component:
- Check Bead: `meal-planner-51y`
- Review test file: `food_log_entry_card_test.gleam`
- See component source: `food_log_entry_card.gleam`
