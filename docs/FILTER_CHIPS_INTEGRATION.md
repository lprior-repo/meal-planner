# Filter Chips Integration Guide

## Overview

The filter chips system provides interactive client-side filtering with automatic URL query parameter synchronization. This guide covers implementation, usage, and customization.

## Files

- `gleam/priv/static/js/filter-chips.js` - Main JavaScript module (1000+ lines)
- `gleam/priv/static/css/filter-chips.css` - Styling and responsive design

## Quick Start

### 1. Include Scripts and Styles

```html
<!-- In your HTML template -->
<link rel="stylesheet" href="/static/css/filter-chips.css">
<script src="/static/js/filter-chips.js"></script>
```

### 2. Basic HTML Structure

```html
<!-- Filter controls container -->
<div class="filter-controls">
  <!-- Category dropdown -->
  <div class="category-dropdown-container">
    <button class="category-dropdown-trigger" aria-expanded="false">
      Filter by Category
    </button>
    <div class="category-dropdown-menu" role="listbox">
      <button class="category-dropdown-item" data-category-value="vegetables" role="option">
        Vegetables
      </button>
      <button class="category-dropdown-item" data-category-value="fruits" role="option">
        Fruits
      </button>
      <button class="category-dropdown-item" data-category-value="grains" role="option">
        Grains
      </button>
    </div>
  </div>

  <!-- Clear all button -->
  <button class="filters-clear-all" aria-label="Clear all filters" disabled>
    Clear All
  </button>

  <!-- Results info -->
  <div class="filters-results-info" aria-live="polite"></div>
</div>

<!-- Active filter chips -->
<div class="filter-chips-container" aria-label="Active filters" tabindex="0">
  <div class="filter-chip active" data-filter-type="category" data-filter-value="vegetables" role="button" tabindex="0" aria-pressed="true">
    <span class="chip-label">Vegetables</span>
    <button class="chip-remove" aria-label="Remove vegetables filter">×</button>
  </div>

  <div class="filter-chip" data-filter-type="verified" data-filter-value="true" role="button" tabindex="-1" aria-pressed="false">
    <span class="chip-label">Verified Only</span>
    <button class="chip-remove" aria-label="Remove verified only filter">×</button>
  </div>
</div>

<!-- Search results section -->
<div id="search-results">
  <!-- Results loaded via JavaScript -->
</div>
```

### 3. JavaScript Initialization

```javascript
// Basic initialization with default options
FilterChips.init();

// Or with custom callbacks
FilterChips.init({
  loadFromUrl: true,
  persistToStorage: true,
  onFilterChange: function(event) {
    console.log('Filter changed:', event);
    // Update UI, animate, etc.
  },
  onSearch: function(event) {
    console.log('Searching with filters:', event.filters);
    // Trigger API call or search
  }
});

// Listen to events
FilterChips.on('filterChange', function(event) {
  console.log('Filter applied:', event.filterType, event.filterValue);
});

FilterChips.on('filterApply', function(event) {
  console.log('Triggering search with filters:', event.filters);
  performSearch(event.filters);
});
```

## Features

### 1. Click Handlers for Filter Chips

```javascript
// Clicking a chip toggles it on/off
const chip = document.querySelector('[data-filter-value="vegetables"]');
chip.click(); // Toggles active state

// Clicking the remove button removes the chip
const removeBtn = chip.querySelector('.chip-remove');
removeBtn.click(); // Removes filter

// Auto-update URL and storage
// No manual management needed!
```

### 2. URL Query Parameter Syncing

```javascript
// Automatically sync with URL
// URL: /search?filter_category=vegetables&filter_verified=true
// Loads filters on page load

// Filter changes update URL
FilterChips.on('filterChange', function() {
  // URL automatically updated to reflect current state
  // No page reload needed
});

// Bookmarkable URLs
// User can bookmark: /search?filter_category=fruits&filter_category=vegetables
```

### 3. Toggle Active State Visually

