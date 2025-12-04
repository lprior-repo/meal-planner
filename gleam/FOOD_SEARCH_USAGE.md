# Food Search Filter Chips - Usage Guide

## Component Location

```gleam
import meal_planner/ui/components/food_search as fs
```

Path: `gleam/src/meal_planner/ui/components/food_search.gleam`

## Implementation

The component renders Lustre `element.Element(msg)` that produces semantic HTML with:
- Clickable filter chips (buttons)
- Category dropdown filter
- Full accessibility attributes
- Data attributes for JavaScript integration

## Types

### FilterType

Defines the four available filter types:

```gleam
pub type FilterType {
  All           // Show all foods (default)
  VerifiedOnly  // Only verified foods
  Branded       // Only branded foods
  ByCategory    // Filter by category
}
```

### FilterChip

Represents a single filter chip:

```gleam
pub type FilterChip {
  FilterChip(
    label: String,         // Display text
    filter_type: FilterType,
    selected: Bool         // Current selection state
  )
}
```

## Core Functions

### 1. render_filter_chip

**Purpose:** Render a single filter chip button

**Signature:**
```gleam
pub fn render_filter_chip(chip: FilterChip) -> element.Element(msg)
```

**Renders:**
```html
<button class="filter-chip filter-chip-selected"
        data-filter="all"
        aria-selected="true"
        type="button">
  All
</button>
```

**Example:**
```gleam
let chip = FilterChip("All", All, True)
render_filter_chip(chip)
```

---

### 2. render_filter_chips

**Purpose:** Render multiple filter chips in a container

**Signature:**
```gleam
pub fn render_filter_chips(chips: List(FilterChip)) -> element.Element(msg)
```

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

**Example:**
```gleam
let chips = [
  FilterChip("All", All, True),
  FilterChip("Verified Only", VerifiedOnly, False),
  FilterChip("Branded", Branded, False),
]
render_filter_chips(chips)
```

---

### 3. render_filter_chips_with_dropdown

**Purpose:** Render filter chips with integrated category dropdown

**Signature:**
```gleam
pub fn render_filter_chips_with_dropdown(
  chips: List(FilterChip),
  categories: List(String),
) -> element.Element(msg)
```

**Renders:**
```html
<div class="filter-chips-container">
  <div class="filter-chips" role="group" aria-label="Food search filters">
    <!-- Chips -->
  </div>
  <div class="filter-dropdown-container">
    <select class="filter-dropdown" data-filter="category" disabled>
      <option value="">Select Category...</option>
      <option value="Vegetables">Vegetables</option>
      <!-- More options -->
    </select>
  </div>
</div>
```

**Features:**
- Dropdown is **disabled** by default
- Dropdown becomes **enabled** when "By Category" chip is selected
- Includes all categories as options
- Proper ARIA labels

**Example:**
```gleam
let chips = default_filter_chips()
let categories = ["Vegetables", "Fruits", "Proteins"]
render_filter_chips_with_dropdown(chips, categories)
```

---

### 4. default_filter_chips

**Purpose:** Get standard filter chips with sensible defaults

**Signature:**
```gleam
pub fn default_filter_chips() -> List(FilterChip)
```

**Returns:**
```gleam
[
  FilterChip("All", All, True),              // Selected
  FilterChip("Verified Only", VerifiedOnly, False),
  FilterChip("Branded", Branded, False),
  FilterChip("By Category", ByCategory, False),
]
```

**Example:**
```gleam
let chips = default_filter_chips()
// chips has 4 items with "All" selected
```

---

### 5. default_categories

**Purpose:** Get standard food categories

**Signature:**
```gleam
pub fn default_categories() -> List(String)
```

**Returns:**
```gleam
[
  "Vegetables",
  "Fruits",
  "Proteins",
  "Grains",
  "Dairy",
  "Oils & Fats",
  "Condiments",
  "Beverages",
  "Snacks",
  "Prepared Foods",
]
```

**Example:**
```gleam
let cats = default_categories()
// cats has 10 common food categories
```

---

### 6. update_selected_filter

**Purpose:** Update chip selection state (single-selection pattern)

**Signature:**
```gleam
pub fn update_selected_filter(
  chips: List(FilterChip),
  target_filter: FilterType,
) -> List(FilterChip)
```

**Behavior:**
- Sets the target filter's chip as selected
- Deselects all other chips
- Returns updated chip list

**Example:**
```gleam
let chips = default_filter_chips()
// chips: [All(selected=True), Verified(selected=False), ...]

let updated = update_selected_filter(chips, VerifiedOnly)
// updated: [All(selected=False), Verified(selected=True), ...]
```

---

## Complete Usage Examples

### Example 1: Basic Rendering

