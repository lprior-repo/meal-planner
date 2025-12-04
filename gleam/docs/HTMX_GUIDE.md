# HTMX Usage Guide for Meal Planner

## Table of Contents
1. [Introduction](#introduction)
2. [Why HTMX for This Project](#why-htmx-for-this-project)
3. [Common Patterns](#common-patterns)
4. [HTMX Attributes Reference](#htmx-attributes-reference)
5. [Loading States](#loading-states)
6. [Best Practices](#best-practices)
7. [Real Examples from the Codebase](#real-examples-from-the-codebase)
8. [Troubleshooting](#troubleshooting)

---

## Introduction

This guide documents how to use HTMX in the meal-planner project. HTMX allows us to build dynamic, interactive interfaces using only HTML attributes - **no custom JavaScript required**.

### Core Principle

**ALL interactivity MUST use HTMX attributes. Custom JavaScript files are prohibited.**

The only exception is the HTMX library itself, which is already included in the base template.

---

## Why HTMX for This Project

### Architecture Benefits

1. **Server-Side Rendering (SSR)**: All HTML is generated in Gleam using Lustre, ensuring type safety and consistency
2. **No JavaScript Files**: Eliminates client-side state management complexity
3. **URL-Based State**: All application state lives in URL query parameters, making features bookmarkable and shareable
4. **Progressive Enhancement**: Works without JavaScript, degrades gracefully
5. **Reduced Payload**: Removed ~15KB of custom JavaScript during migration

### Developer Benefits

1. **Type Safety**: Gleam's type system validates all data structures
2. **Single Source of Truth**: Filter logic, search logic, and state management all in Gleam
3. **Easier Testing**: Server-side logic is easier to test than client-side JavaScript
4. **Maintainability**: No context switching between languages
5. **Accessibility**: Semantic HTML by default

---

## Common Patterns

### 1. Search with Debouncing

**Use Case**: Search input that triggers API calls as user types

**Pattern**:
```html
<input type="search"
       name="q"
       hx-get="/api/foods/search"
       hx-trigger="input changed delay:300ms"
       hx-target="#search-results"
       hx-swap="innerHTML"
       hx-push-url="true"
       hx-indicator="#search-loading" />
<span id="search-loading" class="htmx-indicator">Loading...</span>
```

**Key Points**:
- `delay:300ms` - Debounces input to avoid excessive API calls
- `changed` - Only triggers if value actually changed
- `hx-push-url="true"` - Updates browser URL for bookmarking
- `hx-indicator` - Shows loading state during request

---

### 2. Filter Chips

**Use Case**: Clickable filter buttons that update search results

**Pattern**:
```html
<button class="filter-chip"
        data-filter="verified"
        hx-get="/api/foods/search?filter=verified"
        hx-target="#search-results"
        hx-swap="innerHTML"
        hx-push-url="true"
        hx-include="[name='q']"
        hx-indicator="#filter-loading"
        aria-pressed="false"
        role="button">
  Verified Only
</button>
```

**Key Points**:
- `hx-include="[name='q']"` - Includes search query from input field
- `data-filter` - Custom attribute for CSS styling (not HTMX)
- `aria-pressed` - Accessibility for toggle state
- Query parameters in URL maintain all filter state

---

### 3. Dropdown with Auto-Submit

**Use Case**: Category dropdown that filters results on selection change

**Pattern**:
```html
<select name="category"
        hx-get="/api/foods/search"
        hx-trigger="change"
        hx-target="#search-results"
        hx-swap="innerHTML"
        hx-push-url="true"
        hx-include="[name='q'], [name='filter']"
        aria-label="Filter by category">
  <option value="">All Categories</option>
  <option value="Vegetables">Vegetables</option>
  <option value="Fruits">Fruits</option>
</select>
```

**Key Points**:
- `hx-trigger="change"` - Fires on dropdown selection
- Multiple `hx-include` selectors separated by commas
- Empty value for "All Categories" option

---

### 4. Form Submission with Partial Update

**Use Case**: Submit form and update only part of the page

**Pattern**:
```html
<form hx-post="/api/logs"
      hx-target="#log-list"
      hx-swap="afterbegin">
  <input name="food_id" type="hidden" value="12345" />
  <input name="quantity" type="number" />
  <button type="submit">Log Food</button>
</form>
```

**Key Points**:
- `hx-post` - POST request on form submit
- `hx-swap="afterbegin"` - Inserts new content at start of target
- Form fields automatically included in request

---

### 5. Clear Button Pattern

**Use Case**: Button to clear search and reset filters

**Pattern**:
```html
<button type="button"
        class="btn-clear-all-filters"
        hx-get="/api/foods/search?q="
        hx-target="#search-results"
        hx-swap="innerHTML"
        hx-push-url="true">
  Clear All Filters
</button>
```

**Key Points**:
- `?q=` - Empty query parameter clears search
- Resets URL to default state
- Server returns default/empty state HTML

---

## HTMX Attributes Reference

### Core Request Attributes

| Attribute | Purpose | Example |
|-----------|---------|---------|
| `hx-get` | Issue GET request to URL | `hx-get="/api/foods"` |
| `hx-post` | Issue POST request to URL | `hx-post="/api/logs"` |
| `hx-put` | Issue PUT request to URL | `hx-put="/api/foods/123"` |
| `hx-delete` | Issue DELETE request to URL | `hx-delete="/api/logs/456"` |
| `hx-patch` | Issue PATCH request to URL | `hx-patch="/api/foods/123"` |

### Response Handling

| Attribute | Purpose | Values |
|-----------|---------|--------|
| `hx-target` | CSS selector for where to put response | `#search-results`, `.food-list` |
| `hx-swap` | How to swap content into target | `innerHTML`, `outerHTML`, `beforebegin`, `afterbegin`, `beforeend`, `afterend` |

**Swap Strategy Details**:
- `innerHTML` - Replace inner content (most common)
- `outerHTML` - Replace entire element including wrapper
- `afterbegin` - Insert at start of target's children
- `beforeend` - Insert at end of target's children
- `beforebegin` - Insert before target element
- `afterend` - Insert after target element

### Trigger Events

| Attribute | Purpose | Examples |
|-----------|---------|----------|
| `hx-trigger` | Event that triggers request | `click`, `change`, `input`, `submit` |

**Advanced Trigger Modifiers**:
```html
<!-- Debounce: wait 300ms after typing stops -->
hx-trigger="input changed delay:300ms"

<!-- Throttle: fire at most once per second -->
hx-trigger="input throttle:1s"

<!-- Only from specific element -->
hx-trigger="input changed delay:300ms from:#search-input"

<!-- Multiple events -->
hx-trigger="click, keyup[key=='Enter']"
```

### Request Parameters

| Attribute | Purpose | Example |
|-----------|---------|---------|
| `hx-include` | Include additional form fields | `hx-include="[name='q']"` |
| `hx-params` | Filter which params to send | `hx-params="q,filter"` or `hx-params="*"` |
| `hx-vals` | Add static JSON values | `hx-vals='{"priority": "high"}'` |

### URL Management

| Attribute | Purpose | Values |
|-----------|---------|--------|
| `hx-push-url` | Update browser URL | `true`, `false`, or specific URL |
| `hx-replace-url` | Replace browser URL (no history) | `true`, `false`, or specific URL |

### Loading States

| Attribute | Purpose | Example |
|-----------|---------|---------|
| `hx-indicator` | Element to show during request | `hx-indicator="#loading"` |

### Other Useful Attributes

| Attribute | Purpose | Example |
|-----------|---------|---------|
| `hx-confirm` | Confirmation dialog before request | `hx-confirm="Are you sure?"` |
| `hx-boost` | Progressively enhance links/forms | `hx-boost="true"` |
| `hx-select` | Select part of response to swap | `hx-select="#results"` |

---

## Loading States

### Basic Loading Indicator

**HTML**:
```html
<span id="search-loading" class="htmx-indicator">Loading...</span>
```

**CSS**:
```css
.htmx-indicator {
  opacity: 0;
  transition: opacity 200ms ease-in;
}

.htmx-request .htmx-indicator,
.htmx-request.htmx-indicator {
  opacity: 1;
}
```

**How It Works**:
- HTMX automatically adds `htmx-request` class to requesting element
- Indicator becomes visible during request
- Fades out when request completes

### Multiple Loading States

**Pattern**: Different indicators for different operations

```html
<!-- Search loading -->
<input hx-get="/api/search" hx-indicator="#search-loading" />
<span id="search-loading" class="htmx-indicator">Searching...</span>

<!-- Filter loading -->
<button hx-get="/api/filter" hx-indicator="#filter-loading">Filter</button>
<span id="filter-loading" class="htmx-indicator">Filtering...</span>

<!-- Category loading -->
<select hx-get="/api/category" hx-indicator="#category-loading">...</select>
<span id="category-loading" class="htmx-indicator">Loading categories...</span>
```

### Skeleton Loading States

**Server-Side Rendered Skeleton**:
```gleam
pub fn search_results_loading() -> String {
  "<div class=\"search-results-loading\" aria-busy=\"true\">"
  <> "<div class=\"skeleton skeleton-item\"></div>"
  <> "<div class=\"skeleton skeleton-item\"></div>"
  <> "<div class=\"skeleton skeleton-item\"></div>"
  <> "</div>"
}
```

**CSS**:
```css
.skeleton {
  background: linear-gradient(
    90deg,
    #f0f0f0 25%,
    #e0e0e0 50%,
    #f0f0f0 75%
  );
  background-size: 200% 100%;
  animation: skeleton-loading 1.5s infinite;
}

@keyframes skeleton-loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

.skeleton-item {
  height: 60px;
  margin-bottom: 10px;
  border-radius: 4px;
}
```

---

## Best Practices

### 1. Debouncing and Throttling

**Always debounce text input searches**:
```html
<!-- ✅ GOOD: Prevents excessive API calls -->
<input hx-trigger="input changed delay:300ms" />

<!-- ❌ BAD: Fires on every keystroke -->
<input hx-trigger="input" />
```

**Use appropriate delays**:
- Search: 300ms - 500ms (balance between responsiveness and server load)
- Auto-save: 1000ms - 2000ms (less critical, save server resources)
- Real-time updates: 100ms - 200ms (critical user feedback)

---

### 2. Error Handling

**Server-Side Error Responses**:

Return meaningful HTML fragments for errors:
```gleam
// In search handler
case validate_search_query(query) {
  Error(error_msg) -> {
    let error_html =
      "<div class=\"error-message\" role=\"alert\">"
      <> escape_html(error_msg)
      <> "</div>"
    wisp.html_response(error_html, 400)
  }
  Ok(validated) -> {
    // Process search...
  }
}
```

**Client-Side Error Display**:
```html
<div id="search-results">
  <!-- HTMX will swap error message here -->
</div>
```

---

### 3. Accessibility

**Always include ARIA attributes**:
```html
<input type="search"
       aria-label="Search for foods"
       hx-get="/api/search" />

<button aria-pressed="false"
        role="button"
        hx-get="/api/filter">Filter</button>

<div id="results"
     role="listbox"
     aria-live="polite">
  <!-- Results here -->
</div>

<span class="htmx-indicator"
      aria-label="Loading search results">
  Loading...
</span>
```

**ARIA Best Practices**:
- `aria-label` - Descriptive labels for inputs/buttons
- `aria-live="polite"` - Announce updates to screen readers
- `aria-busy="true"` - Indicate loading state
- `role="alert"` - For error messages
- `role="status"` - For status updates
- `aria-pressed` - Toggle button state
- `aria-selected` - Selection state

---

### 4. URL Management

**Use `hx-push-url` for user-initiated actions**:
```html
<!-- ✅ GOOD: User can bookmark/share filter state -->
<button hx-get="/api/foods?filter=verified"
        hx-push-url="true">Verified</button>

<!-- ❌ BAD: State lost on refresh -->
<button hx-get="/api/foods?filter=verified">Verified</button>
```

**Include all state in URL parameters**:
```html
<!-- ✅ GOOD: Complete state in URL -->
hx-get="/api/foods?q=apple&filter=verified&category=Fruits"

<!-- ❌ BAD: State in separate attributes -->
hx-get="/api/foods"
hx-vals='{"filter": "verified"}'
```

---

### 5. Performance Optimization

**Minimize DOM Updates**:
```html
<!-- ✅ GOOD: Update only results container -->
<div id="search-results">
  <!-- Only this updates -->
</div>

<!-- ❌ BAD: Updates entire page -->
<body hx-get="/page">
  <!-- Entire body updates, very slow -->
</body>
```

**Use `hx-select` for large responses**:
```html
<!-- Only extract #results from response -->
<div hx-get="/api/page"
     hx-select="#results"
     hx-target="#container">
</div>
```

**Cache static content**:
```html
<!-- Headers indicate caching policy -->
<div hx-get="/api/categories">
  <!-- Server returns Cache-Control headers -->
</div>
```

---

### 6. Security

**Always validate and sanitize server-side**:
```gleam
// ✅ GOOD: Validate all inputs
pub fn validate_search_query(query: String) -> Result(String, String) {
  let trimmed = string.trim(query)

  case string.length(trimmed) < 2 {
    True -> Error("Query must be at least 2 characters")
    False -> {
      case string.length(trimmed) > 100 {
        True -> Error("Query too long")
        False -> Ok(trimmed)
      }
    }
  }
}

// Escape HTML in responses
fn escape_html(text: String) -> String {
  text
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&#39;")
}
```

**Use parameterized queries** (Gleam's `pog` library handles this):
```gleam
// ✅ GOOD: Parameterized query
pog.query("SELECT * FROM foods WHERE description LIKE $1")
|> pog.parameter(pog.text("%" <> query <> "%"))

// ❌ BAD: String concatenation (vulnerable to SQL injection)
// pog.query("SELECT * FROM foods WHERE description LIKE '%" <> query <> "%'")
```

---

## Real Examples from the Codebase

### Example 1: Search Input with Debouncing

**Location**: `gleam/src/meal_planner/ui/components/forms.gleam` (Lines 76-110)

**Gleam Component**:
```gleam
pub fn search_input(query: String, placeholder: String) -> String {
  "<div class=\"search-box\" role=\"search\">"
  <> "<input type=\"search\" class=\"input-search\" "
  <> "id=\"search-input\" "
  <> "name=\"q\" "
  <> "placeholder=\"" <> placeholder <> "\" "
  <> "aria-label=\"" <> placeholder <> "\" "
  <> "value=\"" <> query <> "\" "
  <> "hx-get=\"/api/foods/search\" "
  <> "hx-trigger=\"input changed delay:300ms\" "
  <> "hx-target=\"#food-results\" "
  <> "hx-swap=\"innerHTML\" "
  <> "hx-push-url=\"true\" "
  <> "hx-indicator=\"#search-loading\" />"
  <> "<button class=\"btn btn-primary\" type=\"submit\">Search</button>"
  <> "<span id=\"search-loading\" class=\"htmx-indicator\">Loading...</span>"
  <> "</div>"
}
```

**Features**:
- 300ms debouncing prevents excessive API calls
- `changed` modifier only triggers if value actually changed
- Loading indicator provides user feedback
- URL updates for bookmarking

---

### Example 2: Filter Chips with State Management

**Location**: `gleam/src/meal_planner/ui/components/food_search.gleam` (Lines 85-115)

**Gleam Component**:
```gleam
pub fn render_filter_chip(chip: FilterChip) -> element.Element(msg) {
  let FilterChip(label: label, filter_type: filter_type, selected: selected) = chip
  let classes = chip_classes(selected)
  let filter_str = filter_type_to_string(filter_type)

  html.button([
    attribute.class(classes),
    attribute.attribute("data-filter", filter_str),
    attribute.attribute("aria-selected", case selected {
      True -> "true"
      False -> "false"
    }),
    attribute.attribute("aria-pressed", case selected {
      True -> "true"
      False -> "false"
    }),
    attribute.attribute("role", "button"),
    attribute.type_("button"),
    // HTMX attributes for dynamic filtering
    attribute.attribute("hx-get", "/api/foods/search?filter=" <> filter_str),
    attribute.attribute("hx-target", "#search-results"),
    attribute.attribute("hx-swap", "innerHTML"),
    attribute.attribute("hx-push-url", "true"),
    attribute.attribute("hx-include", "[name='q']"),
    attribute.attribute("hx-indicator", "#filter-loading"),
  ], [element.text(label)])
}
```

**Features**:
- ARIA attributes for accessibility
- `hx-include` preserves search query
- `hx-push-url` maintains browser history
- CSS classes indicate selection state

---

### Example 3: Category Dropdown with Auto-Submit

**Location**: `gleam/src/meal_planner/ui/components/forms.gleam` (Lines 673-723)

**Gleam Component**:
```gleam
pub fn category_dropdown(
  categories: List(String),
  selected_category: option.Option(String),
  on_change_handler: String,
) -> String {
  // ... option building logic ...

  "<select class=\"category-dropdown\" "
  <> "id=\"category-filter\" "
  <> "name=\"category\" "
  <> "aria-label=\"Filter by category\" "
  <> "hx-get=\"/api/foods/search\" "
  <> "hx-trigger=\"change\" "
  <> "hx-target=\"#food-results\" "
  <> "hx-swap=\"innerHTML\" "
  <> "hx-push-url=\"true\" "
  <> "hx-include=\"[name='category']\" "
  <> "hx-indicator=\"#category-loading\">"
  <> "<option value=\"\">All Categories</option>"
  <> category_options
  <> "</select>"
  <> "<span id=\"category-loading\" class=\"htmx-indicator\">Loading...</span>"
}
```

**Features**:
- Auto-submits on category change
- Includes category name in request
- Loading indicator during fetch
- "All Categories" option clears filter

---

### Example 4: Server-Side Search Handler

**Location**: `gleam/src/meal_planner/web/handlers/search.gleam` (Lines 244-338)

**Handler Function**:
```gleam
pub fn api_foods_search(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Parse query parameters
  let parsed_query = uri.parse_query(req.query |> option.unwrap(""))

  // Read search query
  let query = case parsed_query {
    Ok(params) -> {
      case list.find(params, fn(p) { p.0 == "q" }) {
        Ok(#(_, q)) -> q
        Error(_) -> ""
      }
    }
    Error(_) -> ""
  }

  // Parse filter type: all, verified, branded, or category
  let filter_type = case parsed_query {
    Ok(params) ->
      case list.find(params, fn(p) { p.0 == "filter" }) {
        Ok(#(_, f)) -> f
        Error(_) -> "all"
      }
    Error(_) -> "all"
  }

  // Build SearchFilters based on filter type
  let filters = case filter_type {
    "verified" -> SearchFilters(verified_only: True, branded_only: False, category: None)
    "branded" -> SearchFilters(verified_only: False, branded_only: True, category: None)
    "category" -> SearchFilters(verified_only: False, branded_only: False, category: category_param)
    _ -> SearchFilters(verified_only: False, branded_only: False, category: None)
  }

  // Execute search
  let foods = case query {
    "" -> []
    q -> search_foods_filtered(ctx, q, filters, nutrition_constants.default_search_limit)
  }

  // Render HTML fragment
  let search_results = case query {
    "" -> html.div([attribute.id("search-results")], [element.text("Enter a search term")])
    q -> case foods {
      [] -> html.div([attribute.id("search-results")], [element.text("No foods found")])
      _ -> html.div([attribute.id("search-results")], list.map(foods, food_row))
    }
  }

  // Return HTML fragment (not full page)
  wisp.html_response(element.to_string(search_results), 200)
}
```

**Features**:
- Reads all state from URL query parameters
- Validates and sanitizes inputs
- Returns HTML fragments (not full pages)
- Stateless design (no server-side sessions)

---

### Example 5: Filter State Management

**Location**: `gleam/src/meal_planner/web/handlers/search.gleam` (Lines 71-109)

**Validation Function**:
```gleam
pub fn validate_filters(
  verified_param: option.Option(String),
  branded_param: option.Option(String),
  category_param: option.Option(String),
) -> Result(SearchFilters, String) {
  // Validate verified filter if present
  let verified_result = case verified_param {
    Some(v) -> validate_boolean_filter(v)
    None -> Ok(False)
  }

  // Validate branded filter if present
  let branded_result = case branded_param {
    Some(b) -> validate_boolean_filter(b)
    None -> Ok(False)
  }

  // Combine results
  use verified <- result.try(verified_result)
  use branded <- result.try(branded_result)

  // Validate and sanitize category
  let category = case category_param {
    Some(cat) -> {
      let trimmed = string.trim(cat)
      case trimmed {
        "" | "all" -> None
        c -> Some(c)
      }
    }
    None -> None
  }

  Ok(SearchFilters(
    verified_only: verified,
    branded_only: branded,
    category: category,
  ))
}
```

**Features**:
- Type-safe filter validation
- Graceful error handling
- Sanitizes all inputs
- Returns Result type for error propagation

---

## Troubleshooting

### Issue 1: Request Not Firing

**Symptoms**: Clicking button/typing in input does nothing

**Checklist**:
1. Is HTMX library loaded? Check browser console for errors
2. Is `hx-get`/`hx-post` attribute present and correct?
3. Is `hx-trigger` correct for the element type?
   - Buttons: `click` (default)
   - Inputs: `input`, `change`, `keyup`
   - Forms: `submit` (default)
4. Check browser Network tab - is request being sent?
5. Check browser Console for HTMX errors

**Debug**:
```html
<!-- Add htmx.logAll() in browser console to see all HTMX events -->
<script>htmx.logAll();</script>
```

---

### Issue 2: Response Not Updating DOM

**Symptoms**: Request succeeds but page doesn't update

**Checklist**:
1. Does `hx-target` selector match an element on page?
2. Is server returning HTML (not JSON)?
3. Check response in Network tab - is it valid HTML?
4. Is `hx-swap` appropriate for the target?
5. Are there JavaScript errors preventing HTMX from running?

**Debug**:
```gleam
// Ensure server returns HTML, not JSON
pub fn api_foods_search(...) -> wisp.Response {
  // ✅ GOOD: Returns HTML
  wisp.html_response(element.to_string(search_results), 200)

  // ❌ BAD: Returns JSON (HTMX won't swap this)
  // wisp.json_response(json.to_string(json_data), 200)
}
```

---

### Issue 3: Loading Indicator Not Showing

**Symptoms**: No visual feedback during request

**Checklist**:
1. Does element with `id` matching `hx-indicator` exist?
2. Is CSS class `.htmx-indicator` defined with `opacity: 0`?
3. Is CSS rule for `.htmx-request .htmx-indicator` defined with `opacity: 1`?
4. Check browser DevTools - is `htmx-request` class being added?

**Fix**:
```css
/* Required CSS for loading indicators */
.htmx-indicator {
  opacity: 0;
  transition: opacity 200ms ease-in;
}

.htmx-request .htmx-indicator,
.htmx-request.htmx-indicator {
  opacity: 1;
}
```

---

### Issue 4: URL Not Updating

**Symptoms**: Browser URL stays the same after request

**Checklist**:
1. Is `hx-push-url="true"` present?
2. Is server setting correct headers?
3. Check if `hx-replace-url` is being used instead

**Fix**:
```html
<!-- ✅ GOOD: Updates browser history -->
<button hx-get="/api/foods?filter=verified"
        hx-push-url="true">Filter</button>

<!-- ✅ ALSO GOOD: Replaces current history entry -->
<button hx-get="/api/foods?filter=verified"
        hx-replace-url="true">Filter</button>

<!-- ❌ BAD: No URL update -->
<button hx-get="/api/foods?filter=verified">Filter</button>
```

---

### Issue 5: Search Not Including Filter State

**Symptoms**: Filters reset when typing in search box

**Checklist**:
1. Are filter chips using `hx-include="[name='q']"`?
2. Is search input using `hx-include` to include filter params?
3. Are form field names correct (`name="q"`, `name="filter"`, etc)?
4. Check Network tab - are all expected params in request URL?

**Fix**:
```html
<!-- Search input includes filter state -->
<input name="q"
       hx-get="/api/foods/search"
       hx-include="[name='filter'], [name='category']"
       hx-trigger="input changed delay:300ms" />

<!-- Filter chip includes search query -->
<button hx-get="/api/foods/search?filter=verified"
        hx-include="[name='q']"
        hx-target="#results">
  Verified
</button>
```

---

### Issue 6: Debouncing Not Working

**Symptoms**: Request fires on every keystroke

**Checklist**:
1. Is `delay:300ms` in `hx-trigger`?
2. Is `changed` modifier present?
3. Check spelling: `delay:300ms` not `delay:300` or `delay=300ms`

**Fix**:
```html
<!-- ✅ GOOD: Debounces with 300ms delay -->
<input hx-trigger="input changed delay:300ms" />

<!-- ❌ BAD: No debouncing -->
<input hx-trigger="input" />

<!-- ❌ BAD: Wrong syntax -->
<input hx-trigger="input delay:300" />
```

---

### Issue 7: Form Fields Not Included

**Symptoms**: Server receives incomplete data

**Checklist**:
1. Are form fields inside a `<form>` element? (auto-included)
2. If outside form, is `hx-include` targeting correct selectors?
3. Do fields have `name` attributes?
4. Are fields enabled (not `disabled`)?

**Fix**:
```html
<!-- ✅ GOOD: Fields auto-included -->
<form hx-post="/api/logs">
  <input name="food_id" />
  <input name="quantity" />
  <button type="submit">Log</button>
</form>

<!-- ✅ GOOD: Manual inclusion -->
<input name="q" id="search" />
<button hx-get="/api/search"
        hx-include="[name='q']">Search</button>

<!-- ❌ BAD: No name attribute -->
<input id="query" />
<button hx-get="/api/search"
        hx-include="#query">Search</button>
```

---

### Issue 8: Accessibility Warnings

**Symptoms**: Screen reader issues, ARIA warnings in DevTools

**Checklist**:
1. Do all inputs have `aria-label` or associated `<label>`?
2. Are buttons using `role="button"` and `aria-pressed`?
3. Are live regions using `aria-live="polite"`?
4. Are loading states using `aria-busy="true"`?
5. Run accessibility audit in DevTools

**Fix**:
```html
<!-- ✅ GOOD: Full accessibility -->
<input type="search"
       name="q"
       aria-label="Search for foods"
       hx-get="/api/search" />

<button role="button"
        aria-pressed="false"
        aria-label="Filter by verified foods"
        hx-get="/api/foods?filter=verified">
  Verified Only
</button>

<div id="results"
     role="region"
     aria-live="polite"
     aria-label="Search results">
  <!-- Results here -->
</div>
```

---

### Issue 9: Server Errors Not Displayed

**Symptoms**: Error occurs but user sees nothing

**Checklist**:
1. Is server returning HTML error fragments (not just status codes)?
2. Is `hx-target` pointing to where error should display?
3. Check Network tab for response body
4. Are error codes (4xx, 5xx) being handled?

**Fix**:
```gleam
// Server returns HTML error fragment
case validate_search_query(query) {
  Error(error_msg) -> {
    let error_html =
      "<div class=\"error-message\" role=\"alert\" aria-live=\"assertive\">"
      <> escape_html(error_msg)
      <> "</div>"
    wisp.html_response(error_html, 400)
  }
  Ok(validated) -> {
    // Process successfully...
  }
}
```

---

## Additional Resources

### Official HTMX Documentation
- [HTMX Main Site](https://htmx.org/)
- [Attributes Reference](https://htmx.org/reference/)
- [Examples](https://htmx.org/examples/)

### Project-Specific Documentation
- [HTMX Filter Verification](../HTMX_FILTER_VERIFICATION.md) - Test results and implementation details
- [Component Signatures](./component_signatures.md) - Gleam component API reference
- [Food Search Usage](./FOOD_SEARCH_USAGE.md) - Food search component examples

### Testing
- [Search Handler Tests](../test/meal_planner/web/handlers/search_test.gleam) - 32 filter tests
- [Food Filter Workflow Tests](../test/meal_planner/web/handlers/food_filter_workflow_test.gleam) - 16 workflow tests

---

## Quick Reference Card

### Most Common Patterns

```html
<!-- Search with debouncing -->
<input name="q"
       hx-get="/api/search"
       hx-trigger="input changed delay:300ms"
       hx-target="#results"
       hx-swap="innerHTML"
       hx-push-url="true" />

<!-- Filter button -->
<button hx-get="/api/filter?type=verified"
        hx-target="#results"
        hx-include="[name='q']"
        hx-push-url="true">Filter</button>

<!-- Dropdown auto-submit -->
<select name="category"
        hx-get="/api/search"
        hx-trigger="change"
        hx-target="#results"
        hx-push-url="true">...</select>

<!-- Form submission -->
<form hx-post="/api/submit"
      hx-target="#confirmation"
      hx-swap="innerHTML">...</form>

<!-- Loading indicator -->
<span id="loading" class="htmx-indicator">Loading...</span>
```

### Remember

1. **No custom JavaScript files** - Use only HTMX attributes
2. **Server returns HTML** - Not JSON
3. **State in URL** - All filter/search state in query parameters
4. **Debounce inputs** - Use `delay:300ms` for search
5. **Include related state** - Use `hx-include` to preserve context
6. **Accessibility first** - Always add ARIA attributes
7. **Test server-side** - All logic validated in Gleam

---

**Last Updated**: 2025-12-04
**Version**: 1.0
**Status**: Production Ready