```javascript
// Automatic visual updates via CSS classes
.filter-chip.active {
  background-color: #0066cc;
  color: #ffffff;
}

// Keyboard navigation support
// Arrow keys: navigate between chips
// Space/Enter: toggle chip
// Delete/Backspace: remove chip
```

### 4. Trigger Search with New Filters

```javascript
// Setup search trigger
FilterChips.init({
  onSearch: function(event) {
    const filters = event.filters;
    // Example: { category: ['vegetables'], verified: ['true'] }

    // Make API call
    fetch('/api/foods?q=search&' + new URLSearchParams(flattenFilters(filters)))
      .then(r => r.json())
      .then(data => displayResults(data));
  }
});

// Debounced (200ms default) to avoid excessive requests
```

### 5. Category Dropdown Management

```javascript
// Dropdown automatically opens/closes on click
// Keyboard navigation:
// - ArrowDown: next item
// - ArrowUp: previous item
// - Enter: select item
// - Escape: close dropdown

// Selected category automatically added as filter chip
FilterChips.on('filterChange', function(event) {
  if (event.filterType === 'category') {
    console.log('Category selected:', event.filterValue);
  }
});
```

## API Reference

### Methods

#### `FilterChips.init(options)`

Initialize the filter chips system.

```javascript
FilterChips.init({
  loadFromUrl: true,              // Load filters from URL on init
  persistToStorage: true,         // Save filters to localStorage
  onFilterChange: function(e) {}, // Callback when filter changes
  onSearch: function(e) {}        // Callback when search triggered
});
```

#### `FilterChips.getFilters()`

Get currently active filters.

```javascript
const filters = FilterChips.getFilters();
// Returns: { category: ['vegetables', 'fruits'], verified: ['true'] }
```

#### `FilterChips.setFilters(filters)`

Set filters programmatically.

```javascript
FilterChips.setFilters({
  category: ['vegetables'],
  verified: ['true']
});
// Updates UI, URL, storage, and triggers search
```

#### `FilterChips.clearAll()`

Clear all filters.

```javascript
FilterChips.clearAll();
// Clears state, updates UI, URL, storage
// Triggers search callback
```

#### `FilterChips.addFilter(filterType, filterValue)`

Add a single filter.

```javascript
FilterChips.addFilter('category', 'vegetables');
// Does NOT trigger search (use setFilters for that)
```

#### `FilterChips.removeFilter(filterType, filterValue)`

Remove a single filter.

```javascript
FilterChips.removeFilter('category', 'vegetables');
// Does NOT trigger search
```

#### `FilterChips.isFilterActive(filterType, filterValue)`

Check if filter is active.

```javascript
const isActive = FilterChips.isFilterActive('category', 'vegetables');
// Returns: true/false
```

#### `FilterChips.on(eventType, callback)`

Register event listener.

```javascript
FilterChips.on('filterChange', function(event) {
  console.log('Filter changed:', event);
});

FilterChips.on('filterApply', function(event) {
  console.log('Search triggered with:', event.filters);
});

FilterChips.on('dropdownOpen', function(event) {
  console.log('Dropdown opened');
});

FilterChips.on('dropdownClose', function(event) {
  console.log('Dropdown closed');
});
```

## Events

### `filterChange`

Fired when a filter is added, removed, or toggled.

```javascript
FilterChips.on('filterChange', function(event) {
  event.filterType;     // e.g., 'category'
  event.filterValue;    // e.g., 'vegetables'
  event.isActive;       // true if added, false if removed
  event.removed;        // true if explicitly removed
  event.filters;        // Full filters object (if bulk operation)
});
```

### `filterApply`

Fired when search should be triggered (debounced).

```javascript
FilterChips.on('filterApply', function(event) {
  event.filters;  // { category: ['vegetables'], ... }
});
```

### `dropdownOpen`

Fired when category dropdown opens.

```javascript
FilterChips.on('dropdownOpen', function(event) {
  // Reset dropdown scroll, focus management, etc.
});
```

### `dropdownClose`

