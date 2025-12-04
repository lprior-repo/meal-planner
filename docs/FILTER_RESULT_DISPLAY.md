# Filter Result Display Component

## Overview

This document describes the new filter result count display feature for the food search interface. The feature includes:

1. **Result Count Display** - Shows "X results" above search results
2. **Active Filter Tags** - Displays currently active filters as removable badges
3. **Individual Filter Removal** - Click any filter tag to remove that single filter
4. **Clear All Filters Button** - One-click button to clear all active filters
5. **Real-Time Updates** - Count and filters update dynamically as user interacts

## Components

### Gleam Component: `search_results_with_count`

Located in: `/home/lewis/src/meal-planner/gleam/src/meal_planner/ui/components/forms.gleam`

#### Function Signature

```gleam
pub fn search_results_with_count(
  items: List(#(Int, String, String, String)),
  result_count: Int,
  active_filters: List(#(String, String)),
  show_clear_all: Bool,
) -> String
```

#### Parameters

- **items**: List of search result tuples containing `(id, name, type, category)`
- **result_count**: Number of results to display
- **active_filters**: List of active filters as tuples of `(filter_name, filter_value)`
  - Example: `[("category", "Vegetables"), ("verified", "true")]`
- **show_clear_all**: Boolean to show/hide the "Clear All Filters" button

#### Usage Examples

**Example 1: Basic usage with results and filters**

```gleam
let items = [
  (#(1, "Broccoli", "Food", "Vegetables")),
  (#(2, "Carrots", "Food", "Vegetables")),
]

let active_filters = [
  ("category", "Vegetables"),
  ("verified", "true"),
]

search_results_with_count(
  items,
  2,
  active_filters,
  True  // Show Clear All button
)
```

**Example 2: No active filters**

```gleam
search_results_with_count(
  items,
  50,
  [],  // No filters
  False  // Hide Clear All button when no filters
)
```

**Example 3: Single filter**

```gleam
search_results_with_count(
  results,
  15,
  [("category", "Fruits")],
  True
)
```

#### Output HTML Structure

```html
<div class="search-results-container">
  <div class="search-results-header">
    <div class="search-results-count" role="status" aria-live="polite">
      2 results
    </div>

    <div class="active-filters-container">
      <div class="active-filters-label">Active filters:</div>
      <div class="active-filters">
        <button class="filter-tag" data-filter-name="category" data-filter-value="Vegetables" type="button">
          Vegetables
          <span class="remove-filter" aria-hidden="true">×</span>
        </button>
        <button class="filter-tag" data-filter-name="verified" data-filter-value="true" type="button">
          true
          <span class="remove-filter" aria-hidden="true">×</span>
        </button>
      </div>
      <button class="btn-clear-all-filters btn btn-ghost btn-sm" type="button">
        Clear All Filters
      </button>
    </div>
  </div>

  <div class="search-results-list max-h-96 overflow-y-auto" role="listbox">
    <!-- Results items -->
  </div>
</div>
```

## CSS Classes

### Main Classes

| Class | Purpose |
|-------|---------|
| `.search-results-container` | Main wrapper for results + header |
| `.search-results-header` | Header section with count and filters |
| `.search-results-count` | Result count display (e.g., "12 results") |
| `.active-filters-container` | Container for all active filters |
| `.active-filters-label` | "Active filters:" label |
| `.active-filters` | Flex container for filter tags |
| `.filter-tag` | Individual removable filter button |
| `.remove-filter` | × icon inside filter tag |
| `.btn-clear-all-filters` | Clear all filters button |

### CSS Styling Features

**Filter Tag Styling:**
- Primary blue background with dark text by default
- White background on hover
- Smooth scale animation (1.05x on hover, 0.98x on click)
- Rounded pill shape (border-radius: full)
- Smooth transitions (200ms easing)

**Remove Filter Icon (×):**
- 20x20px circular background
- Rotates 90 degrees on hover
- Background opacity changes on tag hover
- Smooth transitions

