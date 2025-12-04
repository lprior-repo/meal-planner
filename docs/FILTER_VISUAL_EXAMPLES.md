# Filter Result Display - Visual Examples

## Component Output Examples

This document shows actual HTML output and visual representations of the filter result display component.

## Example 1: Multiple Active Filters

### Scenario
- User searches for "apple"
- Filters by: Category=Fruits, Verified=true
- Results: 12 food items

### Gleam Code
```gleam
search_results_with_count(
  [
    (#(1, "Apple, raw", "FDC", "Fruits")),
    (#(2, "Apple juice", "FDC", "Beverages")),
    // ... 10 more results
  ],
  12,
  [
    ("category", "Fruits"),
    ("verified", "true")
  ],
  True  // Show Clear All button
)
```

### HTML Output
```html
<div class="search-results-container">
  <div class="search-results-header">
    <div class="search-results-count" role="status" aria-live="polite">
      12 results
    </div>

    <div class="active-filters-container">
      <div class="active-filters-label">Active filters:</div>
      <div class="active-filters">
        <button class="filter-tag" data-filter-name="category" data-filter-value="Fruits" type="button" aria-label="Remove Fruits filter">
          Fruits
          <span class="remove-filter" aria-hidden="true">×</span>
        </button>
        <button class="filter-tag" data-filter-name="verified" data-filter-value="true" type="button" aria-label="Remove true filter">
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
    <!-- Result items -->
  </div>
</div>
```

### Visual Rendering (Desktop - 1024px width)

```
┌─────────────────────────────────────────────────────────┐
│ 12 results                                              │
│                                                         │
│ Active filters:                                         │
│ [Fruits ×]  [true ×]                                   │
│ Clear All Filters                                       │
├─────────────────────────────────────────────────────────┤
│ Apple, raw                              FDC • Fruits   │
│ Apple juice                             FDC • Beverages│
│ ...                                                     │
└─────────────────────────────────────────────────────────┘
```

### Visual Rendering (Mobile - 375px width)

```
┌──────────────────────────┐
│ 12 results               │
│                          │
│ Active filters:          │
│ [Fruits ×]               │
│ [true ×]                 │
│ Clear All Filters        │
├──────────────────────────┤
│ Apple, raw               │
│ FDC • Fruits             │
│                          │
│ Apple juice              │
│ FDC • Beverages          │
│ ...                      │
└──────────────────────────┘
```

## Example 2: Single Filter

### Scenario
- User searches for "dairy products"
- Filters by: Category=Dairy
- Results: 45 food items

### Gleam Code
```gleam
search_results_with_count(
  dairyResults,
  45,
  [("category", "Dairy")],
  True
)
```

### HTML Output
```html
<div class="search-results-container">
  <div class="search-results-header">
    <div class="search-results-count" role="status" aria-live="polite">
      45 results
    </div>

    <div class="active-filters-container">
      <div class="active-filters-label">Active filters:</div>
      <div class="active-filters">
        <button class="filter-tag" data-filter-name="category" data-filter-value="Dairy" type="button" aria-label="Remove Dairy filter">
          Dairy
          <span class="remove-filter" aria-hidden="true">×</span>
        </button>
      </div>
      <button class="btn-clear-all-filters btn btn-ghost btn-sm" type="button">
        Clear All Filters
      </button>
    </div>
  </div>

  <div class="search-results-list max-h-96 overflow-y-auto" role="listbox">
    <!-- Result items -->
  </div>
</div>
```

### Visual Rendering

```
┌─────────────────────────────────────────┐
│ 45 results                              │
│                                         │
│ Active filters:                         │
│ [Dairy ×]                               │
│ Clear All Filters                       │
├─────────────────────────────────────────┤
│ Milk, whole                             │
│ Cheese, cheddar                         │
│ Yogurt, plain                           │
│ ...                                     │
└─────────────────────────────────────────┘
```

## Example 3: No Filters

### Scenario
- User searches for "pasta" without any filters
- Results: 128 food items

