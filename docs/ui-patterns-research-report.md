# Modern UI Patterns Research Report - Meal Planner Web Application
**Gleam/Lustre SSR Framework Analysis**

**Research Date**: 2025-12-03  
**Scope**: Medium depth - Actionable findings with code examples  
**Status**: Complete and ready for implementation

---

## EXECUTIVE SUMMARY

The meal-planner application uses a **Gleam/Wisp backend with server-side rendered HTML via Lustre**, creating a pure functional programming approach to web development:

- **Zero JavaScript frameworks** (React, Vue, etc.)
- **Pure Gleam HTML generation** via lustre/element
- **PostgreSQL backend** with USDA FoodData Central (400K+ foods)
- **Responsive CSS** with modern patterns (flexbox, CSS Grid)
- **Form-first interaction** (progressive enhancement)
- **Planned accessibility** (WCAG AA referenced in documentation)

**Key Finding**: This is an *SSR-first approach* where Gleam generates HTML server-side. Forms use traditional POST/GET, not AJAX. This enables **zero JavaScript in critical path** while maintaining full functionality.

---

## 1. EXISTING UI PATTERNS INVENTORY

### 1.1 Lustre Elements Used

**Current patterns found in codebase:**

```gleam
// Layout
html.div([attribute.class("...")], [...])
html.header([attribute.class("page-header")], [...])
html.nav([attribute.class("home-nav")], [...])

// Forms (SSR Pattern)
html.form([
  attribute.method("POST"),
  attribute.action("/api/endpoint"),
  attribute.class("recipe-form"),
], [
  html.div([attribute.class("form-group")], [
    html.label([attribute.attribute("for", "id")], [element.text("Label")]),
    html.input([
      attribute.type_("text"),
      attribute.id("id"),
      attribute.name("name"),
      attribute.value(""),
      attribute.required(True),
    ]),
  ]),
])

// Data Display
html.table([attribute.class("nutrients-table")], [
  html.thead([], [...]),
  html.tbody([], list.map(data, food_row)),
])
```

### 1.2 CSS Architecture

**Single `/static/styles.css` file (~750 lines)**

```css
/* Layout Utilities */
.container { max-width: 1200px; margin: 0 auto; padding: 20px; }
.recipe-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); }

/* Components */
.btn { padding: 0.5rem 1rem; border: none; border-radius: 4px; cursor: pointer; transition: all 0.2s; }
.btn-primary { background: #007bff; color: white; }
.btn:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.1); }

/* Data Visualization */
.progress-bar { height: 10px; background: #e9ecef; border-radius: 5px; overflow: hidden; }
.progress-fill { height: 100%; transition: width 0.3s ease; background: #28a745; }

/* Cards */
.recipe-card { background: white; border: 1px solid #e9ecef; border-radius: 12px; 
               padding: 1.25rem; transition: transform 0.2s, box-shadow 0.2s; }
```

**Color Scheme:**
- Primary: `#007bff` (Blue)
- Success: `#28a745` (Green)
- Danger: `#dc3545` (Red)
- Neutral: `#e9ecef` (Light), `#666` (Medium), `#333` (Dark)

### 1.3 Form Patterns (SSR)

**Key characteristics:**
- Server validation only (no frontend)
- Value preservation for edit forms
- Method override for DELETE/PUT
- Required attributes on critical fields
- No JavaScript event handlers

**Missing patterns:**
- Real-time validation feedback
- Inline error messages
- Success/failure notifications
- Autocomplete search

---

## 2. RECOMMENDED LIBRARIES

### CSS/Styling Decision

| Framework | Recommendation | Why |
|-----------|---|---|
| **Pure CSS** (current) | **Keep** | Full control, zero overhead, SSR-perfect |
| **CSS Variables** | **Add** | Design tokens, consistency |
| **HTMX** | **Consider** | 14KB, autocomplete without page reloads |
| **Tailwind** | Skip | Framework overhead unnecessary |
| **Bootstrap** | Skip | Heavy, requires JS |

**Decision**: Keep pure CSS + adopt CSS variables + consider HTMX for autocomplete

### Autocomplete Search Solution

**Option A: HTMX (Recommended for future)**
```gleam
// Returns partial HTML
fn api_foods_autocomplete(req: Request, ctx: Context) -> Response {
  let query = uri.parse_query(req.query) |> get_param("q")
  let foods = search_foods(ctx, query, 10)
  let html = html.div([attribute.class("autocomplete-results")],
    list.map(foods, food_row))
  wisp.html_response(element.to_string(html), 200)
}
```

HTML:
```html
<input type="search" 
       hx-get="/api/foods/autocomplete"
       hx-trigger="keyup changed delay:300ms"
       hx-target="#results"
       placeholder="Search foods...">
<div id="results"></div>
```

**Option C: Current (Form-based)**
- User types and presses Enter
- Full page reload with results
- Perfectly acceptable for now