Fired when category dropdown closes.

```javascript
FilterChips.on('dropdownClose', function(event) {
  // Cleanup, focus management
});
```

## HTML Attributes Reference

### Filter Chip Element

```html
<div class="filter-chip"
     data-filter-type="category"
     data-filter-value="vegetables"
     role="button"
     tabindex="0"
     aria-pressed="false">
  <span class="chip-label">Vegetables</span>
  <button class="chip-remove" aria-label="Remove vegetables filter">×</button>
</div>
```

**Attributes:**
- `data-filter-type`: Category of filter (required)
- `data-filter-value`: Filter value (required)
- `role="button"`: Accessibility role
- `tabindex`: Keyboard navigation (auto-managed)
- `aria-pressed`: Active state (auto-managed)
- `class="active"`: Visual active state (auto-managed)

### Category Dropdown Item

```html
<button class="category-dropdown-item"
        data-category-value="vegetables"
        role="option">
  Vegetables
</button>
```

**Attributes:**
- `data-category-value`: Category value (required)
- `role="option"`: Accessibility role
- `class="selected"`: Visual selected state (auto-managed)
- `aria-selected`: Selected state (auto-managed)

## CSS Customization

### CSS Variables

Customize colors by setting CSS variables:

```css
:root {
  /* Chip colors */
  --chip-bg-color: #e8f0ff;
  --chip-active-bg-color: #0066cc;
  --chip-border-color: #b0d0ff;
  --chip-text-color: #0066cc;
  --chip-hover-bg-color: #d0e5ff;

  /* Dropdown colors */
  --dropdown-bg: #ffffff;
  --dropdown-border: #d0d0d0;
  --dropdown-hover-bg: #f0f0f0;
}
```

### Key Classes

```css
/* Container */
.filter-chips-container { }
.filter-controls { }
.category-dropdown-container { }

/* Chip states */
.filter-chip { }
.filter-chip.active { }
.filter-chip:hover { }
.filter-chip:focus-visible { }

/* Dropdown */
.category-dropdown-menu { }
.category-dropdown-menu.open { }
.category-dropdown-item { }
.category-dropdown-item.selected { }

/* Utility */
.filters-clear-all { }
.filters-results-info { }
```

### Responsive Breakpoints

The CSS includes responsive styling for:
- Desktop (default)
- Tablet (≤768px)
- Mobile (≤480px)

Customize breakpoints in CSS file.

### Dark Mode

Built-in dark mode support via `prefers-color-scheme: dark` media query.

## Accessibility Features

### WCAG 2.1 AA Compliance

- **Keyboard Navigation**: Full keyboard support
  - Tab: Navigate between chips
  - Arrow keys: Move between chips
  - Space/Enter: Toggle chip
  - Delete/Backspace: Remove chip
  - Escape: Close dropdown

- **Screen Reader Support**:
  - Semantic HTML with `role="button"`, `role="option"`
  - `aria-pressed` for chip state
  - `aria-selected` for dropdown selection
  - `aria-label` for remove buttons
  - `aria-expanded` for dropdown trigger
  - `aria-live="polite"` for results info

- **Color Contrast**:
  - WCAG AA contrast ratios (4.5:1 minimum)
  - Dark mode support
  - No color-only indicators

- **Focus Management**:
  - Visible focus indicators (2px outline)
  - Logical tab order
  - Focus restoration after actions

## Usage Examples

### Example 1: Food Search with Category Filter