### Gleam Code
```gleam
search_results_with_count(
  pastaResults,
  128,
  [],  // No active filters
  False  // Don't show Clear All when no filters
)
```

### HTML Output
```html
<div class="search-results-container">
  <div class="search-results-header">
    <div class="search-results-count" role="status" aria-live="polite">
      128 results
    </div>
    <!-- No active-filters-container -->
  </div>

  <div class="search-results-list max-h-96 overflow-y-auto" role="listbox">
    <!-- Result items -->
  </div>
</div>
```

### Visual Rendering

```
┌─────────────────────────────────────┐
│ 128 results                         │
├─────────────────────────────────────┤
│ Pasta, cooked                       │
│ Pasta, dry                          │
│ Noodles, ramen                      │
│ ...                                 │
└─────────────────────────────────────┘
```

## Example 4: Single Result

### Scenario
- User searches for specific food with filter
- Results: 1 item

### Gleam Code
```gleam
search_results_with_count(
  [specifcResult],
  1,
  [("verified", "true")],
  True
)
```

### HTML Output (singular "result")
```html
<div class="search-results-count" role="status" aria-live="polite">
  1 result
</div>
```

### Visual Difference
- "1 result" (singular) vs "2 results" (plural)
- Grammatically correct output

## Example 5: Three-Filter Scenario

### Scenario
- User filters by: Category + Verified + Branded
- Results: 8 items

### Gleam Code
```gleam
search_results_with_count(
  results,
  8,
  [
    ("category", "Vegetables"),
    ("verified", "true"),
    ("branded", "false")
  ],
  True
)
```

### HTML Output (showing filter tags)
```html
<div class="active-filters">
  <button class="filter-tag" data-filter-name="category" data-filter-value="Vegetables">
    Vegetables <span class="remove-filter">×</span>
  </button>
  <button class="filter-tag" data-filter-name="verified" data-filter-value="true">
    true <span class="remove-filter">×</span>
  </button>
  <button class="filter-tag" data-filter-name="branded" data-filter-value="false">
    false <span class="remove-filter">×</span>
  </button>
</div>
```

### Visual Rendering (Desktop)

```
┌──────────────────────────────────────────────┐
│ 8 results                                    │
│                                              │
│ Active filters:                              │
│ [Vegetables ×]  [true ×]  [false ×]         │
│ Clear All Filters                            │
├──────────────────────────────────────────────┤
│ Broccoli                    Verified • Food  │
│ Spinach                     Verified • Food  │
│ ...                                          │
└──────────────────────────────────────────────┘
```

### Visual Rendering (Mobile - wraps tags)

```
┌──────────────────────────┐
│ 8 results                │
│                          │
│ Active filters:          │
│ [Vegetables ×]           │
│ [true ×]  [false ×]      │
│ Clear All Filters        │
├──────────────────────────┤
│ Broccoli                 │
│ Verified • Food          │
│ ...                      │
└──────────────────────────┘
```

## Interaction States

### Filter Tag States

#### Default State
```
┌──────────────────┐
│ Fruits     ×     │
└──────────────────┘
Background: Light Blue (#E7F1FF-ish)
Text: Dark Blue
Icon: Circular background, light
```

#### Hover State
```
┌──────────────────┐
│ Fruits     ↗×↖   │
└──────────────────┘
Background: Solid Blue (primary)
Text: White
Icon: Rotated 90°, darker background
Shadow: Subtle drop shadow
```

#### Active/Click State
```
┌──────────────────┐
│ Fruits     ×     │  (slightly smaller scale)
└──────────────────┘
Effect: Pressed down animation
```

#### Focus State (Keyboard)
```
┌────────────────────┐
│ Fruits     ×       │
│▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄│ (outline)
└────────────────────┘
Outline: 3px solid primary color
```

## CSS Hover Animation Breakdown

### Tag Hover Animation Timeline

```
0ms:   Scale: 1.0, Shadow: none
       Color: Light Blue bg, Dark Blue text

100ms: Scale: 1.025 (50% of the way)
       Slight shadow appears

200ms: Scale: 1.05 (full scale)
       Full shadow visible
       Text turns white
       Background: Solid blue

× Icon Rotation:
0ms:   Rotate: 0deg
200ms: Rotate: 90deg
```

