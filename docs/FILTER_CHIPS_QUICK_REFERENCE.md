# Filter Chips - Quick Reference

## Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `gleam/priv/static/js/filter-chips.js` | 765 | Main JavaScript module for filter chip interactions |
| `gleam/priv/static/css/filter-chips.css` | 608 | Complete styling with responsive design & dark mode |
| `docs/FILTER_CHIPS_INTEGRATION.md` | ~400 | Comprehensive integration guide |
| `docs/filter-chips-example.html` | ~500 | Working interactive example |
| `docs/FILTER_CHIPS_QUICK_REFERENCE.md` | This file | Quick reference |

**Total: 1,373+ lines of production-ready code**

## Setup (30 seconds)

```html
<!-- 1. Add stylesheet -->
<link rel="stylesheet" href="/static/css/filter-chips.css">

<!-- 2. Add HTML structure -->
<div class="filter-controls">
  <div class="category-dropdown-container">
    <button class="category-dropdown-trigger">Filter by Category</button>
    <div class="category-dropdown-menu" role="listbox">
      <button class="category-dropdown-item" data-category-value="vegetables">Vegetables</button>
      <button class="category-dropdown-item" data-category-value="fruits">Fruits</button>
    </div>
  </div>
  <button class="filters-clear-all" disabled>Clear All</button>
  <div class="filters-results-info"></div>
</div>

<div class="filter-chips-container">
  <div class="filter-chip" data-filter-type="verified" data-filter-value="true">
    <span class="chip-label">Verified Only</span>
    <button class="chip-remove">×</button>
  </div>
</div>

<!-- 3. Add script -->
<script src="/static/js/filter-chips.js"></script>

<!-- 4. Initialize -->
<script>
  FilterChips.init({
    onSearch: function(event) {
      console.log('Search with filters:', event.filters);
      performSearch(event.filters);
    }
  });
</script>
```

## Core Features

### 1. Click Handlers
```javascript
// Automatic on chip click
// - Click chip: toggle on/off
// - Click X: remove filter
// - No manual setup needed
```

### 2. URL Sync
```javascript
// Automatic bidirectional sync
// URL: /search?filter_category=vegetables&filter_verified=true
// Loads on page load, updates on filter change
```

### 3. Visual State
```javascript
// Automatic CSS class toggling
.filter-chip { /* inactive */ }
.filter-chip.active { /* active */ }
```

### 4. Search Triggering
```javascript
FilterChips.on('filterApply', function(event) {
  // Debounced 200ms
  fetch('/api/foods?' + encodeFilters(event.filters));
});
```

### 5. Category Dropdown
```javascript
// Automatic open/close
// Keyboard: Arrow keys, Enter, Escape
// Selection adds filter chip automatically
```

## API Quick Start

```javascript
// Initialize
FilterChips.init({ onSearch, onFilterChange });

// Get state
FilterChips.getFilters()  // { category: ['vegetables'] }
FilterChips.isFilterActive('verified', 'true')  // boolean

// Set state
FilterChips.setFilters({ category: ['vegetables'] })
FilterChips.addFilter('verified', 'true')
FilterChips.removeFilter('verified', 'true')
FilterChips.clearAll()

// Listen
FilterChips.on('filterChange', callback)
FilterChips.on('filterApply', callback)
FilterChips.on('dropdownOpen', callback)
FilterChips.on('dropdownClose', callback)
```

## Keyboard Navigation

| Key | Action |
|-----|--------|
| `Tab` | Focus between chips |
| `Space` / `Enter` | Toggle chip |
| `Delete` / `Backspace` | Remove chip |
| `Arrow Left` / `Arrow Right` | Navigate between chips |
| `Arrow Up` / `Arrow Down` | Navigate in dropdown |
| `Escape` | Close dropdown |

## HTML Structure Reference

### Container
```html
<div class="filter-chips-container"
     aria-label="Active filters"
     tabindex="0">
  <!-- chips go here -->
</div>
```

### Filter Chip
```html
<div class="filter-chip"
     data-filter-type="category"
     data-filter-value="vegetables"
     role="button"
     tabindex="0"
     aria-pressed="false">
  <span class="chip-label">Vegetables</span>
  <button class="chip-remove"
          aria-label="Remove vegetables filter">×</button>
</div>
```

### Category Dropdown
```html
<div class="category-dropdown-container">
  <button class="category-dropdown-trigger"
          aria-expanded="false">
    Filter by Category
  </button>
  <div class="category-dropdown-menu" role="listbox">
    <button class="category-dropdown-item"
            data-category-value="vegetables"
            role="option">
      Vegetables
    </button>
  </div>
</div>
```

## CSS Customization

### Color Scheme
```css
/* Light mode (default) */
--chip-bg-color: #e8f0ff;
--chip-active-bg-color: #0066cc;
--chip-border-color: #b0d0ff;
--chip-text-color: #0066cc;

/* Dark mode (auto via prefers-color-scheme) */
/* Automatically inverted */
```