**Clear All Button:**
- Ghost style (transparent background, colored border)
- Danger color on hover (red)
- Small size by default

**Responsive Design:**
- Mobile breakpoint at 640px
- Reduced padding and gap on mobile
- Smaller font sizes on mobile
- More compact layout

## JavaScript Integration

File: `/home/lewis/src/meal-planner/gleam/priv/static/js/food-search-filters.js`

### FoodSearchFilters Class

Manages filter state and event handling.

#### Methods

**`removeFilter(filterName, filterValue)`**
- Removes a single filter and triggers search
- Example: `foodSearchFilters.removeFilter("category", "Vegetables")`

**`clearAllFilters()`**
- Removes all active filters
- Triggers search update
- Example: `foodSearchFilters.clearAllFilters()`

**`addFilter(filterName, filterValue)`**
- Adds filter to active filters map
- Example: `foodSearchFilters.addFilter("category", "Vegetables")`

**`getActiveFiltersObject()`**
- Returns object with all active filters
- Returns: `{ "category": "Vegetables", "verified": "true" }`

**`updateResultCount(count)`**
- Updates the result count display
- Example: `foodSearchFilters.updateResultCount(42)`

#### Events

**Custom Event: `foodSearchFilterChange`**

Dispatched when filters are added/removed.

```javascript
document.addEventListener('foodSearchFilterChange', (e) => {
  console.log(e.detail.query);      // Current search query
  console.log(e.detail.filters);    // Active filters object
  console.log(e.detail.timestamp);  // Event timestamp
});
```

#### Accessibility Features

- **Screen Reader Announcements**
  - Announces when individual filters are removed
  - Announces when all filters are cleared
  - Uses `.sr-only` (screen reader only) elements

- **ARIA Attributes**
  - `role="status"` on result count for dynamic updates
  - `aria-live="polite"` for announcements
  - `aria-label` on filter tags with action description
  - `aria-hidden="true"` on decorative × icon

## Integration Guide

### 1. Update Gleam Component

In your page render function, import the new function:

```gleam
import meal_planner/ui/components/forms

// In your page rendering code:
pub fn render_food_search_page(state: SearchState) -> String {
  let results = state.results
  let filter_count = list.length(state.active_filters)

  forms.search_results_with_count(
    results,
    state.total_count,
    state.active_filters,
    filter_count > 0  // Show clear all only if filters exist
  )
}
```

### 2. Update HTML Layout

Include the JavaScript file in your layout template:

```html
<script src="/static/js/food-search-filters.js"></script>
```

### 3. Handle Filter Changes in JavaScript

```javascript
// Assume you have a search handler
async function performSearch(query, filters = {}) {
  const response = await fetch('/api/food/search', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, filters })
  });

  const data = await response.json();

  // Update result count
  window.foodSearchFilters.updateResultCount(data.results.length);

  // Render results (your implementation)
  renderResults(data.results);
}

// Listen for filter changes
document.addEventListener('foodSearchFilterChange', (e) => {
  performSearch(e.detail.query, e.detail.filters);
});
```

### 4. Handle Initial Filters

When page loads with existing filters:

```javascript
// Initialize active filters from page state
const initialFilters = {
  "category": "Vegetables",
  "verified": "true"
};

Object.entries(initialFilters).forEach(([name, value]) => {
  window.foodSearchFilters.addFilter(name, value);
});
```

## Styling Customization

All colors and spacing use CSS variables defined in the theme:

```css
/* Colors */
--color-primary
--color-primary-light
--color-primary-dark
--color-text
--color-text-secondary
--color-border
--color-bg-secondary
--color-danger

/* Spacing */
--space-1, --space-2, --space-3, etc.

/* Typography */
--text-xs, --text-sm, --text-base, etc.

/* Timing */
--duration-200, --duration-300, etc.
--ease-out
```

To customize filter tag colors, override:

