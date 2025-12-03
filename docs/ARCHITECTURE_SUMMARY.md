# UI Architecture Design - Executive Summary

**Status**: Complete
**Date**: 2025-12-03
**Audience**: Developers, Architects

---

## What Was Delivered

Three comprehensive architecture documents defining the modern UI redesign for the Meal Planner application:

### 1. Main Architecture Document (650+ lines)
**File**: `/home/lewis/src/meal-planner/docs/ui_architecture.md`

Complete system design covering:
- System architecture diagram (ASCII art)
- Component hierarchy (3 levels)
- File organization structure
- CSS design system (tokens, organization strategy)
- Gleam/Lustre component signatures with examples
- Data flow and integration patterns
- Implementation roadmap for three beads
- 6 Architecture Decision Records (ADRs)
- Testing strategy and accessibility guidelines
- Performance targets and monitoring

### 2. Component Signatures Reference
**File**: `/home/lewis/src/meal-planner/docs/component_signatures.md`

Precise Gleam type signatures for:
- Atomic components (buttons, cards, forms, progress, typography, layout)
- Page components (home, food search, dashboard, profile, recipes)
- Type definitions for component data
- Composition patterns and examples
- Function signatures ready for implementation

### 3. CSS Design Tokens Reference
**File**: `/home/lewis/src/meal-planner/docs/css_design_tokens.md`

Complete CSS system definition:
- Color palette with semantic usage
- Typography scale (modular 1.125)
- Spacing system (8px base unit)
- Border radius, shadows, transitions
- Breakpoints (mobile-first)
- CSS architecture structure
- Utility classes (display, flexbox, spacing, typography)
- Component styles (buttons, cards, forms, progress)
- Layout components and responsive overrides

---

## Architecture Overview

### Design Philosophy

```
Type Safety + SSR + Modular CSS = Maintainable UI
```

**Key Principles**:
1. Type Safety First - Gleam's type system catches errors at compile time
2. SSR-Native - Server-side rendering with progressive enhancement
3. Modular CSS - Custom properties + utilities + semantic components
4. Composable Elements - Small, reusable functions with single responsibility
5. No Runtime Complexity - Pure functional components, no client-side state
6. Accessibility First - WCAG 2.1 AA compliance built-in

### Technology Stack

- **Framework**: Gleam 1.0+ with Lustre 5.0+
- **Web Server**: Wisp + Mist
- **Styling**: Plain CSS (no preprocessor needed)
- **Database**: PostgreSQL (existing)
- **Type Safety**: Full Gleam static typing

---

## Three Beads Implementation Plan

### Bead 1: CSS Design System (Foundation)
**Duration**: 3-4 days | **Priority**: Highest

What gets built:
- Design tokens (colors, typography, spacing, shadows)
- Utility classes (display, flexbox, text, colors, borders)
- Base component styles (buttons, cards, forms, progress)
- Responsive breakpoints (mobile-first approach)

Files created:
```
priv/static/
├── theme.css      (Design tokens - NEW)
├── utilities.css  (Utility classes - NEW)
├── components.css (Component styles - NEW)
├── responsive.css (Media queries - NEW)
└── styles.css     (Main entry point - UPDATE)
```

This bead must be completed first as it's the foundation for all other work.

### Bead 2: Food Search Component
**Duration**: 3-4 days | **Priority**: High | **Depends on**: Bead 1

What gets built:
- Search input component with integrated button
- Search results list with food items
- Food detail view showing complete nutrition info
- Type-safe data structures (SearchState, FoodCardData)
- Server-side PostgreSQL FTS integration

Files created:
```
gleam/src/meal_planner/ui/
├── components/forms.gleam         (UPDATE - add search_input)
├── pages/food_search.gleam        (NEW)
└── pages/food_detail.gleam        (NEW)

gleam/src/meal_planner/
└── web.gleam                      (UPDATE - add routes)
```

### Bead 3: Nutrition Dashboard
**Duration**: 3-4 days | **Priority**: High | **Depends on**: Bead 1 (+ partial Bead 2)

What gets built:
- Dashboard layout with date navigation (prev/next day)
- Calorie summary card showing current vs. targets
- Macro progress bars (protein, fat, carbs)
- Daily log entries list showing all logged meals
- Integration with existing DailyLog data structure

Files created:
```
gleam/src/meal_planner/ui/
├── components/progress.gleam      (UPDATE - add macro visualization)
├── pages/dashboard.gleam          (NEW)
└── pages/home.gleam               (NEW)

gleam/src/meal_planner/
└── web.gleam                      (UPDATE - refactor handlers)
```

---

