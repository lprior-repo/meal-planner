# UI Components Index

## Food Search Components

### Main Module
- **File:** `food_search.gleam`
- **Lines:** 277
- **Status:** Production Ready
- **Return Type:** `element.Element(msg)`

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

### Public Functions

1. **render_filter_chip**
   ```gleam
   pub fn render_filter_chip(chip: FilterChip) -> element.Element(msg)
   ```
   Renders a single filter chip button with data attributes and ARIA support.

2. **render_filter_chips**
   ```gleam
   pub fn render_filter_chips(chips: List(FilterChip)) -> element.Element(msg)
   ```
   Renders multiple filter chips in an accessible container group.

3. **render_filter_chips_with_dropdown**
   ```gleam
   pub fn render_filter_chips_with_dropdown(
     chips: List(FilterChip),
     categories: List(String),
   ) -> element.Element(msg)
   ```
   Renders filter chips with integrated category dropdown.

4. **default_filter_chips**
   ```gleam
   pub fn default_filter_chips() -> List(FilterChip)
   ```
   Returns standard filter chips with "All" selected.

5. **default_categories**
   ```gleam
   pub fn default_categories() -> List(String)
   ```
   Returns 10 common food categories.

6. **update_selected_filter**
   ```gleam
   pub fn update_selected_filter(
     chips: List(FilterChip),
     target_filter: FilterType,
   ) -> List(FilterChip)
   ```
   Updates chip selection state (single-selection pattern).

### Documentation Files

- **food_search_example.gleam** - 7 complete usage examples
- **../docs/food_search_component.md** - Technical documentation (300+ lines)
- **../FOOD_SEARCH_USAGE.md** - Comprehensive usage guide (500+ lines)
- **../../FOOD_SEARCH_COMPONENT_README.md** - Implementation summary

### Quick Start

```gleam
import meal_planner/ui/components/food_search as fs

pub fn render_food_filters() {
  fs.default_filter_chips()
  |> fs.render_filter_chips_with_dropdown(_, fs.default_categories())
}
```

### HTML Output

The component generates semantic HTML:

```html
<div class="filter-chips-container">
  <div class="filter-chips" role="group" aria-label="Food search filters">
    <button class="filter-chip filter-chip-selected" data-filter="all" aria-selected="true">All</button>
    <button class="filter-chip" data-filter="verified" aria-selected="false">Verified Only</button>
    <button class="filter-chip" data-filter="branded" aria-selected="false">Branded</button>
    <button class="filter-chip" data-filter="category" aria-selected="false">By Category</button>
  </div>
  <div class="filter-dropdown-container">
    <select class="filter-dropdown" data-filter="category" disabled aria-label="Filter by category">
      <option value="">Select Category...</option>
      <option value="Vegetables">Vegetables</option>
      <!-- more options -->
    </select>
  </div>
</div>
```

### Features

- Type-safe Gleam implementation
- Lustre HTML element rendering
- Accessible with ARIA attributes
- Data attributes for JavaScript integration
- CSS class-based styling
- Single-selection pattern
- Smart dropdown enable/disable
- Server-side rendering compatible

### Integration

1. **Import in your module:**
   ```gleam
   import meal_planner/ui/components/food_search as fs
   ```

2. **Render in your page:**
   ```gleam
   pub fn food_search_page() {
     fs.render_filter_chips_with_dropdown(
       fs.default_filter_chips(),
       fs.default_categories()
     )
   }
   ```

3. **Hook in JavaScript:**
   ```javascript
   document.addEventListener('click', (e) => {
     if (e.target.dataset.filter) {
       handleFilterChange(e.target.dataset.filter);
     }
   });
   ```

4. **Style with CSS:**
   ```css
   .filter-chip-selected {
     background: #0066cc;
     color: white;
   }
   ```

### Data Attributes

- `data-filter="all"` - All foods filter
- `data-filter="verified"` - Verified foods filter
- `data-filter="branded"` - Branded foods filter
- `data-filter="category"` - Category dropdown filter

### CSS Classes

- `.filter-chips-container` - Main container
- `.filter-chips` - Chips group
- `.filter-chip` - Individual chip
- `.filter-chip-selected` - Selected chip
- `.filter-dropdown-container` - Dropdown wrapper
- `.filter-dropdown` - Select element
- `.filter-dropdown-active` - Active dropdown

### Build Status

✓ Compiles successfully
✓ All types check
✓ Module imports work
✓ Functions export correctly

### Related Components

- `button.gleam` - Basic button components
- `card.gleam` - Card containers
- `forms.gleam` - Form inputs
- `loading.gleam` - Loading states

### See Also

- Gleam documentation: https://gleam.run
- Lustre framework: https://github.com/lustre-labs/lustre
- HTML accessibility: https://www.w3.org/WAI/
