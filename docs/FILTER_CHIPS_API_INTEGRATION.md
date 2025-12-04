# Filter Chips - API Integration Guide

This document shows how to integrate filter chips with the meal-planner backend.

## Overview

The filter chips system syncs with URL query parameters in format:
```
/search?filter_category=vegetables&filter_verified=true&filter_branded=false
```

The Gleam API handler (`handlers/search.gleam`) already supports these parameters.

## Current API Support

### GET /api/foods

**Query Parameters:**
- `q` - Search query (required)
- `filter_category` - Category filter (repeatable)
- `filter_verified_only` - Verified foods only (true/false)
- `filter_branded_only` - Branded foods only (true/false)

**Example:**
```
GET /api/foods?q=apple&filter_category=fruits&filter_verified_only=true
```

**Response:**
```json
[
  {
    "fdc_id": 123456,
    "description": "APPLE, GALA",
    "data_type": "Survey (FNDDS)",
    "category": "Fruits"
  }
]
```

## Frontend Implementation

### 1. HTML Template

```html
<!-- /gleam/src/meal_planner/ui/pages/food_search.gleam or view template -->

<div class="food-search-container">
  <!-- Filter Controls -->
  <div class="filter-controls">
    <div class="category-dropdown-container">
      <button class="category-dropdown-trigger" aria-expanded="false">
        Filter by Category
      </button>
      <div class="category-dropdown-menu" role="listbox">
        <button class="category-dropdown-item"
                data-category-value="vegetables"
                role="option">
          Vegetables
        </button>
        <button class="category-dropdown-item"
                data-category-value="fruits"
                role="option">
          Fruits
        </button>
        <button class="category-dropdown-item"
                data-category-value="grains"
                role="option">
          Grains
        </button>
        <button class="category-dropdown-item"
                data-category-value="proteins"
                role="option">
          Proteins
        </button>
      </div>
    </div>

    <button class="filters-clear-all" aria-label="Clear all filters" disabled>
      Clear All Filters
    </button>

    <div class="filters-results-info" aria-live="polite"></div>
  </div>

  <!-- Active Filter Chips -->
  <div class="filter-chips-container" aria-label="Active filters" tabindex="0">
    <div class="filter-chip"
         data-filter-type="verified_only"
         data-filter-value="true"
         role="button"
         tabindex="0"
         aria-pressed="false">
      <span class="chip-label">Verified Only</span>
      <button class="chip-remove" aria-label="Remove verified filter">×</button>
    </div>

    <div class="filter-chip"
         data-filter-type="branded_only"
         data-filter-value="false"
         role="button"
         tabindex="-1"
         aria-pressed="false">
      <span class="chip-label">Generic Foods</span>
      <button class="chip-remove" aria-label="Remove generic foods filter">×</button>
    </div>
  </div>

  <!-- Search Input -->
  <div class="search-input-wrapper">
    <input type="search"
           id="food-search-input"
           class="search-input"
           placeholder="Search foods (e.g., apple, chicken)..."
           autocomplete="off">
    <button class="search-button" aria-label="Search">Search</button>
  </div>

  <!-- Results Section -->
  <div id="food-search-results" class="food-results-container">
    <!-- Results populated by JavaScript -->
  </div>

  <!-- Loading State -->
  <div id="food-search-loading" class="loading-state" style="display: none;">
    <p>Searching...</p>
  </div>

  <!-- Error State -->
  <div id="food-search-error" class="error-state" style="display: none;">
    <p id="error-message"></p>
  </div>
</div>

<!-- Stylesheets -->
<link rel="stylesheet" href="/static/css/filter-chips.css">

<!-- Scripts -->
<script src="/static/js/filter-chips.js"></script>
<script>
  /**
   * Initialize food search with filter chips
   */
  FilterChips.init({
    loadFromUrl: true,
    persistToStorage: true,
    onFilterChange: function(event) {
      console.log('Filter changed:', event);
      // Optional: Highlight changed filter, animate, etc.
    },
    onSearch: function(event) {
      performFoodSearch(event.filters);
    }
  });

  /**
   * Perform food search with filters
   */
  function performFoodSearch(filters) {
    const query = document.getElementById('food-search-input').value;

    if (!query.trim()) {
      clearResults();
      return;
    }

    const params = new URLSearchParams();
    params.append('q', query);

    // Add filter parameters
    // Filter chip data-filter-type matches URL param names:
    // - verified_only -> filter_verified_only
    // - branded_only -> filter_branded_only
    // - category -> filter_category

    Object.entries(filters).forEach(([filterType, values]) => {
      if (Array.isArray(values)) {
        values.forEach(value => {
          params.append('filter_' + filterType, value);
        });
      }
    });

    showLoading(true);
    clearError();

    fetch('/api/foods?' + params)
      .then(response => {
        if (!response.ok) {
          throw new Error('Search failed: ' + response.statusText);
        }
        return response.json();
      })
      .then(foods => {
        showLoading(false);
        displayFoodResults(foods, query);
      })
      .catch(error => {
        showLoading(false);
        showError('Search failed: ' + error.message);
      });
  }

  /**
   * Display food results
   */
  function displayFoodResults(foods, query) {
    const container = document.getElementById('food-search-results');

    if (foods.length === 0) {
      container.innerHTML = `
        <div class="empty-state">
          <p>No foods found matching "${query}"</p>
          <p>Try adjusting your search or filters</p>
        </div>
      `;
      return;
    }

    const html = foods.map(food => `
      <div class="food-result-card" data-fdc-id="${food.fdc_id}">
        <div class="food-result-header">
          <h3 class="food-name">${escapeHtml(food.description)}</h3>
          <button class="add-to-log-btn" onclick="addToLog(${food.fdc_id}, '${escapeHtml(food.description)}')">
            Add to Log
          </button>
        </div>
        <div class="food-result-details">
          <span class="food-category-badge">${escapeHtml(food.category)}</span>
          <span class="food-type-badge">${escapeHtml(food.data_type)}</span>
        </div>
      </div>
    `).join('');

    container.innerHTML = html;
  }

  /**
   * Clear results
   */
  function clearResults() {
    document.getElementById('food-search-results').innerHTML = '';
  }

  /**
   * Show/hide loading state
   */
  function showLoading(isLoading) {
    document.getElementById('food-search-loading').style.display =
      isLoading ? 'block' : 'none';
  }

  /**
   * Show error message
   */
  function showError(message) {
    const errorDiv = document.getElementById('food-search-error');
    document.getElementById('error-message').textContent = message;
    errorDiv.style.display = 'block';
  }

  /**
   * Clear error message
   */
  function clearError() {
    document.getElementById('food-search-error').style.display = 'none';
  }

  /**
   * Escape HTML to prevent XSS
   */
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  /**
   * Add food to log
   */
  function addToLog(fdcId, description) {
    console.log('Adding to log:', fdcId, description);
    // Implement based on your meal logger
  }

  // Trigger search on input change
  const searchInput = document.getElementById('food-search-input');
  searchInput.addEventListener('input', function() {
    // Optional: Auto-search on input
    // performFoodSearch(FilterChips.getFilters());
  });

  // Trigger search on button click
  document.querySelector('.search-button').addEventListener('click', function() {
    performFoodSearch(FilterChips.getFilters());
  });

  // Trigger search on Enter key
  searchInput.addEventListener('keypress', function(event) {
    if (event.key === 'Enter') {
      performFoodSearch(FilterChips.getFilters());
    }
  });
</script>
```