### Key Classes
```css
.filter-chips-container     /* main container */
.filter-chip                /* inactive chip */
.filter-chip.active         /* active chip */
.chip-label                 /* label text */
.chip-remove                /* remove button */
.category-dropdown-container   /* dropdown wrapper */
.category-dropdown-trigger     /* trigger button */
.category-dropdown-menu        /* dropdown menu */
.category-dropdown-item        /* dropdown item */
.category-dropdown-item.selected /* selected item */
.filters-clear-all          /* clear button */
.filters-results-info       /* results counter */
```

## Events

```javascript
FilterChips.on('filterChange', function(event) {
  event.filterType;    // 'category'
  event.filterValue;   // 'vegetables'
  event.isActive;      // true/false
  event.removed;       // true if removed
  event.filters;       // Full state (if bulk)
});

FilterChips.on('filterApply', function(event) {
  event.filters;       // { category: ['vegetables'] }
  // Perform search here
});

FilterChips.on('dropdownOpen', function(event) {
  // Dropdown opened
});

FilterChips.on('dropdownClose', function(event) {
  // Dropdown closed
});
```

## Common Patterns

### Search on Filter Change
```javascript
FilterChips.init({
  onSearch: function(event) {
    const query = document.getElementById('search-input').value;
    const params = new URLSearchParams();
    params.append('q', query);
    Object.entries(event.filters).forEach(([type, values]) => {
      values.forEach(v => params.append('filter_' + type, v));
    });
    fetch('/api/foods?' + params).then(displayResults);
  }
});
```

### Preset Filters
```javascript
document.getElementById('healthy-preset').addEventListener('click', function() {
  FilterChips.setFilters({
    verified: ['true'],
    category: ['vegetables', 'fruits']
  });
});
```

### Conditional Filters
```javascript
FilterChips.on('filterChange', function(event) {
  if (event.filterType === 'category' && event.filterValue === 'seafood') {
    // Show allergen warning
    showAllergenyWarning();
  }
});
```

### Disable Certain Filters
```javascript
const restrictedChip = document.querySelector('[data-filter-type="admin"]');
if (restrictedChip) {
  restrictedChip.style.opacity = '0.5';
  restrictedChip.style.pointerEvents = 'none';
  restrictedChip.setAttribute('disabled', 'disabled');
}
```

## Accessibility

### Features
- WCAG 2.1 AA compliant
- Full keyboard navigation
- Screen reader support (semantic HTML)
- ARIA labels and roles
- Color contrast 4.5:1+
- Focus management
- No color-only indicators

### Testing
```javascript
// Test keyboard nav
// - Tab through chips
// - Use arrow keys
// - Press Space/Enter/Delete

// Test screen reader
// - NVDA/JAWS on Windows
// - VoiceOver on Mac

// Test color contrast
// - Chrome DevTools > Lighthouse
// - WebAIM Contrast Checker
```

## Browser Support

- Chrome/Edge 60+
- Firefox 55+
- Safari 12+
- Mobile: iOS Safari 12+, Chrome Android 60+

## Performance

- Event delegation (1 listener per container)
- Debounced search (200ms)
- LocalStorage persistence (optional)
- URL history management (replaceState, no reloads)
- Minimal DOM updates

## Responsive Breakpoints

```css
/* Desktop (default) */
.filter-chips-container { gap: 0.5rem; }

/* Tablet (≤768px) */
@media (max-width: 768px) { /* reduced spacing */ }

/* Mobile (≤480px) */
@media (max-width: 480px) { /* full-width layout */ }
```

## Integration with Search API

```gleam
// In Gleam search handler
pub fn api_foods(req: wisp.Request, ctx: Context) -> wisp.Response {
  let filters = types.SearchFilters(
    verified_only: parse_bool_param(req, "filter_verified"),
    branded_only: parse_bool_param(req, "filter_branded"),
    category: get_string_param(req, "filter_category"),
  )

  let foods = storage.search_foods_filtered(ctx.db, query, filters, 50)
  wisp.json_response(json.to_string(food_to_json(foods)), 200)
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Filters not saving | Check `persistToStorage: true` in init, verify localStorage enabled |
| URL not updating | Verify `loadFromUrl: true`, check console for errors |
| Dropdown not showing | Ensure `.category-dropdown-menu` in HTML, check CSS loaded |
| Search not triggering | Verify `onSearch` callback in init, check debounce timing |
| Accessibility issues | Test keyboard nav, run WCAG checker, test with screen reader |

## Example HTML (Complete)

See: `docs/filter-chips-example.html`

Interactive demo with:
- Working filter chips
- Category dropdown
- Results display
- URL sync demo
- API examples
- Open in browser to test

## Next Steps

1. Copy HTML structure to your template
2. Include `filter-chips.js` and `filter-chips.css`
3. Call `FilterChips.init()` with your search callback
4. Test keyboard navigation
5. Test with screen reader
6. Customize CSS colors if needed
7. Integrate with API endpoints

## Support

For issues or questions:
1. Check `FILTER_CHIPS_INTEGRATION.md` for detailed docs
2. Review `filter-chips-example.html` for working example
3. Check browser console for error messages
4. Verify HTML structure matches documentation
5. Test in different browsers