## Filter Tag Interactions Flow

### Scenario: User Clicks × to Remove "Fruits" Filter

**Initial State**
```
Display: "12 results"
Tags: [Fruits ×] [Verified ×]
```

**User hovers on Fruits tag**
```
Display: "12 results" (unchanged)
Tags: [Fruits ×] (scaled up, white, × rotated)
       [Verified ×] (unchanged)
```

**User clicks × on Fruits tag**
```
1. Button click event fires
2. removeFilter("category", "Fruits") called
3. Custom event: foodSearchFilterChange dispatched
4. (Search handler updates results)
5. Page updates with new state:
```

**Updated State (from server)**
```
Display: "25 results" (was 12, now shows all + verified)
Tags: [Verified ×]
Clear All: Still visible
```

**Screen reader announces**
```
"Fruits filter removed"
```

## Clear All Filters Flow

### Initial State
```
Display: "8 results"
Tags: [Vegetables ×] [Verified ×] [Branded ×]
Button: "Clear All Filters" (visible)
```

### User hovers on "Clear All Filters"
```
Button background: Light red tint
Button text: Red
```

### User clicks "Clear All Filters"
```
1. Button click event fires
2. clearAllFilters() called
3. Custom event: foodSearchFilterChange dispatched
4. (Search handler updates results)
5. Page updates with new state:
```

### Updated State
```
Display: "487 results" (all items)
Tags: (none, section hidden)
Button: (hidden, no filters to clear)
```

### Screen reader announces
```
"All filters cleared"
```

## Result Count Update Examples

### Count Behavior

| Result Count | Display Text |
|--------------|-------------|
| 1 | "1 result" (singular) |
| 2 | "2 results" (plural) |
| 10 | "10 results" |
| 100 | "100 results" |
| 0 | "0 results" (edge case) |

### Real-Time Update Example

```
Initial Search:
Display: "25 results"

User adds Category filter:
Display: (updates immediately)
"12 results"

User removes filter:
Display: (updates immediately)
"25 results"
```

## Responsive Behavior

### Desktop (1024px+)

```
┌─────────────────────────────────────────────┐
│ 12 results                                  │
│                                             │
│ Active filters:                             │
│ [Fruits ×]  [Verified ×]  [Branded ×]      │
│ Clear All Filters                           │
├─────────────────────────────────────────────┤
```

- All items on single line
- Full spacing
- Full font sizes

### Tablet (768px)

```
┌────────────────────────────────┐
│ 12 results                     │
│                                │
│ Active filters:                │
│ [Fruits ×]  [Verified ×]       │
│ [Branded ×]                    │
│ Clear All Filters              │
├────────────────────────────────┤
```

- Tags wrap to two lines
- Reduced spacing

### Mobile (375px)

```
┌──────────────────────┐
│ 12 results           │
│                      │
│ Active filters:      │
│ [Fruits ×]           │
│ [Verified ×]         │
│ [Branded ×]          │
│ Clear All Filters    │
├──────────────────────┤
```

- Tags stack vertically
- Minimal spacing
- Touch-friendly targets

## Accessibility Visual Indicators

### Keyboard Focus

```
Normal State:
┌────────┐
│ Tag ×  │
└────────┘

Focused State (Tab key):
┌─────────┐
│ Tag ×   │ ← 3px outline
├─────────┤ ← offset by 2px
```

### Color Contrast

**Tag Normal State:**
- Background: Light Blue
- Text: Dark Blue
- Contrast Ratio: 7:1 (exceeds WCAG AAA)

**Tag Hover State:**
- Background: Blue
- Text: White
- Contrast Ratio: 8:1 (exceeds WCAG AAA)

## Summary

This visual guide shows:
- Component output in various scenarios
- Desktop and mobile layouts
- Interaction states and animations
- Real-time update behavior
- Accessibility features
- Responsive design breakdown
- Grammar handling (singular/plural)