## Component Architecture

### Three-Level Hierarchy

```
Level 3: Atomic Components
├── Buttons (primary, secondary, danger, sizes)
├── Cards (basic, stat, recipe, food)
├── Forms (input, search, select, validation)
├── Progress (bars, badges, indicators)
├── Typography (h1-h6, body, labels)
└── Layout (flex, grid, container, section)

Level 2: Feature Components
├── Food Search (search form + results)
├── Dashboard (calorie summary + macro bars + log)
└── Recipe Management (cards, detail, forms)

Level 1: Page Components
├── Home Page
├── Dashboard
├── Food Search
├── Food Detail
└── Profile
```

### Component Pattern

All components are pure functions returning Lustre elements:

```gleam
pub fn button(
  label: String,
  href: String,
  variant: ButtonVariant,
) -> element.Element(msg) {
  html.a([
    attribute.href(href),
    attribute.class("btn " <> variant_to_class(variant))
  ], [element.text(label)])
}
```

No state, no callbacks, no runtime complexity. Perfect for SSR.

---

## CSS Design System

### Design Tokens (CSS Custom Properties)

All styling uses custom properties for consistency:

```css
:root {
  /* Colors */
  --color-primary: #007bff;
  --color-success: #28a745;
  --color-protein: #28a745;
  --color-fat: #ffc107;
  --color-carbs: #17a2b8;
  
  /* Typography */
  --font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto;
  --text-lg: 1.125rem;
  --font-bold: 700;
  
  /* Spacing (8px base) */
  --space-4: 1rem;
  --space-6: 1.5rem;
  
  /* Responsive */
  @media (min-width: 1024px) { /* desktop */ }
}
```

### CSS Organization

```
1. Design Tokens (custom properties)
2. Utility Classes (reusable atomic styles)
3. Component Styles (buttons, cards, forms)
4. Layout Components (grid, flex, container)
5. Responsive Overrides (mobile-first breakpoints)
```

### Key CSS Classes

```css
/* Buttons */
.btn .btn-primary .btn-secondary .btn-danger

/* Cards */
.card .card-header .card-body .card-footer

/* Forms */
.input .input-search .form-group

/* Progress */
.progress-bar .progress-fill .macro-bar .macro-badge

/* Utilities */
.flex .flex-col .gap-4 .p-4 .text-lg .font-bold
```

---

## Data Flow & Integration

### Server-Side Rendering Pattern

```
Request → Extract Query Params → Load Data from DB
    ↓
Create Type-Safe Data Structure → Render Component
    ↓
Convert Element to HTML → Wrap in Page Template
    ↓
Response: Full HTML page
```

### Example: Food Search

```gleam
fn foods_page(req: wisp.Request, ctx: Context) -> wisp.Response {
  let query = extract_search_query(req)
  let foods = search_foods(ctx, query)
  let state = SearchState(query: query, results: foods)
  let content = [render_food_search_page(state)]
  wisp.html_response(render_page("Food Search", content), 200)
}
```

No client-side state management needed. Just pass data to components!

---

## Key Design Decisions

### ADR-1: SSR Over SPA
**Decision**: Use Gleam/Lustre SSR, not client-side SPA
**Why**: Type safety, performance, accessibility, SEO-friendly

### ADR-2: Hybrid CSS
**Decision**: Utility classes + semantic components (not pure utilities, not pure semantic)
**Why**: Flexibility + consistency + maintainability

### ADR-3: CSS Custom Properties
**Decision**: All design tokens as CSS variables (no build tools)
**Why**: Native browser support, no build complexity, runtime flexibility

### ADR-4: Pure Lustre Functions
**Decision**: Components are pure functions returning elements
**Why**: Type safety, SSR-friendly, no state management complexity

### ADR-5: Mobile-First
**Decision**: Build for mobile first, enhance for desktop
**Why**: Mobile-centric traffic, progressive enhancement

### ADR-6: Type-Safe Data
**Decision**: Every component has a well-defined Gleam type
**Why**: Compile-time safety, self-documenting, refactoring support

---

## Performance Targets

- **Dashboard Load**: < 200ms
- **Food Search**: < 100ms (database FTS)
- **CSS Size**: < 30KB gzipped
- **Initial Page Load**: < 300ms

Achieved through:
- Server-side rendering (no JS to parse/execute)
- Efficient PostgreSQL queries with full-text search
- Optimized CSS with design tokens
- Streaming HTML responses

---

## Accessibility (WCAG 2.1 AA)