### Nutrition Visualization

**Current**: Pure CSS progress bars  
**Recommended**: SVG + CSS for advanced visualizations

**Example - Calorie Ring**:
```gleam
fn calorie_ring(current: Float, target: Float) -> element.Element(msg) {
  let pct = current /. target *. 100.0
  let circumference = 2.0 *. 3.14159 *. 45.0
  let offset = circumference *. (1.0 -. pct /. 100.0)
  
  html.svg([attribute.width("120"), attribute.height("120")], [
    html.circle([
      attribute.cx("60"), attribute.cy("60"), attribute.r("45"),
      attribute.fill("none"), attribute.stroke("#e9ecef"),
      attribute.attribute("stroke-width", "8"),
    ]),
    html.circle([
      attribute.cx("60"), attribute.cy("60"), attribute.r("45"),
      attribute.fill("none"), attribute.stroke("#007bff"),
      attribute.attribute("stroke-width", "8"),
      attribute.attribute("stroke-dasharray", float_to_string(circumference)),
      attribute.attribute("stroke-dashoffset", float_to_string(offset)),
      attribute.style("transition", "stroke-dashoffset 0.5s ease"),
    ]),
  ])
}
```

---

## 3. BEST PRACTICES FOR GLEAM/LUSTRE UI

### DO's

1. **Use helper functions** for reusable patterns
2. **Compose** from smaller elements
3. **Use CSS classes**, not inline styles
4. **Preserve form state** in edit flows
5. **Use semantic HTML** (main, nav, article, etc.)

### DON'Ts

1. **Avoid inline styles** - breaks responsive design
2. **Don't hardcode colors** - use CSS variables
3. **Don't repeat patterns** - create components
4. **Don't validate frontend-only** - validate server
5. **Don't skip semantic markup**

### Performance Tips

1. Use `list.map()` for dynamic content
2. Keep components under 100 lines
3. Cache computed values (calories, macros)
4. Use CSS transitions, not JavaScript
5. Lazy-load images with `loading="lazy"`

---

## 4. ACCESSIBILITY IMPLEMENTATION (WCAG AA)

**Currently planned but NOT implemented**

### Add to Gleam Code

```gleam
// Skip link
fn skip_link() -> element.Element(msg) {
  html.a([
    attribute.href("#main-content"),
    attribute.class("skip-link"),
    attribute.attribute("aria-label", "Skip to main content"),
  ], [element.text("Skip to main content")])
}

// Accessible form field
fn accessible_form_field(label: String, name: String, error: Option(String)) 
    -> element.Element(msg) {
  html.div([attribute.class("form-group")], [
    html.label([attribute.attribute("for", name)], [element.text(label)]),
    html.input([
      attribute.type_("text"),
      attribute.id(name),
      attribute.name(name),
      attribute.attribute("aria-describedby", case error {
        Some(_) -> name <> "-error"
        None -> ""
      }),
    ]),
    case error {
      Some(err) ->
        html.span([
          attribute.id(name <> "-error"),
          attribute.class("error-text"),
          attribute.attribute("role", "alert"),
        ], [element.text(err)])
      None -> html.text("")
    },
  ])
}

// Progress bar with ARIA
fn accessible_progress_bar(label: String, current: Float, target: Float) 
    -> element.Element(msg) {
  let pct = float.min(current /. target *. 100.0, 100.0)
  html.div([], [
    html.label([], [element.text(label)]),
    html.div([
      attribute.role("progressbar"),
      attribute.attribute("aria-valuenow", float.to_string(current)),
      attribute.attribute("aria-valuemax", float.to_string(target)),
      attribute.class("progress-bar"),
    ], [
      html.div([
        attribute.class("progress-fill"),
        attribute.style("width", float.to_string(pct) <> "%"),
      ], []),
    ]),
  ])
}
```

### Add to CSS

```css
/* Focus indicators */
:focus-visible {
  outline: 2px solid #007bff;
  outline-offset: 2px;
}

/* Skip link */
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: #007bff;
  color: white;
  padding: 8px;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
  * {
    animation: none !important;
    transition: none !important;
  }
}

/* High contrast mode */
@media (prefers-contrast: more) {
  :root {
    --color-text-primary: #000;
    --color-primary: #0000ff;
  }
}
```

---

## 5. RESPONSIVE DESIGN PATTERNS

**Current breakpoints:**
- Mobile: `@media (max-width: 768px)`
- Desktop: Default (1200px container)

**Enhanced strategy:**

