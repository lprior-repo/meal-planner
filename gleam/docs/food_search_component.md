# Food Search Filter Chips Component

## Overview

The food search component provides a reusable UI for food search filtering functionality. It includes:
- Clickable filter chips (All, Verified Only, Branded, By Category)
- Category dropdown filter
- Type-safe Gleam implementation using Lustre
- Full accessibility support (ARIA attributes)

## File Location

```
gleam/src/meal_planner/ui/components/food_search.gleam
```

## Component Structure

### Types

```gleam
pub type FilterType {
  All
  VerifiedOnly
  Branded
  ByCategory
}

pub type FilterChip {
  FilterChip(label: String, filter_type: FilterType, selected: Bool)
}
```

## Public Functions

### `render_filter_chip(chip: FilterChip) -> element.Element(msg)`

Renders a single filter chip button.

**Features:**
- Clickable button with data attributes
- CSS class based on selection state
- ARIA attributes for accessibility

**Renders:**
```html
<button class="filter-chip filter-chip-selected"
        data-filter="all"
        aria-selected="true"
        type="button">
  All
</button>
```

### `render_filter_chips(chips: List(FilterChip)) -> element.Element(msg)`

Renders multiple filter chips in a container.

**Features:**
- Container div with role="group"
- ARIA label for accessibility
- Maps each chip to `render_filter_chip`

**Renders:**
```html
<div class="filter-chips-container">
  <div class="filter-chips" role="group" aria-label="Food search filters">
    <button class="filter-chip filter-chip-selected" data-filter="all">All</button>
    <button class="filter-chip" data-filter="verified">Verified Only</button>
    <button class="filter-chip" data-filter="branded">Branded</button>
  </div>
</div>
```

### `render_filter_chips_with_dropdown(chips: List(FilterChip), categories: List(String)) -> element.Element(msg)`

Renders filter chips with integrated category dropdown.

**Features:**
- All standard filter chips
- Category dropdown (disabled by default)
- Dropdown enabled only when "By Category" chip is selected
- Dynamic class application based on selection state

**Renders:**
```html
<div class="filter-chips-container">
  <div class="filter-chips" role="group" aria-label="Food search filters">
    <!-- Chips here -->
  </div>
  <div class="filter-dropdown-container">
    <select class="filter-dropdown" data-filter="category" disabled>
      <option value="">Select Category...</option>
      <option value="Vegetables">Vegetables</option>
      <!-- More categories -->
    </select>
  </div>
</div>
```

### `default_filter_chips() -> List(FilterChip)`

Returns standard filter chips with "All" selected.

### `default_categories() -> List(String)`

Returns common food category list:
- Vegetables
- Fruits
- Proteins
- Grains
- Dairy
- Oils & Fats
- Condiments
- Beverages
- Snacks
- Prepared Foods

### `update_selected_filter(chips: List(FilterChip), target_filter: FilterType) -> List(FilterChip)`

Updates the selection state of chips. Sets the target filter as selected and deselects others (single-selection behavior).

## Usage Examples

### Basic Usage

```gleam
import meal_planner/ui/components/food_search as fs

pub fn render_food_search_page() {
  fs.default_filter_chips()
  |> fs.render_filter_chips
}
```

### With Dropdown

```gleam
pub fn render_food_search_with_category() {
  let chips = fs.default_filter_chips()
  let categories = fs.default_categories()

  fs.render_filter_chips_with_dropdown(chips, categories)
}
```

### Handle Filter Selection

```gleam
pub fn handle_filter_change(selected: fs.FilterType) {
  let chips = fs.default_filter_chips()
  let updated = fs.update_selected_filter(chips, selected)

  fs.render_filter_chips_with_dropdown(updated, fs.default_categories())
}
```

### Custom Categories

```gleam
pub fn render_with_custom_categories() {
  let chips = fs.default_filter_chips()
  let categories = [
    "Meat & Poultry",
    "Seafood",
    "Legumes",
  ]

  fs.render_filter_chips_with_dropdown(chips, categories)
}
```

## CSS Classes

### Container Classes