Built-in accessibility features:
- Color contrast: 4.5:1 for normal text, 3:1 for large text
- Keyboard navigation: All interactive elements accessible via Tab/Enter
- Focus indicators: Visible focus rings on all buttons/links
- Semantic HTML: Proper heading hierarchy, label associations
- Form validation: Clear error messages associated with fields
- ARIA attributes: Only where needed (semantic HTML preferred)

---

## File Locations

**Architecture Documentation**:
```
/home/lewis/src/meal-planner/docs/
├── ui_architecture.md            (650+ lines, main document)
├── component_signatures.md       (API reference)
└── css_design_tokens.md          (CSS system reference)
```

**Implementation Locations**:
```
gleam/src/meal_planner/ui/
├── components/                   (atomic components)
│   ├── buttons.gleam
│   ├── cards.gleam
│   ├── forms.gleam
│   ├── progress.gleam
│   ├── typography.gleam
│   └── layout.gleam
├── pages/                        (feature components)
│   ├── home.gleam
│   ├── food_search.gleam         (BEAD 2)
│   ├── food_detail.gleam         (BEAD 2)
│   ├── dashboard.gleam           (BEAD 3)
│   ├── profile.gleam
│   └── layout.gleam
└── styles/
    ├── design_system.gleam       (token helpers)
    └── constants.gleam

priv/static/
├── theme.css                     (BEAD 1)
├── utilities.css                 (BEAD 1)
├── components.css                (BEAD 1)
├── responsive.css                (BEAD 1)
└── styles.css                    (main import)
```

---

## Next Steps

### Immediate (This Sprint)
1. Review architecture with development team
2. Identify any gaps or concerns
3. Get approval for SSR + hybrid CSS approach

### Bead 1: CSS Foundation (Week 1-2)
1. Create `priv/static/theme.css` with all design tokens
2. Create `priv/static/utilities.css` with utility classes
3. Create `priv/static/components.css` with base components
4. Create `priv/static/responsive.css` with breakpoints
5. Test CSS across devices (320px, 768px, 1024px)
6. Verify performance (< 30KB gzipped)

### Bead 2: Food Search (Week 2-3)
1. Implement `ui/components/forms.gleam` (search_input function)
2. Implement `ui/pages/food_search.gleam` (page component)
3. Implement `ui/pages/food_detail.gleam` (detail page)
4. Update `web.gleam` with new route handlers
5. Integration testing with database
6. Performance testing (< 100ms searches)

### Bead 3: Dashboard (Week 3-4)
1. Implement `ui/components/progress.gleam` enhancements
2. Implement `ui/pages/dashboard.gleam` (main dashboard)
3. Update `web.gleam` dashboard handler
4. Integration with DailyLog structure
5. Date navigation functionality
6. Performance testing (< 200ms loads)

---

## Success Criteria

### Architecture Level
- [x] Clear component hierarchy documented
- [x] Type signatures defined for all components
- [x] CSS design system fully specified
- [x] Integration points identified
- [x] Data flow documented with examples

### Implementation Level (after beads complete)
- [ ] CSS system passes WCAG 2.1 AA contrast audit
- [ ] All components responsive (tested 320px-1280px)
- [ ] Food search returns results < 100ms
- [ ] Dashboard loads < 200ms
- [ ] CSS payload < 30KB gzipped
- [ ] 100% keyboard accessible
- [ ] Zero runtime JavaScript errors

---

## References

**Main Documents**:
1. `/home/lewis/src/meal-planner/docs/ui_architecture.md` - Complete architecture
2. `/home/lewis/src/meal-planner/docs/component_signatures.md` - Component APIs
3. `/home/lewis/src/meal-planner/docs/css_design_tokens.md` - CSS reference

**Code References**:
- `gleam/src/meal_planner/web.gleam` - Existing page handlers (integration point)
- `gleam/src/meal_planner/storage.gleam` - Data layer (search_foods, load_daily_log)
- `gleam/priv/static/styles.css` - Existing CSS (to be refactored)

**Standards**:
- WCAG 2.1 Level AA (accessibility)
- Mobile-first responsive design
- Gleam 1.0+ type system
- Lustre 5.0+ SSR rendering

---

## Contact & Questions

This architecture is ready for review and implementation. All three beads are sequenced with clear dependencies:

1. **Bead 1** (CSS) must complete first
2. **Bead 2** (Food Search) depends on Bead 1
3. **Bead 3** (Dashboard) depends on Bead 1, optional partial Bead 2

Each bead includes specific file locations, function signatures, and success criteria for implementation.

---

**Document Generated**: 2025-12-03
**Architecture Status**: Complete and Ready for Implementation
**Total Documentation**: 3 documents, 1200+ lines of specification