```gleam
import meal_planner/ui/components/food_search as fs

pub fn render_food_filters() {
  fs.default_filter_chips()
  |> fs.render_filter_chips
}
```

### Example 2: With Dropdown

```gleam
pub fn render_food_filters_full() {
  let chips = fs.default_filter_chips()
  let categories = fs.default_categories()

  fs.render_filter_chips_with_dropdown(chips, categories)
}
```

### Example 3: Custom Filters

```gleam
pub fn render_custom_filters() {
  let custom_chips = [
    fs.FilterChip("All", fs.All, True),
    fs.FilterChip("Organic Only", fs.VerifiedOnly, False),
    fs.FilterChip("Popular Brands", fs.Branded, False),
  ]

  fs.render_filter_chips(custom_chips)
}
```

### Example 4: Handling Filter Changes

```gleam
pub fn apply_filter(selected_filter: fs.FilterType) {
  let chips = fs.default_filter_chips()
  let updated_chips = fs.update_selected_filter(chips, selected_filter)

  // Re-render with updated state
  fs.render_filter_chips_with_dropdown(
    updated_chips,
    fs.default_categories(),
  )
}
```

### Example 5: In a Full Page

```gleam
pub fn food_search_page() {
  html.div([attribute.class("page")], [
    html.h1([], [element.text("Search Foods")]),

    // Render filter chips
    fs.render_filter_chips_with_dropdown(
      fs.default_filter_chips(),
      fs.default_categories(),
    ),

    // Search input
    html.input([
      attribute.type_("search"),
      attribute.placeholder("Search foods..."),
    ], []),

    // Results container
    html.div([attribute.id("results")], []),
  ])
}
```

---

## HTML Output Structure

### Single Chip
```html
<button class="filter-chip"
        data-filter="all"
        aria-selected="false"
        type="button">
  All
</button>
```

### Chips Container
```html
<div class="filter-chips-container">
  <div class="filter-chips"
       role="group"
       aria-label="Food search filters">
    <button class="filter-chip filter-chip-selected" data-filter="all">All</button>
    <button class="filter-chip" data-filter="verified">Verified Only</button>
    <button class="filter-chip" data-filter="branded">Branded</button>
    <button class="filter-chip" data-filter="category">By Category</button>
  </div>
</div>
```

### With Dropdown
```html
<div class="filter-chips-container">
  <div class="filter-chips" role="group" aria-label="Food search filters">
    <!-- 4 chips -->
  </div>
  <div class="filter-dropdown-container">
    <select class="filter-dropdown" data-filter="category" disabled>
      <option value="">Select Category...</option>
      <option>Vegetables</option>
      <option>Fruits</option>
      <option>Proteins</option>
      <!-- etc -->
    </select>
  </div>
</div>
```

---

## JavaScript Integration

### Hook Into Filter Changes

```javascript
// Listen for chip clicks
document.addEventListener('click', (event) => {
  const filterType = event.target.dataset.filter;

  if (filterType) {
    console.log('Filter selected:', filterType);
    handleFilterChange(filterType);
  }
});

function handleFilterChange(filterType) {
  // Handle: "all", "verified", "branded", "category"
  switch (filterType) {
    case 'all':
      console.log('Showing all foods');
      break;
    case 'verified':
      console.log('Showing verified foods only');
      break;
    case 'branded':
      console.log('Showing branded foods only');
      break;
    case 'category':
      console.log('Category filter selected');
      break;
  }

  // Fetch updated results
  refetchResults(filterType);
}
```

### Handle Dropdown Changes

```javascript
const dropdown = document.querySelector('[data-filter="category"]');
if (dropdown) {
  dropdown.addEventListener('change', (event) => {
    const category = event.target.value;
    console.log('Category selected:', category);

    // Fetch with category filter
    refetchResults('category', category);
  });
}
```

### Complete Handler

```javascript
async function refetchResults(filterType, categoryValue = null) {
  const params = new URLSearchParams();
  params.append('filter', filterType);

  if (categoryValue) {
    params.append('category', categoryValue);
  }

  try {
    const response = await fetch(`/api/food-search?${params}`);
    const results = await response.json();
    renderResults(results);
  } catch (error) {
    console.error('Failed to fetch results:', error);
  }
}

function renderResults(results) {
  const container = document.getElementById('results');
  container.innerHTML = '';

  results.forEach(food => {
    const div = document.createElement('div');
    div.className = 'food-result';
    div.innerHTML = `
      <h3>${food.description}</h3>
      <p>${food.category}</p>
      <p>${food.data_type}</p>
    `;
    container.appendChild(div);
  });
}
```

---

## CSS Styling

### Minimal Styling