- `.filter-chips-container` - Main container wrapping all filter elements
- `.filter-chips` - Container for chip buttons
- `.filter-dropdown-container` - Container for the category dropdown

### Chip Classes

- `.filter-chip` - Base chip button style
- `.filter-chip-selected` - Applied to selected chip (use for highlighting)

### Dropdown Classes

- `.filter-dropdown` - Base dropdown style
- `.filter-dropdown-active` - Applied when category filter is selected

## Data Attributes

Each chip has a `data-filter` attribute for JavaScript interaction:

```
data-filter="all"           // All foods filter
data-filter="verified"      // Verified only filter
data-filter="branded"       // Branded foods filter
data-filter="category"      // Category dropdown
```

## Accessibility

The component includes comprehensive accessibility features:

- **ARIA Labels:** `aria-label="Food search filters"` on the group
- **ARIA Selected:** `aria-selected="true"` or `"false"` on chips
- **Semantic HTML:** Uses `<button>` for clickable elements
- **Role Attributes:** `role="group"` on filter container
- **Form Elements:** `<select>` with proper labels for dropdown

## Example CSS Styling

```css
.filter-chips-container {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 1rem;
}

.filter-chips {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.filter-chip {
  padding: 0.5rem 1rem;
  border: 1px solid #ccc;
  background-color: #f5f5f5;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.875rem;
  transition: all 0.2s ease;
}

.filter-chip:hover {
  border-color: #999;
  background-color: #eee;
}

.filter-chip-selected {
  border-color: #0066cc;
  background-color: #0066cc;
  color: white;
}

.filter-dropdown-container {
  display: flex;
}

.filter-dropdown {
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
  cursor: pointer;
}

.filter-dropdown:disabled {
  background-color: #f5f5f5;
  color: #999;
  cursor: not-allowed;
}

.filter-dropdown-active {
  border-color: #0066cc;
  background-color: #f9f9f9;
}
```

## Example JavaScript Integration

```javascript
// Handle filter chip clicks
document.querySelectorAll('[data-filter]').forEach(element => {
  element.addEventListener('click', (e) => {
    const filterType = e.target.dataset.filter;
    console.log('Filter changed:', filterType);

    // Update filter state, refetch data, etc.
    applyFilter(filterType);
  });
});

// Handle category dropdown changes
const categoryDropdown = document.querySelector('[data-filter="category"]');
if (categoryDropdown) {
  categoryDropdown.addEventListener('change', (e) => {
    const category = e.target.value;
    console.log('Category selected:', category);

    // Refetch data with category filter
    refetchResults(category);
  });
}
```

## Return Type

All render functions return `element.Element(msg)` which is compatible with:
- Lustre applications
- Server-side rendering (SSR)
- Component composition
- Type-safe element manipulation

## Integration with Food Search API

The filter chips are designed to work with food search functionality:

1. User clicks a chip (e.g., "Verified Only")
2. JavaScript captures the click via `data-filter` attribute
3. Filter state is updated
4. API call made with filter parameters
5. Results re-rendered

Example API parameters:
- `/api/food-search?query=chicken&filter=all`
- `/api/food-search?query=chicken&filter=verified`
- `/api/food-search?query=chicken&filter=branded`
- `/api/food-search?query=chicken&filter=category&category=Proteins`

## Testing

The component is fully type-safe and can be tested:

```gleam
import gleeunit/should
import meal_planner/ui/components/food_search as fs

pub fn test_default_chips() {
  fs.default_filter_chips()
  |> list.length
  |> should.equal(4)
}

pub fn test_update_selection() {
  let chips = fs.default_filter_chips()
  let updated = fs.update_selected_filter(chips, fs.VerifiedOnly)

  list.find(updated, fn(c) { c.filter_type == fs.VerifiedOnly })
  |> option.map(fn(c) { c.selected })
  |> should.equal(option.Some(True))
}
```

## Component Variants

The module provides flexibility for different use cases:

1. **Simple Chips** - Basic filter chips without dropdown
2. **Chips with Dropdown** - Full featured with category selection
3. **Custom Chips** - Build your own chip list with any labels/filters
4. **Dynamic Updates** - Update selection state programmatically

Choose the variant that best fits your use case.