```html
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="/static/css/filter-chips.css">
</head>
<body>
  <h1>Food Search</h1>

  <div class="filter-controls">
    <div class="category-dropdown-container">
      <button class="category-dropdown-trigger" aria-expanded="false">
        Filter by Category
      </button>
      <div class="category-dropdown-menu" role="listbox">
        <button class="category-dropdown-item" data-category-value="vegetables" role="option">
          Vegetables
        </button>
        <button class="category-dropdown-item" data-category-value="fruits" role="option">
          Fruits
        </button>
      </div>
    </div>
    <button class="filters-clear-all" aria-label="Clear all filters">Clear All</button>
    <div class="filters-results-info" aria-live="polite"></div>
  </div>

  <div class="filter-chips-container" aria-label="Active filters"></div>

  <input type="search" id="search-input" placeholder="Search foods...">
  <div id="search-results"></div>

  <script src="/static/js/filter-chips.js"></script>
  <script>
    FilterChips.init({
      onSearch: function(event) {
        const query = document.getElementById('search-input').value;
        const filters = event.filters;

        const params = new URLSearchParams();
        params.append('q', query);
        Object.entries(filters).forEach(([type, values]) => {
          values.forEach(v => params.append('filter_' + type, v));
        });

        fetch('/api/foods?' + params)
          .then(r => r.json())
          .then(data => {
            const html = data.map(food => `
              <div class="food-item">
                <h3>${food.description}</h3>
                <p>${food.category}</p>
              </div>
            `).join('');
            document.getElementById('search-results').innerHTML = html;
          });
      }
    });
  </script>
</body>
</html>
```

### Example 2: Multiple Filter Types

```javascript
// Add multiple filter types
const container = document.querySelector('.filter-chips-container');

// Add verified only filter
const verifiedChip = document.createElement('div');
verifiedChip.className = 'filter-chip';
verifiedChip.dataset.filterType = 'verified';
verifiedChip.dataset.filterValue = 'true';
verifiedChip.innerHTML = `
  <span class="chip-label">Verified Only</span>
  <button class="chip-remove" aria-label="Remove verified only filter">×</button>
`;
container.appendChild(verifiedChip);

// Add branded filter
const brandedChip = document.createElement('div');
brandedChip.className = 'filter-chip';
brandedChip.dataset.filterType = 'branded';
brandedChip.dataset.filterValue = 'true';
brandedChip.innerHTML = `
  <span class="chip-label">Branded Foods</span>
  <button class="chip-remove" aria-label="Remove branded foods filter">×</button>
`;
container.appendChild(brandedChip);

FilterChips.init();
```

### Example 3: Programmatic Filter Control

```javascript
// Initialize
FilterChips.init();

// Set specific filters
document.getElementById('filter-btn').addEventListener('click', function() {
  FilterChips.setFilters({
    category: ['vegetables', 'fruits'],
    verified: ['true']
  });
});

// Clear specific category
document.getElementById('clear-category-btn').addEventListener('click', function() {
  const current = FilterChips.getFilters();
  delete current.category;
  FilterChips.setFilters(current);
});

// Check if filter is active
if (FilterChips.isFilterActive('category', 'vegetables')) {
  console.log('Vegetables filter is active');
}
```

## Troubleshooting

### Filters not persisting across page loads

- Ensure `persistToStorage: true` in init options
- Check browser's localStorage is enabled
- Look for errors in browser console

### Dropdown not appearing

- Verify `.category-dropdown-menu` element exists in HTML
- Check CSS is loaded (`filter-chips.css`)
- Ensure dropdown trigger has proper `aria-expanded` attribute

### URL not updating

- Confirm `loadFromUrl: true` in init options
- Check browser console for JavaScript errors
- Verify `window.history.replaceState` is supported

### Accessibility issues

- Run through WCAG checker
- Test with keyboard navigation (Tab, Arrow keys, Enter, Escape)
- Test with screen reader (NVDA, JAWS, VoiceOver)
- Verify color contrast with Contrast Checker

## Performance Considerations

- **Debouncing**: Search triggered with 200ms debounce to prevent excessive requests
- **Event Delegation**: Uses single event listener on container (not per-chip)
- **Storage**: Serialized to JSON in localStorage
- **URL Updates**: Uses `replaceState` (no DOM overhead)

## Browser Support

- Chrome/Edge 60+
- Firefox 55+
- Safari 12+
- Mobile browsers (iOS Safari 12+, Chrome Android 60+)

## License

Same as meal-planner project