```css
/* Mobile-first (320px+) */
.recipe-grid { grid-template-columns: 1fr; }

/* Tablet (640px+) */
@media (min-width: 640px) {
  .recipe-grid { grid-template-columns: repeat(2, 1fr); }
}

/* Desktop (1024px+) */
@media (min-width: 1024px) {
  .container { max-width: 1200px; margin: 0 auto; }
  .recipe-grid { grid-template-columns: repeat(3, 1fr); }
}

/* Large screens (1280px+) */
@media (min-width: 1280px) {
  .recipe-grid { grid-template-columns: repeat(4, 1fr); }
}

/* Touch device optimization */
@media (hover: none) and (pointer: coarse) {
  .btn { min-height: 44px; min-width: 44px; }
}
```

---

## 6. TOP 3 IMMEDIATE IMPROVEMENTS

### 1. Add CSS Variables (Easy, High Impact)

```css
:root {
  /* Colors */
  --color-primary: #007bff;
  --color-success: #28a745;
  --color-danger: #dc3545;
  --color-text: #333;
  --color-bg: #ffffff;
  --color-border: #e9ecef;
  
  /* Spacing */
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 1.5rem;
  
  /* Typography */
  --font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --font-size-base: 1rem;
  
  /* Shadows */
  --shadow-md: 0 4px 12px rgba(0, 0, 0, 0.1);
  
  /* Transitions */
  --transition: 0.3s ease;
}

/* Usage */
.btn { background: var(--color-primary); }
.card { box-shadow: var(--shadow-md); }
```

### 2. Create Form Field Component (Medium, Reduces Boilerplate)

```gleam
pub type FormFieldProps {
  FormFieldProps(
    label: String,
    name: String,
    type_: String,
    value: String,
    placeholder: String,
    required: Bool,
    error: Option(String),
  )
}

fn form_field(props: FormFieldProps) -> element.Element(msg) {
  html.div([attribute.class("form-group")], [
    html.label([attribute.attribute("for", props.name)], 
      [element.text(props.label)]),
    html.input([
      attribute.type_(props.type_),
      attribute.id(props.name),
      attribute.name(props.name),
      attribute.value(props.value),
      attribute.placeholder(props.placeholder),
      attribute.required(props.required),
    ]),
    case props.error {
      Some(err) -> html.span([attribute.class("error")], [element.text(err)])
      None -> html.text("")
    },
  ])
}

// Usage:
form_field(FormFieldProps(
  label: "Protein (g)",
  name: "protein",
  type_: "number",
  value: "35",
  placeholder: "0.0",
  required: True,
  error: None,
))
```

### 3. Add ARIA Labels to Forms (Medium, Accessibility)

Update form patterns to include:

```gleam
html.input([
  attribute.type_("text"),
  attribute.id("recipe-name"),
  attribute.name("name"),
  attribute.attribute("aria-label", "Recipe name"),
  attribute.attribute("aria-describedby", case error {
    Some(_) -> "name-error"
    None -> ""
  }),
  attribute.required(True),
])
```

---

## 7. IMPLEMENTATION ROADMAP

### Phase 1: Foundation (Current)
- ✓ Pure CSS styling system
- ✓ Basic Lustre components
- ✓ Server-side form rendering
- ✓ Responsive grid layouts

### Phase 2: Enhancement (Recommended Next)
- [ ] Add CSS variables for consistency
- [ ] Implement accessibility (ARIA labels, skip links, focus indicators)
- [ ] Create reusable form field component
- [ ] Add HTMX for live search (optional)

### Phase 3: Advanced (Optional)
- [ ] Lustre server components for real-time dashboard
- [ ] Chart visualization for nutrition trends
- [ ] Custom food management UI
- [ ] Offline support (Service Workers)

### Phase 4: Polish
- [ ] Dark mode support
- [ ] Performance optimization
- [ ] Full a11y audit and fixes
- [ ] Analytics/monitoring

---

## 8. KEY FILES & LOCATIONS

| File | Purpose |
|------|---------|
| `/server/src/server/web.gleam` | SSR page rendering, form components |
| `/server/priv/static/styles.css` | All styling (750 lines) |
| `/docs/ui-mockups.md` | Complete wireframes with CSS specs |
| `/docs/lustre-research.md` | Framework architecture guide |

---

## 9. SUMMARY

### Strengths
1. Pure server-side rendering - works everywhere, SEO-friendly
2. No JavaScript required - fast, secure, accessible
3. Type-safe HTML - Gleam catches errors at compile time
4. PostgreSQL integration - powerful nutrition data querying
5. Mobile-first CSS - already responsive

### Next Steps
1. **Immediate**: Add CSS variables + ARIA labels
2. **Soon**: Create form field component + HTMX for autocomplete
3. **Future**: Consider Lustre server components for real-time dashboard

### Libraries Decision
- **Keep**: Pure CSS architecture
- **Add**: CSS variables + HTMX (optional)
- **Skip**: Tailwind, Bootstrap, Material, React

---

**Report Status**: Ready for implementation  
**Findings Depth**: Medium (actionable with code examples)  
**Code Examples**: ✓ Recipe forms, ✓ Cards, ✓ Accessibility patterns, ✓ SVG visualization