### 2. CSS Integration

```css
/* Add to styles.css or filter-chips.css */

.food-search-container {
  max-width: 800px;
  margin: 2rem auto;
  padding: 0 1rem;
}

.search-input-wrapper {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 2rem;
}

.search-input {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid #d0d0d0;
  border-radius: 4px;
  font-size: 1rem;
}

.search-input:focus {
  outline: 2px solid #0066cc;
  outline-offset: 2px;
}

.search-button {
  padding: 0.75rem 1.5rem;
  background-color: #0066cc;
  color: white;
  border: none;
  border-radius: 4px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 150ms;
}

.search-button:hover {
  background-color: #0052a3;
}

.search-button:focus {
  outline: 2px solid #0066cc;
  outline-offset: 2px;
}

.food-results-container {
  display: grid;
  gap: 1rem;
  margin-top: 2rem;
}

.food-result-card {
  padding: 1rem;
  background: #ffffff;
  border: 1px solid #e0e0e0;
  border-radius: 4px;
  transition: all 150ms ease-in-out;
}

.food-result-card:hover {
  border-color: #0066cc;
  box-shadow: 0 2px 8px rgba(0, 102, 204, 0.1);
}

.food-result-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.5rem;
}

.food-name {
  font-size: 1rem;
  font-weight: 600;
  color: #333;
  margin: 0;
}

.add-to-log-btn {
  padding: 0.5rem 1rem;
  background-color: #e8f0ff;
  border: 1px solid #b0d0ff;
  border-radius: 4px;
  color: #0066cc;
  font-weight: 500;
  cursor: pointer;
  transition: all 150ms;
}

.add-to-log-btn:hover {
  background-color: #d0e5ff;
  border-color: #80b5ff;
}

.food-result-details {
  display: flex;
  gap: 0.5rem;
  font-size: 0.875rem;
}

.food-category-badge {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  background-color: #f0f0f0;
  border-radius: 12px;
  color: #666;
}

.food-type-badge {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  background-color: #e8f5e9;
  border-radius: 12px;
  color: #2e7d32;
  font-size: 0.75rem;
}

.empty-state {
  text-align: center;
  padding: 2rem;
  color: #999;
}

.empty-state p {
  margin: 0.5rem 0;
}

.loading-state {
  text-align: center;
  padding: 2rem;
  color: #0066cc;
}

.error-state {
  padding: 1rem;
  background-color: #ffebee;
  border-left: 3px solid #d32f2f;
  border-radius: 0.25rem;
  color: #d32f2f;
}
```

## Backend Implementation

### Gleam Handler (Already Implemented)