```css
.filter-tag {
  background-color: your-color;
  color: your-text-color;
  border-color: your-border-color;
}

.filter-tag:hover {
  background-color: your-hover-color;
  color: your-hover-text-color;
}
```

## Accessibility Compliance

This component follows WCAG 2.1 AA standards:

- **Keyboard Navigation**: All controls are keyboard accessible
- **Screen Reader Support**: Proper ARIA labels and live regions
- **Color Contrast**: Sufficient contrast ratios
- **Focus Indicators**: Clear visual focus states
- **Mobile**: Touch-friendly target sizes (44x44px minimum)
- **Animations**: Respects `prefers-reduced-motion`

## Browser Compatibility

- Chrome/Edge: Full support
- Firefox: Full support
- Safari: Full support
- Mobile browsers: Full support
- IE11: Not supported (uses modern JS)

## Performance Considerations

- **CSS**: Minimal repaints through transform-based animations
- **JS**: Event delegation for efficient listener management
- **DOM**: Minimal updates on filter changes
- **Bundle Size**: ~2KB gzipped for JS, ~1.5KB for CSS

## Examples

### Example 1: Category Filter Removal

```gleam
// Current state: category="Vegetables", verified="true"
// User clicks × on category tag

// Before: 2 results, 2 filters
search_results_with_count(
  results,
  2,
  [("category", "Vegetables"), ("verified", "true")],
  True
)

// After: 15 results, 1 filter (verified only)
search_results_with_count(
  newResults,
  15,
  [("verified", "true")],
  True
)
```

### Example 2: Clear All Filters

```gleam
// User clicks "Clear All Filters"

// Before: Multiple filters
search_results_with_count(
  results,
  2,
  [
    ("category", "Vegetables"),
    ("verified", "true"),
    ("branded", "false")
  ],
  True
)

// After: No filters, all results
search_results_with_count(
  allResults,
  487,
  [],  // Empty filter list
  False  // Clear All button hidden
)
```

## Testing

### Unit Tests (Gleam)

```gleam
// Test filter count rendering
result_list = search_results_with_count(
  [#(1, "Apple", "Food", "Fruits")],
  1,
  [("category", "Fruits")],
  True
)

// Should contain: "1 result", "Fruits" tag, Clear All button
```

### Integration Tests (JavaScript)

```javascript
// Test filter removal
const button = document.querySelector('[data-filter-name="category"]');
button.click();

// Verify event was dispatched
expect(filterChangeEvent).toHaveBeenCalled();

// Test clear all
const clearBtn = document.querySelector('.btn-clear-all-filters');
clearBtn.click();

// Verify all filters removed
expect(window.foodSearchFilters.activeFilters.size).toBe(0);
```

## Troubleshooting

**Issue**: Filter tags not appearing

- Verify active_filters list is not empty
- Check browser dev tools for HTML in DOM
- Ensure CSS file is loaded

**Issue**: Clear All button not showing

- Verify `show_clear_all` parameter is `True`
- Check that active_filters list has items
- Look at CSS `display: none` on parent

**Issue**: Clicks not triggering search

- Ensure `food-search-filters.js` is loaded
- Check browser console for errors
- Verify event listener is registered

**Issue**: Result count not updating

- Call `window.foodSearchFilters.updateResultCount(newCount)`
- Check element selector matches `.search-results-count`
- Verify singular/plural logic works

## Related Files

- `/gleam/src/meal_planner/ui/components/forms.gleam` - Component functions
- `/gleam/priv/static/css/components.css` - CSS styling
- `/gleam/priv/static/js/food-search-filters.js` - JavaScript logic
- `/gleam/src/meal_planner/ui/pages/food_search.gleam` - Page integration

## Future Enhancements

- Animated filter addition/removal
- Persistent filter state (localStorage)
- Undo/redo functionality
- Filter presets
- Filter history
- Advanced filter builder UI
- Filter suggestions based on history
