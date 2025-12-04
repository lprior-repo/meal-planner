# Filter Result Display - Quick Start Guide

## TL;DR

New component shows search result counts with removable filter tags.

## 3-Step Integration

### Step 1: Use the Gleam Component

```gleam
import meal_planner/ui/components/forms

// In your render function:
forms.search_results_with_count(
  search_results,     // List of (id, name, type, category) tuples
  result_count,       // Number as Int
  active_filters,     // List of ("name", "value") tuples
  show_clear_all      // Boolean for clear button
)
```

### Step 2: Add JavaScript

Include in your HTML layout:

```html
<script src="/static/js/food-search-filters.js"></script>
```

### Step 3: Handle Filter Events

```javascript
document.addEventListener('foodSearchFilterChange', (e) => {
  // e.detail.query - search query string
  // e.detail.filters - object of active filters
  // e.detail.timestamp - when change occurred

  // Do your search here
  performSearch(e.detail.query, e.detail.filters);
});
```

## Common Tasks

### Remove a Single Filter (in JavaScript)

```javascript
window.foodSearchFilters.removeFilter("category", "Vegetables");
```

### Clear All Filters

```javascript
window.foodSearchFilters.clearAllFilters();
```

### Update Result Count

```javascript
window.foodSearchFilters.updateResultCount(42);
```

### Get All Active Filters

```javascript
const filters = window.foodSearchFilters.getActiveFiltersObject();
// Returns: { "category": "Vegetables", "verified": "true" }
```

## HTML Output

```html
<!-- Count Display -->
<div class="search-results-count">12 results</div>

<!-- Filter Tags (click × to remove individual filter) -->
<button class="filter-tag" data-filter-name="category" data-filter-value="Vegetables">
  Vegetables
  <span class="remove-filter">×</span>
</button>

<!-- Clear All Button -->
<button class="btn-clear-all-filters">Clear All Filters</button>
```

## CSS Classes to Know

| Class | What it does |
|-------|-------------|
| `.filter-tag` | Removable filter badge |
| `.remove-filter` | The × button inside filter |
| `.btn-clear-all-filters` | Clear all filters button |
| `.search-results-count` | Shows "X results" |
| `.active-filters` | Container for all filter tags |

## Styling

All colors/spacing use theme CSS variables. Customize with:

```css
/* Override default colors */
.filter-tag {
  background-color: var(--color-primary-light);
  color: var(--color-primary-dark);
}

.filter-tag:hover {
  background-color: var(--color-primary);
  color: white;
}
```

## Accessibility

- All interactive elements are keyboard accessible
- Screen readers get announcements when filters change
- High contrast by default
- Works on mobile

## Files Modified/Created

### Modified
- `/gleam/src/meal_planner/ui/components/forms.gleam` - Added `search_results_with_count` function
- `/gleam/priv/static/css/components.css` - Added filter styling

### Created
- `/gleam/priv/static/js/food-search-filters.js` - Filter management
- `/docs/FILTER_RESULT_DISPLAY.md` - Full documentation
- `/docs/FILTER_QUICK_START.md` - This file

## Example Flow

```
User searches for "apple"
  ↓
Shows 50 results
  ↓
User clicks "category" filter for "Fruits"
  ↓
Filter tag appears: [Fruits ×]
  ↓
Shows 12 results
  ↓
User clicks × on Fruits tag
  ↓
Tag removed, search updates
  ↓
Shows 50 results again
```

## Performance

- ~2KB JS (gzipped)
- ~1.5KB CSS (gzipped)
- Uses CSS transforms for smooth animations
- Efficient event delegation

## Browser Support

- Chrome/Edge: ✓
- Firefox: ✓
- Safari: ✓
- Mobile: ✓
- IE11: ✗ (not supported)

## Need Help?

1. See full docs: `/docs/FILTER_RESULT_DISPLAY.md`
2. Check examples: `/gleam/priv/static/js/food-search-filters.js` (integration section)
3. Review CSS: `/gleam/priv/static/css/components.css` (lines 588-731)