```gleam
// /gleam/src/meal_planner/web/handlers/search.gleam

pub fn api_foods(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Parse query string
  let parsed_query = uri.parse_query(req.query |> option.unwrap(""))

  // Get search query
  let query = case parsed_query {
    Ok(params) -> case list.find(params, fn(p) { p.0 == "q" }) {
      Ok(#(_, q)) -> q
      Error(_) -> ""
    }
    Error(_) -> ""
  }

  // Parse filter parameters
  let filters = case parsed_query {
    Ok(params) -> {
      let verified_only = case list.find(params, fn(p) { p.0 == "filter_verified_only" }) {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let branded_only = case list.find(params, fn(p) { p.0 == "filter_branded_only" }) {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let category = case list.find(params, fn(p) { p.0 == "filter_category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      types.SearchFilters(
        verified_only: verified_only,
        branded_only: branded_only,
        category: category,
      )
    }
    Error(_) -> types.SearchFilters(verified_only: False, branded_only: False, category: None)
  }

  // Perform search
  case query {
    "" -> wisp.json_response(json.to_string(json.object([#("error", json.string("Query required"))])), 400)
    q -> {
      let foods = search_foods_filtered(ctx, q, filters, 50)
      wisp.json_response(json.to_string(json.array(foods, food_to_json)), 200)
    }
  }
}
```

## Filter Parameter Mapping

### URL to Gleam

| URL Parameter | Gleam Field | Type |
|---------------|-------------|------|
| `filter_category` | `SearchFilters.category` | `Option(String)` |
| `filter_verified_only` | `SearchFilters.verified_only` | `Bool` |
| `filter_branded_only` | `SearchFilters.branded_only` | `Bool` |

### JavaScript to URL

```javascript
// From filter chips
FilterChips.getFilters()
// Returns: {
//   category: ['vegetables', 'fruits'],
//   verified_only: ['true'],
//   branded_only: ['false']
// }

// Converts to URL parameters:
// ?filter_category=vegetables
// &filter_category=fruits
// &filter_verified_only=true
// &filter_branded_only=false
```

## Example Flow

### 1. User searches for "apple"
```
Input: "apple"
URL: /search?q=apple
Request: GET /api/foods?q=apple
Response: [apples, pineapples, green apples, ...]
```

### 2. User adds category filter (fruits)
```
Click: "Fruits" in dropdown
URL: /search?q=apple&filter_category=fruits
Request: GET /api/foods?q=apple&filter_category=fruits
Response: [apples, pineapples, ...]
```

### 3. User adds verified filter
```
Click: "Verified Only" chip
URL: /search?q=apple&filter_category=fruits&filter_verified_only=true
Request: GET /api/foods?q=apple&filter_category=fruits&filter_verified_only=true
Response: [APPLE, GALA - verified, ...]
```

### 4. User bookmarks URL
```
URL can be shared or bookmarked with all filters applied
Next visit: All filters automatically restored from URL
```

## Multiple Categories Support

To support multiple categories:

```javascript
// Add multiple category items to dropdown
const categories = [
  'vegetables',
  'fruits',
  'grains',
  'proteins',
  'dairy'
];

categories.forEach(cat => {
  const item = document.createElement('button');
  item.className = 'category-dropdown-item';
  item.dataset.categoryValue = cat;
  item.textContent = cat.charAt(0).toUpperCase() + cat.slice(1);
  menu.appendChild(item);
});

// Each click adds another filter
// URL: ?filter_category=vegetables&filter_category=fruits
// Search results: foods in EITHER category
```

## Testing

### Manual Testing
```bash
# Test search
curl "http://localhost:3000/api/foods?q=apple"

# Test with verified filter
curl "http://localhost:3000/api/foods?q=apple&filter_verified_only=true"

# Test with category filter
curl "http://localhost:3000/api/foods?q=apple&filter_category=fruits"

# Test with multiple categories
curl "http://localhost:3000/api/foods?q=chicken&filter_category=proteins&filter_category=dairy"
```

### Browser Testing
1. Open `/search` in browser
2. Type search query (e.g., "apple")
3. Click search
4. Click category filter
5. Verify URL updates
6. Bookmark page
7. Close tab
8. Reopen bookmark
9. Verify filters restored

## Performance Tips

1. **Debounce Search**: Already implemented (200ms)
2. **Limit Results**: API returns max 50 results
3. **Client-Side Filtering**: Consider pre-loading common searches
4. **Cache Results**: Store results in memory for repeated searches
5. **Optimize Query**: Use indexed database columns

## Security Considerations

1. **XSS Prevention**: Always escape HTML in results display
2. **Input Validation**: Server validates filter parameters
3. **SQL Injection**: Use parameterized queries (handled by storage layer)
4. **Rate Limiting**: Consider rate limit on /api/foods endpoint

## Future Enhancements

1. **Advanced Filters**: Nutrition ranges, allergens, cost
2. **Search History**: Store recent searches
3. **Favorites**: Save frequently searched foods
4. **Analytics**: Track popular searches
5. **Autocomplete**: Suggest foods as user types
6. **Offline Support**: Service worker caching