```css
.filter-chip {
  padding: 0.5rem 1rem;
  border: 1px solid #ccc;
  background: white;
  cursor: pointer;
  border-radius: 4px;
}

.filter-chip-selected {
  background: #007bff;
  color: white;
  border-color: #0056b3;
}

.filter-dropdown {
  padding: 0.5rem;
  border: 1px solid #ccc;
}

.filter-dropdown:disabled {
  opacity: 0.5;
}
```

### Advanced Styling

```css
.filter-chips-container {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 2rem;
}

.filter-chips {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
  align-items: center;
}

.filter-chip {
  padding: 0.5rem 1rem;
  border: 1px solid #d1d5db;
  background: #f9fafb;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 200ms ease;
}

.filter-chip:hover:not(:disabled) {
  border-color: #9ca3af;
  background: #f3f4f6;
}

.filter-chip-selected {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  border-color: #1d4ed8;
  color: white;
  box-shadow: 0 2px 8px rgba(37, 99, 235, 0.3);
}

.filter-chip-selected:hover {
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.4);
}

.filter-dropdown-container {
  display: flex;
}

.filter-dropdown {
  flex: 1;
  padding: 0.5rem 1rem;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 0.875rem;
  background: white;
  cursor: pointer;
  transition: all 200ms ease;
}

.filter-dropdown:not(:disabled):hover {
  border-color: #9ca3af;
}

.filter-dropdown:disabled {
  background: #f9fafb;
  color: #9ca3af;
  cursor: not-allowed;
  opacity: 0.6;
}

.filter-dropdown-active {
  border-color: #3b82f6;
  background: #f0f9ff;
}
```

---

## API Integration

### Request Format

```javascript
// Single filter
GET /api/food-search?query=chicken&filter=verified

// With category
GET /api/food-search?query=chicken&filter=category&category=Proteins
```

### Response Format

```json
{
  "results": [
    {
      "fdc_id": 167168,
      "description": "Chicken, raw",
      "category": "Proteins",
      "data_type": "Survey (FNDDS)",
      "verified": true,
      "branded": false
    }
  ],
  "total": 42
}
```

---

## Testing

```gleam
import gleeunit/should
import meal_planner/ui/components/food_search as fs

pub fn test_render_filter_chip() {
  let chip = fs.FilterChip("All", fs.All, True)
  let element = fs.render_filter_chip(chip)
  // Element type is element.Element(msg)
  should.be_ok(Ok(element))
}

pub fn test_default_chips_count() {
  fs.default_filter_chips()
  |> list.length
  |> should.equal(4)
}

pub fn test_update_selection() {
  let chips = fs.default_filter_chips()
  let updated = fs.update_selected_filter(chips, fs.Branded)

  list.find(updated, fn(c) { c.filter_type == fs.Branded })
  |> option.map(fn(c) { c.selected })
  |> should.equal(option.Some(True))
}
```

---

## Best Practices

1. **Always start with defaults:** Use `default_filter_chips()` and `default_categories()`
2. **Update state carefully:** Use `update_selected_filter()` for single-selection
3. **Re-render on changes:** When filter changes, call render functions again
4. **Handle JavaScript:** Always add event listeners for interactive elements
5. **Style appropriately:** Apply CSS classes from documentation
6. **Test integration:** Verify filter changes trigger API calls
7. **Monitor accessibility:** Use browser devtools to verify ARIA attributes

---

## Troubleshooting

### Dropdown not responding to filter selection

**Issue:** Dropdown stays disabled even when "By Category" is selected

**Solution:** Ensure you're using `update_selected_filter()` to update state before re-rendering

```gleam
// Wrong - dropdown stays disabled
let chips = fs.default_filter_chips()
fs.render_filter_chips_with_dropdown(chips, categories)

// Correct - updates selection first
let chips = fs.default_filter_chips()
let updated = fs.update_selected_filter(chips, fs.ByCategory)
fs.render_filter_chips_with_dropdown(updated, categories)
```

### JavaScript not detecting clicks

**Issue:** Filter changes not triggering API calls

**Solution:** Verify event listeners target the correct data attributes

```javascript
// Wrong - won't match any elements
document.addEventListener('click', (e) => {
  console.log(e.target.getAttribute('data-filter'));
});

// Correct - targets chips with data-filter attribute
document.addEventListener('click', (e) => {
  if (e.target.dataset.filter) {
    console.log('Filter:', e.target.dataset.filter);
  }
});
```

---

## Summary

The food search filter chips component provides:
- **Type-safe** Gleam implementation
- **Accessible** HTML with ARIA attributes
- **Flexible** rendering with multiple variants
- **Easy integration** with JavaScript
- **Production-ready** code

Use it to add professional food search filtering to your meal planner application.
