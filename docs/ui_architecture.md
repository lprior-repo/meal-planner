# UI Component Architecture - Meal Planner Redesign

**Document Version**: 1.0
**Date**: 2025-12-03
**Status**: Architecture Design Phase
**Target Implementation**: Three Beads (CSS Design System, Food Search, Nutrition Dashboard)

---

## Executive Summary

This document defines the component architecture for modernizing the Meal Planner UI. The design leverages Gleam/Lustre Server-Side Rendering (SSR) with a modular CSS system and composable element components. The architecture enables rapid iteration while maintaining type safety and consistent styling across three priority beads.

### Key Principles

- **Type Safety First**: Leverage Gleam's type system for component composition
- **SSR-Native Design**: Optimize for server-side rendering with progressive enhancement
- **Modular CSS Architecture**: Custom properties + utility classes + component styles
- **Composable Elements**: Small, reusable Lustre components with single responsibility
- **Data-Driven Styling**: Component styles derived from shared type definitions
- **No Runtime Complexity**: Pure functional components without client-side state management

---

## 1. Architectural Overview

### System Context

```
┌─────────────────────────────────────────────────────────────┐
│                    Meal Planner SSR App                     │
│                    (Gleam/Lustre/Wisp)                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Page Layer (SSR Pages)                  │   │
│  │  - home_page()                                       │   │
│  │  - dashboard_page()                                  │   │
│  │  - foods_page()                                      │   │
│  │  - recipe_detail_page()                              │   │
│  └──────────────────────────────────────────────────────┘   │
│           │                    │                    │        │
│           v                    v                    v        │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────┐  │
│  │  Component      │  │  Component       │  │ Component │  │
│  │  Composition    │  │  Composition     │  │ Utilities │  │
│  │  Layer          │  │  Layer           │  │ Layer     │  │
│  └──────────────────┘  └──────────────────┘  └───────────┘  │
│           │                    │                    │        │
│           └────────────────────┴────────────────────┘        │
│                         │                                    │
│                         v                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │        CSS Design System & Styling Layer            │   │
│  │  - Custom Properties (Design Tokens)                │   │
│  │  - Utility Classes (Spacing, Typography)            │   │
│  │  - Component Styles (Cards, Buttons, Forms)         │   │
│  │  - Layout System (Grid, Flexbox)                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Data Layer (Storage & DB)              │   │
│  │  - PostgreSQL with USDA FoodData Central            │   │
│  │  - Recipe Storage                                   │   │
│  │  - Food Logs                                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Component Hierarchy

### Level 1: Layout Components (Page Structure)

```
App Container
├── Header (Navigation)
├── Main Content Area
│   ├── Page Header
│   └── Page Content
└── Footer (Optional)
```

### Level 2: Feature Components (Business Logic)

```
Feature Areas
├── Food Search Component
│   ├── Search Input
│   ├── Results List
│   └── Food Detail View
├── Nutrition Dashboard
│   ├── Date Selector
│   ├── Calorie Summary
│   ├── Macro Progress Bars
│   └── Daily Log Entries
└── Recipe Management
    ├── Recipe Cards
    ├── Recipe Detail
    └── Recipe Form
```

### Level 3: Atomic Components (Reusable Elements)

```
Atomic Units
├── Button Variants
│   ├── Primary Button
│   ├── Secondary Button
│   └── Danger Button
├── Cards
│   ├── Basic Card
│   ├── Stat Card
│   └── Recipe Card
├── Form Elements
│   ├── Input Field
│   ├── Search Input
│   └── Select Dropdown
├── Progress Indicators
│   ├── Progress Bar
│   ├── Macro Badge
│   └── Status Indicator
├── Typography
│   ├── Heading Levels (h1-h6)
│   ├── Body Text
│   └── Labels
└── Layout
    ├── Grid
    ├── Flex Container
    └── Spacing Utilities
```

### Complete Visual Hierarchy

```
┌────────────────────────────────────────────────────────────┐
│ <html> Document Root                                       │
├────────────────────────────────────────────────────────────┤
│ <head>                                                     │
│   - Metadata, Links to CSS                                │
│ <body>                                                     │
│   <div class="container">                                 │
│     ┌──────────────────────────────────────────────────┐ │
│     │ Page Layer (SSR-rendered)                        │ │
│     │ e.g., render_page("Dashboard", content)         │ │
│     └──────────────────────────────────────────────────┘ │
│       │                                                   │
│       ├─ <div class="page-header">                       │
│       │   ├─ <h1>Dashboard</h1>                          │
│       │   └─ <p class="subtitle">...</p>                 │
│       │                                                   │
│       ├─ <div class="dashboard">                         │
│       │   ├─ <div class="calorie-summary">              │
│       │   │   └─ macro_stat_block() components         │
│       │   │                                              │
│       │   ├─ <div class="macro-bars">                   │
│       │   │   └─ macro_bar() components                │
│       │   │                                              │
│       │   └─ <div class="quick-actions">                │
│       │       └─ <button> / <a class="btn">             │
│       │                                                   │
│       └─ Styled by styles.css                           │
│          - Design tokens (CSS variables)                 │
│          - Utility classes                              │
│          - Component-specific styles                    │
│                                                          │
└────────────────────────────────────────────────────────────┘
```

---

## 3. File Organization for UI Components

### Proposed Directory Structure

```
gleam/src/meal_planner/
├── ui/                              # NEW: UI Components Directory
│   ├── components/
│   │   ├── buttons.gleam           # Button variants
│   │   ├── cards.gleam             # Card components
│   │   ├── forms.gleam             # Form elements
│   │   ├── progress.gleam          # Progress bars, badges
│   │   ├── typography.gleam        # Text components
│   │   ├── layout.gleam            # Layout containers
│   │   └── shared.gleam            # Shared utilities
│   │
│   ├── pages/
│   │   ├── home.gleam              # Home page components
│   │   ├── dashboard.gleam         # Dashboard components
│   │   ├── food_search.gleam       # Food search component (BEAD 2)
│   │   ├── recipe_detail.gleam     # Recipe detail page
│   │   ├── profile.gleam           # Profile page
│   │   └── layout.gleam            # Page layout wrapper
│   │
│   ├── styles/
│   │   ├── design_system.gleam     # Design tokens & CSS generation (BEAD 1)
│   │   ├── constants.gleam         # CSS constant definitions
│   │   └── theme.gleam             # Theme configuration
│   │
│   └── hooks/
│       └── data_fetchers.gleam     # Server-side data loading helpers
│
├── web.gleam                        # Updated: Page routing & handlers
├── storage.gleam                    # Existing: Database layer
├── types.gleam                      # Existing: Type definitions
└── ... (other modules)

priv/static/
├── styles.css                       # NEW: Redesigned CSS system
├── components.css                   # NEW: Component-specific styles
├── utilities.css                    # NEW: Utility classes
├── theme.css                        # NEW: Design tokens & variables
└── responsive.css                   # NEW: Mobile/tablet breakpoints
```

---

## 4. CSS Architecture & Design System (BEAD 1)

### Design Token System

#### Color Palette

```css
:root {
  /* Primary Colors */
  --color-primary: #007bff;
  --color-primary-dark: #0056b3;
  --color-primary-light: #cfe2ff;

  /* Status Colors */
  --color-success: #28a745;
  --color-warning: #ffc107;
  --color-danger: #dc3545;
  --color-info: #17a2b8;

  /* Neutral Colors */
  --color-text: #333333;
  --color-text-secondary: #666666;
  --color-text-muted: #999999;
  --color-bg: #ffffff;
  --color-bg-secondary: #f5f5f5;
  --color-border: #e9ecef;

  /* Semantic Macros */
  --color-protein: #28a745;
  --color-fat: #ffc107;
  --color-carbs: #17a2b8;
}
```

#### Typography Scale

```css
:root {
  /* Font Family */
  --font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --font-mono: 'Courier New', monospace;

  /* Font Sizes (modular scale 1.125) */
  --text-xs: 0.75rem;    /* 12px */
  --text-sm: 0.875rem;   /* 14px */
  --text-base: 1rem;     /* 16px */
  --text-lg: 1.125rem;   /* 18px */
  --text-xl: 1.25rem;    /* 20px */
  --text-2xl: 1.5rem;    /* 24px */
  --text-3xl: 1.875rem;  /* 30px */
  --text-4xl: 2.25rem;   /* 36px */
  --text-5xl: 2.5rem;    /* 40px */

  /* Font Weights */
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;

  /* Line Heights */
  --line-tight: 1.2;
  --line-normal: 1.5;
  --line-relaxed: 1.75;
}
```

#### Spacing Scale

```css
:root {
  /* 8px base unit */
  --space-0: 0;
  --space-1: 0.25rem;    /* 4px */
  --space-2: 0.5rem;     /* 8px */
  --space-3: 0.75rem;    /* 12px */
  --space-4: 1rem;       /* 16px */
  --space-5: 1.25rem;    /* 20px */
  --space-6: 1.5rem;     /* 24px */
  --space-8: 2rem;       /* 32px */
  --space-10: 2.5rem;    /* 40px */
  --space-12: 3rem;      /* 48px */
  --space-16: 4rem;      /* 64px */
}
```

#### Border & Shadows

```css
:root {
  /* Border Radius */
  --radius-none: 0;
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
  --shadow-xl: 0 20px 25px rgba(0, 0, 0, 0.15);
}
```

#### Breakpoints (Mobile-First)

```css
/* Mobile: < 640px (default) */
/* Tablet: >= 640px (sm) */
@media (min-width: 640px) { }
/* Desktop: >= 1024px (lg) */
@media (min-width: 1024px) { }
/* Large Desktop: >= 1280px (xl) */
@media (min-width: 1280px) { }
```

### CSS Organization Strategy

```
styles.css (Main entry point)
├── 1. CSS Reset & Defaults
├── 2. Design Tokens (Custom Properties)
├── 3. Utility Classes
│   ├── Margin & Padding (m-1, mt-2, p-4, etc.)
│   ├── Display & Flex (flex, flex-col, gap-4)
│   ├── Typography (text-sm, font-bold, text-center)
│   ├── Colors (text-primary, bg-secondary)
│   └── Sizing (w-full, h-screen)
│
├── 4. Base Components (Atomic)
│   ├── Buttons (.btn, .btn-primary, .btn-danger)
│   ├── Cards (.card, .card-stat, .card-recipe)
│   ├── Forms (.input, .form-group, .search-box)
│   ├── Progress (.progress-bar, .macro-bar)
│   └── Typography (h1-h6, p, span, label)
│
├── 5. Compound Components (Feature Level)
│   ├── Macro Bars (.macro-bars, .macro-bar)
│   ├── Calorie Summary (.calorie-summary)
│   ├── Recipe Cards (.recipe-card, .recipe-grid)
│   ├── Food List (.food-list, .food-item)
│   └── Dashboard Layout (.dashboard)
│
├── 6. Page Layouts
│   ├── Home Page (.hero, .home-nav)
│   ├── Dashboard Page (.dashboard, .page-header)
│   ├── Food Search Page (.food-search)
│   ├── Recipe Detail (.recipe-detail)
│   └── Profile Page (.profile)
│
└── 7. Responsive Overrides & Mobile Optimizations
```

### CSS Class Naming Convention

```gleam
// Pattern: [component]-[variant]-[state]

// Buttons
.btn              // Base button
.btn-primary      // Primary variant
.btn-secondary    // Secondary variant
.btn-danger       // Danger variant
.btn:hover        // State
.btn:disabled     // State

// Cards
.card             // Base card
.card-stat        // Stat card variant
.card-recipe      // Recipe card variant
.card-food        // Food search result card

// Forms
.form-group       // Form group container
.input            // Base input
.input-search     // Search input variant
.label            // Form label

// Macro/Progress
.macro-badge      // Inline macro label
.macro-stat       // Stat block (protein, fat, carbs)
.progress-bar     // Progress bar container
.progress-fill    // Actual progress

// Utility naming (Tailwind-like)
.flex             // display: flex
.flex-col         // flex-direction: column
.gap-4            // gap: var(--space-4)
.p-4              // padding: var(--space-4)
.m-2              // margin: var(--space-2)
.text-lg          // font-size: var(--text-lg)
.font-bold        // font-weight: var(--font-bold)
.bg-primary       // background: var(--color-primary)
.text-primary     // color: var(--color-primary)
```

---

## 5. Component Signatures (Gleam/Lustre)

### Atomic Components

```gleam
// buttons.gleam - Button Component Module

/// Button type for variant selection
pub type ButtonVariant {
  Primary
  Secondary
  Danger
  Success
}

/// Button size options
pub type ButtonSize {
  Small
  Medium
  Large
}

/// Main button component
/// Signature: fn(label: String, href: String, variant: ButtonVariant) -> Element
pub fn button(
  label: String,
  href: String,
  variant: ButtonVariant,
) -> element.Element(msg)

/// Button implementation pattern
pub fn button(label, href, variant) {
  let classes = button_classes(variant)
  html.a([attribute.href(href), attribute.class(classes)], [
    element.text(label),
  ])
}

/// Helper: Build button CSS classes
fn button_classes(variant: ButtonVariant) -> String {
  "btn " <> case variant {
    Primary -> "btn-primary"
    Secondary -> "btn-secondary"
    Danger -> "btn-danger"
    Success -> "btn-success"
  }
}
```

```gleam
// cards.gleam - Card Component Module

/// Card type for different card variants
pub type CardVariant {
  Basic
  Stat
  Recipe
  Food
}

/// Stat card data structure
pub type StatCard {
  StatCard(
    label: String,
    value: String,
    unit: String,
    trend: option.Option(Float),
  )
}

/// Render a stat card
pub fn stat_card(stat: StatCard) -> element.Element(msg) {
  html.div([attribute.class("card card-stat")], [
    html.span([attribute.class("stat-value")], [
      element.text(stat.value),
    ]),
    html.span([attribute.class("stat-unit")], [
      element.text(stat.unit),
    ]),
    html.span([attribute.class("stat-label")], [
      element.text(stat.label),
    ]),
  ])
}

/// Render a recipe card
pub fn recipe_card(recipe: Recipe) -> element.Element(msg) {
  let calories = macros_calories(recipe.macros)
  html.a([
    attribute.class("card card-recipe"),
    attribute.href("/recipes/" <> recipe.id),
  ], [
    html.h3([attribute.class("recipe-title")], [
      element.text(recipe.name),
    ]),
    html.span([attribute.class("recipe-category")], [
      element.text(recipe.category),
    ]),
    macro_badges(recipe.macros),
    html.div([attribute.class("recipe-calories")], [
      element.text(float_to_string(calories) <> " cal"),
    ]),
  ])
}
```

```gleam
// forms.gleam - Form Component Module

/// Form input field
pub fn input_field(
  name: String,
  placeholder: String,
  value: String,
) -> element.Element(msg) {
  html.input([
    attribute.type_("text"),
    attribute.name(name),
    attribute.placeholder(placeholder),
    attribute.value(value),
    attribute.class("input"),
  ])
}

/// Search input with icon
pub fn search_input(
  query: String,
  placeholder: String,
) -> element.Element(msg) {
  html.div([attribute.class("search-box")], [
    html.input([
      attribute.type_("search"),
      attribute.placeholder(placeholder),
      attribute.value(query),
      attribute.class("input-search"),
    ]),
    html.button([
      attribute.type_("submit"),
      attribute.class("btn btn-primary"),
    ], [element.text("Search")]),
  ])
}
```

```gleam
// progress.gleam - Progress Component Module

/// Macro progress bar
pub fn macro_bar(
  label: String,
  current: Float,
  target: Float,
  color: String,
) -> element.Element(msg) {
  let percentage = calculate_percentage(current, target)
  html.div([attribute.class("macro-bar")], [
    html.div([attribute.class("macro-bar-header")], [
      html.span([], [element.text(label)]),
      html.span([], [
        element.text(
          float_to_string(current) <> "g / " <> float_to_string(target) <> "g"
        ),
      ]),
    ]),
    html.div([attribute.class("progress-bar")], [
      html.div([
        attribute.class("progress-fill"),
        attribute.style(
          "width",
          float_to_string(percentage) <> "%; background-color: " <> color,
        ),
      ], []),
    ]),
  ])
}

/// Macro badge (inline label)
pub fn macro_badge(label: String, value: Float) -> element.Element(msg) {
  html.span([attribute.class("macro-badge")], [
    element.text(label <> ": " <> float_to_string(value) <> "g"),
  ])
}

/// Calculate percentage with bounds
fn calculate_percentage(current: Float, target: Float) -> Float {
  case target >. 0.0 {
    True -> {
      let pct = current /. target *. 100.0
      case pct >. 100.0 {
        True -> 100.0
        False -> pct
      }
    }
    False -> 0.0
  }
}
```

### Feature Components

```gleam
// pages/food_search.gleam - Food Search Component (BEAD 2)

/// Food search page state
pub type SearchState {
  SearchState(
    query: option.Option(String),
    results: List(UsdaFood),
    total_count: Int,
    loading: Bool,
  )
}

/// Render the food search page
pub fn render_food_search_page(state: SearchState) -> element.Element(msg) {
  html.div([attribute.class("food-search-page")], [
    page_header("Food Search"),
    search_form(state.query),
    search_results(state),
  ])
}

/// Search input form
fn search_form(query: option.Option(String)) -> element.Element(msg) {
  html.form([
    attribute.method("get"),
    attribute.action("/foods"),
  ], [
    search_input(
      query |> option.unwrap(""),
      "Search foods (e.g., chicken, apple, rice)",
    ),
  ])
}

/// Search results display
fn search_results(state: SearchState) -> element.Element(msg) {
  case state.query {
    None | Some("") ->
      html.p([attribute.class("empty-state")], [
        element.text("Enter a search term to find foods"),
      ])
    Some(q) -> {
      case state.results {
        [] ->
          html.p([attribute.class("empty-state")], [
            element.text("No foods found matching \"" <> q <> "\""),
          ])
        results ->
          html.div([attribute.class("food-list")], [
            list.map(results, food_result_item),
          ] |> list.concat)
      }
    }
  }
}

/// Individual food result item
fn food_result_item(food: UsdaFood) -> element.Element(msg) {
  html.a([
    attribute.class("food-item"),
    attribute.href("/foods/" <> int_to_string(food.fdc_id)),
  ], [
    html.div([attribute.class("food-info")], [
      html.span([attribute.class("food-name")], [
        element.text(food.description),
      ]),
      html.span([attribute.class("food-type")], [
        element.text(food.data_type),
      ]),
    ]),
  ])
}
```

```gleam
// pages/dashboard.gleam - Nutrition Dashboard Component (BEAD 3)

/// Dashboard data structure
pub type DashboardData {
  DashboardData(
    profile: UserProfile,
    daily_log: DailyLog,
    date: String,
  )
}

/// Render nutrition dashboard
pub fn render_dashboard(data: DashboardData) -> element.Element(msg) {
  let targets = daily_macro_targets(data.profile)

  html.div([attribute.class("dashboard")], [
    page_header("Dashboard"),
    date_selector(data.date),
    calorie_summary(data.daily_log, targets),
    macro_progress_section(data.daily_log, targets),
    daily_log_section(data.daily_log),
  ])
}

/// Calorie summary card
fn calorie_summary(
  log: DailyLog,
  targets: Macros,
) -> element.Element(msg) {
  let current_calories = macros_calories(log.total_macros)
  let target_calories = macros_calories(targets)

  html.div([attribute.class("calorie-summary")], [
    html.div([attribute.class("calorie-current")], [
      html.span([attribute.class("big-number")], [
        element.text(float_to_string(current_calories)),
      ]),
      html.span([], [element.text(" / ")]),
      html.span([], [
        element.text(float_to_string(target_calories)),
      ]),
      html.span([attribute.class("unit")], [element.text(" cal")]),
    ]),
  ])
}

/// Macro progress bars section
fn macro_progress_section(
  log: DailyLog,
  targets: Macros,
) -> element.Element(msg) {
  html.div([attribute.class("macro-bars")], [
    macro_bar("Protein", log.total_macros.protein, targets.protein, "--color-protein"),
    macro_bar("Fat", log.total_macros.fat, targets.fat, "--color-fat"),
    macro_bar("Carbs", log.total_macros.carbs, targets.carbs, "--color-carbs"),
  ])
}

/// Daily log entries list
fn daily_log_section(log: DailyLog) -> element.Element(msg) {
  html.div([attribute.class("daily-log")], [
    html.h2([], [element.text("Meals Logged")]),
    case log.entries {
      [] ->
        html.p([attribute.class("empty-state")], [
          element.text("No meals logged for today"),
        ])
      entries ->
        html.ul([attribute.class("meal-list")], [
          list.map(entries, meal_list_item),
        ] |> list.concat)
    }
  ])
}

/// Individual meal list item
fn meal_list_item(entry: FoodLogEntry) -> element.Element(msg) {
  html.li([attribute.class("meal-item")], [
    html.span([attribute.class("meal-name")], [
      element.text(entry.recipe_name),
    ]),
    html.span([attribute.class("meal-type")], [
      element.text(meal_type_to_string(entry.meal_type)),
    ]),
    macro_badges(entry.macros),
  ])
}
```

---

## 6. Data Flow & Integration Points

### Server-Side Data Loading

```gleam
// Pattern: Load data -> Render component -> Respond

// Example: Dashboard page
fn dashboard_page(req: wisp.Request, ctx: Context) -> wisp.Response {
  // 1. Load data from database
  let profile = load_profile(ctx)
  let daily_log = load_daily_log(ctx, get_today_date())

  // 2. Create data structure for component
  let dashboard_data = DashboardData(
    profile: profile,
    daily_log: daily_log,
    date: get_today_date(),
  )

  // 3. Render component to HTML
  let content = [
    render_dashboard(dashboard_data)
  ]

  // 4. Wrap in page template and respond
  wisp.html_response(render_page("Dashboard", content), 200)
}
```

### State Management Strategy

Since this is SSR with no client-side JS:

- **Server State**: Database + Query parameters (date, search query)
- **Form Submission**: HTTP GET/POST to trigger page re-renders
- **Progressive Enhancement**: Forms work without JS

```gleam
// Query parameter extraction pattern
fn extract_search_query(req: wisp.Request) -> option.Option(String) {
  case uri.parse_query(req.query |> option.unwrap("")) {
    Ok(params) -> {
      case list.find(params, fn(p) { p.0 == "q" }) {
        Ok(#(_, q)) -> Some(q)
        Error(_) -> None
      }
    }
    Error(_) -> None
  }
}

// Usage in food search handler
fn foods_page(req: wisp.Request, ctx: Context) -> wisp.Response {
  let query = extract_search_query(req)
  let foods = case query {
    Some(q) if q != "" -> search_foods(ctx, q, 50)
    _ -> []
  }
  let state = SearchState(
    query: query,
    results: foods,
    total_count: get_foods_count(ctx),
    loading: False,
  )

  let content = [render_food_search_page(state)]
  wisp.html_response(render_page("Food Search", content), 200)
}
```

---

## 7. Implementation Roadmap (Three Beads)

### Bead 1: CSS Design System (Foundation)

**Duration**: 3-4 days
**Priority**: Highest (Blocks other beads)

#### Deliverables

- Design tokens (colors, typography, spacing) in CSS custom properties
- Utility classes for common patterns
- Base component styles (buttons, cards, forms, progress)
- Responsive design system with mobile-first breakpoints
- CSS file organization and architecture documentation

#### Files to Create/Update

```
priv/static/
├── theme.css                (NEW) - Design tokens
├── utilities.css            (NEW) - Utility classes
├── components.css           (NEW) - Base components
├── responsive.css           (NEW) - Breakpoints
└── styles.css              (UPDATE) - Main import file
```

#### Key Interfaces

```gleam
// design_system.gleam (NEW)
// Functions to generate CSS from Gleam types

pub fn color_to_css(color: String) -> String {
  // Convert color names to CSS custom property references
  case color {
    "primary" -> "var(--color-primary)"
    "success" -> "var(--color-success)"
    // ...
  }
}

pub fn spacing_to_css(scale: Int) -> String {
  // Convert spacing scale to CSS variables
  "var(--space-" <> int.to_string(scale) <> ")"
}
```

#### Success Criteria

- All colors, typography, spacing accessible via CSS custom properties
- Button, card, form, and progress components fully styled
- Mobile responsive (tested at 320px, 768px, 1024px viewports)
- Performance: < 30KB minified

### Bead 2: Food Search Component

**Duration**: 3-4 days
**Dependencies**: Bead 1 (CSS Design System)
**Priority**: High (Used by other features)

#### Deliverables

- Search input component with styling
- Results list display with pagination hints
- Food detail view component
- Type-safe data structures for search results
- Server-side search integration with PostgreSQL FTS

#### Files to Create/Update

```
gleam/src/meal_planner/ui/
├── components/forms.gleam   (UPDATE) - Add search_input
├── pages/food_search.gleam  (NEW) - Food search page component
└── pages/food_detail.gleam  (NEW) - Food detail page component

gleam/src/meal_planner/
├── web.gleam               (UPDATE) - Route handlers
└── storage.gleam           (EXISTING) - Search functions
```

#### Key Interfaces

```gleam
// food_search.gleam (NEW)

pub type FoodSearchState {
  FoodSearchState(
    query: option.Option(String),
    results: List(UsdaFood),
    total_count: Int,
    selected_food: option.Option(UsdaFood),
  )
}

pub fn render_food_search_page(state: FoodSearchState) -> element.Element(msg)
pub fn render_food_detail(food: UsdaFood, nutrients: List(FoodNutrientValue)) -> element.Element(msg)

// web.gleam handlers
fn foods_page(req: wisp.Request, ctx: Context) -> wisp.Response
fn food_detail_page(id: String, ctx: Context) -> wisp.Response
```

#### Success Criteria

- Search queries return results in < 100ms
- Display up to 50 results per search
- Food detail page shows complete nutrition info
- Mobile responsive search interface
- Accessible form labels and ARIA attributes

### Bead 3: Nutrition Dashboard

**Duration**: 3-4 days
**Dependencies**: Bead 1 (CSS Design System), partially on Bead 2
**Priority**: High (Core feature)

#### Deliverables

- Dashboard layout with date navigation
- Calorie summary display component
- Macro progress bars with visual feedback
- Daily log entries list
- Integration with existing DailyLog data structure

#### Files to Create/Update

```
gleam/src/meal_planner/ui/
├── components/progress.gleam (UPDATE) - Add macro progress visualization
├── pages/dashboard.gleam     (NEW) - Dashboard page component
└── pages/home.gleam          (NEW) - Updated home page with new styles

gleam/src/meal_planner/
└── web.gleam                (UPDATE) - Dashboard handler
```

#### Key Interfaces

```gleam
// dashboard.gleam (NEW)

pub type DashboardData {
  DashboardData(
    profile: UserProfile,
    daily_log: DailyLog,
    date: String,
  )
}

pub fn render_dashboard(data: DashboardData) -> element.Element(msg)
pub fn render_nutrition_summary(profile: UserProfile, log: DailyLog) -> element.Element(msg)

// web.gleam handlers (UPDATE)
fn dashboard_page(req: wisp.Request, ctx: Context) -> wisp.Response
fn get_dashboard_data(ctx: Context, date: String) -> DashboardData
```

#### Success Criteria

- Display current macros vs. targets with visual indicators
- Date selector shows previous/next day navigation
- Progress bars clearly show remaining macro targets
- Mobile responsive dashboard layout
- Loads dashboard in < 200ms

---

## 8. Architecture Decision Records (ADRs)

### ADR-1: Server-Side Rendering (SSR) Over Single-Page Application (SPA)

**Decision**: Use Gleam/Lustre SSR for page rendering, not client-side SPA.

**Rationale**:
1. **Type Safety**: Gleam's type system catches errors at compile time
2. **Performance**: No client-side JS bloat; fast initial load
3. **Simplicity**: Stateless request-response model; easier to reason about
4. **SEO**: HTML rendered on server; fully indexable by search engines
5. **Accessibility**: Progressive enhancement; works without JS
6. **Database Proximity**: Logic runs on server; direct DB access

**Trade-offs**:
- No real-time UI updates without polling or WebSockets
- Page reloads for navigation (acceptable with fast server)
- Limited offline functionality (acceptable for nutrition app)

**Alternative Rejected**: Client-side Lustre SPA with API
- Would require significant JS bundling
- Complexity in state management
- Less type safety across JS boundary

---

### ADR-2: CSS Architecture: Utility + Component Hybrid

**Decision**: Use utility classes (Tailwind-like) + semantic component styles.

**Rationale**:
1. **Flexibility**: Utilities for quick prototyping and one-offs
2. **Consistency**: Semantic components enforce design system
3. **Maintainability**: Easy to locate component styles
4. **Performance**: Can tree-shake unused utilities
5. **Learning Curve**: Familiar pattern for modern web developers

**CSS Organization**:
```
Utilities (small, reusable) + Components (semantic, purposeful)
```

**Examples**:
```css
/* Utility class */
.flex { display: flex; }
.gap-4 { gap: var(--space-4); }

/* Component class */
.button { /* button base styles */ }
.button-primary { /* primary variant */ }
```

**Alternative Rejected**: Pure semantic CSS
- Requires creating classes for every combination
- Harder to maintain consistency
- Less flexible for one-offs

---

### ADR-3: CSS Custom Properties for Design Tokens

**Decision**: Use CSS custom properties (CSS variables) for all design tokens.

**Rationale**:
1. **No Build Tools Required**: Works natively in modern browsers
2. **Runtime Flexibility**: Can change theme colors without recompile
3. **Scoping**: Can override in specific contexts (e.g., dark mode)
4. **Maintainability**: Single source of truth for design values
5. **JavaScript Integration**: Can be accessed/modified from Gleam/JS if needed

**Gleam Integration**:
```gleam
// Design tokens defined as CSS custom properties
// Gleam functions reference them by name
pub fn button_classes(variant: ButtonVariant) -> String {
  case variant {
    Primary -> "btn btn-primary"  // Uses --color-primary in CSS
    // ...
  }
}
```

**Alternative Rejected**: SCSS/PostCSS
- Adds build complexity
- Gleam doesn't natively support SCSS
- CSS custom properties sufficient for design tokens

---

### ADR-4: Component Composition via Lustre Element Functions

**Decision**: Create pure functions that return `element.Element(msg)` for components.

**Rationale**:
1. **Type Safety**: Return type is checked at compile time
2. **Composability**: Easy to nest and combine components
3. **Testability**: Pure functions; easy to unit test
4. **No Runtime Overhead**: Compiled to efficient Erlang

**Pattern**:
```gleam
pub fn button(label: String, href: String) -> element.Element(msg) {
  html.a([attribute.href(href), attribute.class("btn")], [
    element.text(label)
  ])
}

pub fn card(title: String, content: List(element.Element(msg))) -> element.Element(msg) {
  html.div([attribute.class("card")], [
    html.h2([], [element.text(title)]),
    html.div([], content)
  ])
}
```

**Alternative Rejected**: Lustre components with state
- Adds complexity; not needed for SSR
- Harder to type-check across components
- More runtime overhead

---

### ADR-5: Mobile-First Responsive Design

**Decision**: Build CSS for mobile first, then add tablet/desktop enhancements.

**Rationale**:
1. **Mobile Traffic**: Majority of users on mobile devices
2. **Progressive Enhancement**: Mobile styles are baseline
3. **Performance**: Smaller CSS payload for mobile
4. **Easier Media Queries**: Add complexity as screen size increases

**Breakpoints**:
```css
/* Mobile: default (<640px) */
/* Tablet: 640px+ */
@media (min-width: 640px) { }
/* Desktop: 1024px+ */
@media (min-width: 1024px) { }
```

**Alternative Rejected**: Desktop-first approach
- Requires many `max-width` media queries
- Harder to test on actual mobile devices
- Not modern best practice

---

### ADR-6: Type-Safe Data Structures for Components

**Decision**: Define Gleam types for component data; no untyped maps or objects.

**Rationale**:
1. **Compile-Time Safety**: Missing fields caught at compile time
2. **Self-Documenting**: Types describe component requirements
3. **Refactoring**: Type checker enforces updates across codebase
4. **Performance**: Records are optimized for pattern matching

**Example**:
```gleam
pub type StatCard {
  StatCard(
    label: String,
    value: String,
    unit: String,
    trend: option.Option(Float),
  )
}

pub fn render_stat_card(card: StatCard) -> element.Element(msg) {
  // Type guarantees all required fields are present
}
```

**Alternative Rejected**: Dynamic types
- Loss of compile-time checking
- Runtime errors possible
- Harder to maintain

---

## 9. Component Interaction Examples

### Food Search Flow

```
User Action: Enter search query
    |
    v
GET /foods?q=chicken
    |
    v
foods_page() handler:
  1. Extract query from request parameters
  2. Call search_foods(ctx, "chicken", 50) -> List(UsdaFood)
  3. Create SearchState with results
  4. Call render_food_search_page(state)
  5. Render to HTML string
    |
    v
Response: HTML page with search results
    |
    v
User Action: Click food item
    |
    v
GET /foods/123456
    |
    v
food_detail_page() handler:
  1. Extract FDC ID from URL
  2. Load food details: get_food_by_id(ctx, 123456)
  3. Load nutrients: get_food_nutrients(ctx, 123456)
  4. Call render_food_detail(food, nutrients)
    |
    v
Response: Detailed nutrient information page
```

### Dashboard Date Navigation

```
User Action: Click "Previous Day"
    |
    v
GET /dashboard?date=2025-12-02
    |
    v
dashboard_page() handler:
  1. Extract date from query parameters
  2. Load user profile: load_profile(ctx)
  3. Load daily log: load_daily_log(ctx, "2025-12-02")
  4. Create DashboardData structure
  5. Calculate macro targets from profile
  6. Call render_dashboard(data)
    |
    v
Response: HTML with updated dashboard for selected date
    |
    v
Browser displays: Previous day's nutrition data
```

---

## 10. Testing Strategy

### Unit Tests (Gleam)

```gleam
// Test component rendering
#[test]
fn test_button_renders_primary() {
  let btn = buttons.button("Click me", "/action", buttons.Primary)
  let html = element.to_string(btn)
  assert string.contains(html, "btn-primary")
  assert string.contains(html, "Click me")
}

// Test data transformations
#[test]
fn test_macro_percentage_calculation() {
  let pct = progress.calculate_percentage(50.0, 100.0)
  assert pct == 50.0

  let capped = progress.calculate_percentage(150.0, 100.0)
  assert capped == 100.0
}

// Test search state
#[test]
fn test_empty_search_state() {
  let state = SearchState(query: None, results: [], total_count: 0, loading: False)
  assert list.length(state.results) == 0
}
```

### Integration Tests (Page Routes)

```gleam
#[test]
fn test_dashboard_page_loads() {
  // Mock database context
  let ctx = create_test_context()

  // Create mock request
  let req = create_test_request("/dashboard", get: [])

  // Render page
  let response = dashboard_page(req, ctx)

  // Assert response contains expected content
  assert string.contains(response.body, "Dashboard")
  assert string.contains(response.body, "Calories")
}
```

### Manual Testing Checklist

- [ ] Responsive design at 320px, 768px, 1024px viewports
- [ ] Keyboard navigation (Tab, Enter)
- [ ] Mobile touch interactions (swipe, long-press)
- [ ] Form submissions work without JavaScript
- [ ] Color contrast meets WCAG AA standards
- [ ] Loading times < 200ms on fast 4G

---

## 11. Performance Considerations

### CSS Performance

- Minify and compress CSS files
- Inline critical above-the-fold CSS (optional)
- Lazy load non-critical styles
- No unused CSS selectors (design tokens only)
- Target: < 30KB gzipped for all CSS

### HTML Performance

- Stream HTML to browser (Wisp supports this)
- Minimize HTML payload (no unnecessary wrappers)
- Compress text responses
- Use HTTP caching headers

### Database Performance

- Use PostgreSQL full-text search for food search (already implemented)
- Index frequently queried columns (date, user_id, recipe_id)
- Connection pooling (using Pog)
- Target: < 100ms query response time

### Overall Target

- Dashboard load: < 200ms
- Food search: < 100ms
- Initial page render: < 300ms

---

## 12. Accessibility Guidelines

### WCAG 2.1 Level AA Compliance

- [ ] Color contrast: 4.5:1 for normal text, 3:1 for large text
- [ ] Form labels: Every input has associated `<label>`
- [ ] ARIA roles: Use semantic HTML; add ARIA only when needed
- [ ] Keyboard navigation: All interactive elements reachable by Tab
- [ ] Focus indicators: Visible focus ring on all buttons/links
- [ ] Alt text: All images have descriptive alt text
- [ ] Error messages: Clear, associated with form fields

### Implementation in Gleam/Lustre

```gleam
// Form with proper labels
pub fn search_form(query: String) -> element.Element(msg) {
  html.form([attribute.method("get"), attribute.action("/foods")], [
    html.label([attribute.for("search-input")], [
      element.text("Search foods:"),
    ]),
    html.input([
      attribute.id("search-input"),
      attribute.type_("search"),
      attribute.name("q"),
      attribute.value(query),
      attribute.aria_label("Food search query"),
    ]),
    html.button([
      attribute.type_("submit"),
      attribute.aria_label("Submit search"),
    ], [element.text("Search")]),
  ])
}

// Interactive element with focus indicator
pub fn button_with_focus(label: String, href: String) -> element.Element(msg) {
  html.a([
    attribute.href(href),
    attribute.class("btn"),
    attribute.aria_label(label),
  ], [element.text(label)])
}
```

---

## 13. Future Enhancements

### Phase 2 (Post-MVP)

1. **Dark Mode Support**
   - Add CSS custom properties for dark color scheme
   - Prefers-color-scheme media query

2. **Animations**
   - Subtle transitions for better UX
   - Progress bar fill animation
   - Card hover effects

3. **Advanced Filtering**
   - Filter food search by category
   - Sort recipes by macro ratio
   - Advanced dashboard analytics

4. **Personalization**
   - User theme preferences (color scheme, font size)
   - Saved search filters
   - Dashboard widget customization

5. **Progressive Web App**
   - Service Worker for offline caching
   - App installation support
   - Push notifications for goals

### Phase 3 (Long-term)

1. **Client-Side Enhancements** (with minimal JavaScript)
   - htmx for dynamic updates without page reload
   - In-place form validation
   - Live search results

2. **Real-Time Features**
   - WebSocket integration for multi-device sync
   - Live nutrition data from wearables
   - Real-time collaborative meal planning

3. **Advanced Analytics**
   - Historical trend charts
   - Goal progress tracking
   - Personalized macro recommendations

---

## 14. Integration with Existing Code

### Current Web.gleam Integration Points

The redesign components will be integrated into the existing `web.gleam` module:

```gleam
// Existing (Current)
fn home_page() -> wisp.Response {
  let content = [ /* inline HTML */ ]
  wisp.html_response(render_page("Home", content), 200)
}

// Proposed Refactoring (Using Components)
fn home_page() -> wisp.Response {
  let content = [
    home.render_home_page()  // NEW: Component from ui/pages/home.gleam
  ]
  wisp.html_response(render_page("Home", content), 200)
}

// Dashboard Integration
fn dashboard_page(req: wisp.Request, ctx: Context) -> wisp.Response {
  let profile = load_profile(ctx)
  let daily_log = load_daily_log(ctx, get_today_date())

  // NEW: Type-safe dashboard component
  let dashboard_data = dashboard.DashboardData(
    profile: profile,
    daily_log: daily_log,
    date: get_today_date(),
  )

  let content = [
    dashboard.render_dashboard(dashboard_data)
  ]
  wisp.html_response(render_page("Dashboard", content), 200)
}
```

### CSS File Updates

```gleam
// Current: Single styles.css with all styles
<link rel="stylesheet" href="/static/styles.css">

// Proposed: Modular CSS imports
<link rel="stylesheet" href="/static/theme.css">      <!-- Design tokens -->
<link rel="stylesheet" href="/static/utilities.css">  <!-- Utility classes -->
<link rel="stylesheet" href="/static/components.css"> <!-- Component styles -->
<link rel="stylesheet" href="/static/responsive.css"> <!-- Media queries -->
```

Or alternatively, import via single main CSS file:

```css
/* priv/static/styles.css */
@import url('theme.css');
@import url('utilities.css');
@import url('components.css');
@import url('responsive.css');
```

---

## 15. Migration Plan

### Phase 1: Foundation (Bead 1 - CSS System)
1. Create CSS design system with custom properties
2. Build base component styles
3. Test on existing pages (no Gleam changes required)
4. Commit: "feat: add modular CSS design system"

### Phase 2: Component Layer (Gleam Refactoring)
1. Create `ui/components` directory with atomic components
2. Create `ui/pages` directory with feature components
3. Update `web.gleam` handlers to use new components
4. Commit: "refactor: extract UI components from pages"

### Phase 3: Bead 2 (Food Search)
1. Implement food search components
2. Update `web.gleam` food search handlers
3. Integration tests
4. Commit: "feat(bead-2): redesigned food search component"

### Phase 4: Bead 3 (Dashboard)
1. Implement dashboard components
2. Update dashboard handlers
3. Integration tests
4. Commit: "feat(bead-3): redesigned nutrition dashboard"

### Phase 5: Cleanup & Documentation
1. Remove inline styles from old `web.gleam`
2. Update documentation
3. Add accessibility audit
4. Performance optimization
5. Commit: "docs: add UI architecture documentation"

---

## 16. Reference Examples

### Example: Rendering Food Search Results

```gleam
// pages/food_search.gleam
import meal_planner/ui/components/forms
import meal_planner/ui/components/cards
import meal_planner/storage

pub type SearchState {
  SearchState(
    query: option.Option(String),
    results: List(storage.UsdaFood),
    total_count: Int,
  )
}

pub fn render_food_search_page(state: SearchState) -> element.Element(msg) {
  html.div([attribute.class("food-search-page")], [
    // Page header
    html.div([attribute.class("page-header")], [
      html.h1([], [element.text("Food Search")]),
      html.p([attribute.class("subtitle")], [
        element.text("Search " <> int_to_string(state.total_count) <> " USDA foods"),
      ]),
    ]),

    // Search form
    html.form([attribute.action("/foods"), attribute.method("get")], [
      forms.search_input(
        state.query |> option.unwrap(""),
        "Search foods (e.g., chicken, apple, rice)"
      ),
    ]),

    // Results
    case state.query {
      None | Some("") ->
        html.p([attribute.class("empty-state")], [
          element.text("Enter a search term to find foods"),
        ])

      Some(q) if q != "" -> {
        case state.results {
          [] ->
            html.p([attribute.class("empty-state")], [
              element.text("No foods found matching \"" <> q <> "\""),
            ])

          results ->
            html.div([attribute.class("food-list")], [
              list.map(results, food_result_card),
            ] |> list.concat)
        }
      }

      _ -> element.none()
    }
  ])
}

fn food_result_card(food: storage.UsdaFood) -> element.Element(msg) {
  html.a([
    attribute.class("food-result-card"),
    attribute.href("/foods/" <> int_to_string(food.fdc_id)),
  ], [
    html.div([attribute.class("food-card-content")], [
      html.span([attribute.class("food-name")], [
        element.text(food.description),
      ]),
      html.span([attribute.class("food-type")], [
        element.text(food.data_type),
      ]),
    ]),
  ])
}
```

### Example: Dashboard with Type-Safe Data

```gleam
// pages/dashboard.gleam
import meal_planner/ui/components/progress
import meal_planner/ui/components/cards

pub type DashboardData {
  DashboardData(
    profile: UserProfile,
    daily_log: DailyLog,
    date: String,
  )
}

pub fn render_dashboard(data: DashboardData) -> element.Element(msg) {
  let targets = daily_macro_targets(data.profile)

  html.div([attribute.class("dashboard")], [
    // Header
    html.header([attribute.class("page-header")], [
      html.h1([], [element.text("Dashboard")]),
    ]),

    // Date navigation
    html.div([attribute.class("date-navigation")], [
      html.a([
        attribute.href("/dashboard?date=2025-12-02"),
        attribute.class("btn btn-secondary"),
      ], [element.text("← Previous")]),
      html.span([], [element.text(data.date)]),
      html.a([
        attribute.href("/dashboard?date=2025-12-04"),
        attribute.class("btn btn-secondary"),
      ], [element.text("Next →")]),
    ]),

    // Calorie summary card
    html.div([attribute.class("calorie-summary")], [
      let current_cal = macros_calories(data.daily_log.total_macros)
      let target_cal = macros_calories(targets)

      html.div([attribute.class("big-stat")], [
        html.span([attribute.class("big-number")], [
          element.text(float_to_string(current_cal)),
        ]),
        html.span([attribute.class("separator")], [element.text(" / ")]),
        html.span([], [element.text(float_to_string(target_cal))]),
        html.span([attribute.class("unit")], [element.text(" cal")]),
      ]),
    ]),

    // Macro bars
    html.div([attribute.class("macro-bars")], [
      progress.macro_bar(
        "Protein",
        data.daily_log.total_macros.protein,
        targets.protein,
        "var(--color-protein)"
      ),
      progress.macro_bar(
        "Fat",
        data.daily_log.total_macros.fat,
        targets.fat,
        "var(--color-fat)"
      ),
      progress.macro_bar(
        "Carbs",
        data.daily_log.total_macros.carbs,
        targets.carbs,
        "var(--color-carbs)"
      ),
    ]),

    // Daily log entries
    html.div([attribute.class("daily-log-section")], [
      html.h2([], [element.text("Meals Logged")]),
      case data.daily_log.entries {
        [] ->
          html.p([attribute.class("empty-state")], [
            element.text("No meals logged for " <> data.date),
          ])

        entries ->
          html.ul([attribute.class("meal-list")], [
            list.map(entries, meal_list_item),
          ] |> list.concat)
      }
    ]),
  ])
}

fn meal_list_item(entry: FoodLogEntry) -> element.Element(msg) {
  html.li([attribute.class("meal-item")], [
    html.div([attribute.class("meal-info")], [
      html.span([attribute.class("meal-name")], [
        element.text(entry.recipe_name),
      ]),
      html.span([attribute.class("meal-type")], [
        element.text(meal_type_string(entry.meal_type)),
      ]),
    ]),
    html.div([attribute.class("meal-macros")], [
      progress.macro_badge("P", entry.macros.protein),
      progress.macro_badge("F", entry.macros.fat),
      progress.macro_badge("C", entry.macros.carbs),
    ]),
  ])
}
```

---

## 17. Summary & Key Takeaways

This architecture enables:

1. **Type-Safe Components**: Gleam's type system ensures correctness at compile time
2. **Modular CSS**: Design system with custom properties enables consistency
3. **Server-Side Rendering**: Fast, accessible, SEO-friendly pages
4. **Maintainability**: Clear separation of concerns and component boundaries
5. **Scalability**: Easy to add new components and features
6. **Accessibility**: Built-in WCAG 2.1 compliance patterns
7. **Performance**: Optimized for fast page loads and minimal runtime overhead

The three beads provide a clear implementation roadmap:
- **Bead 1 (CSS System)**: Foundation for all other work
- **Bead 2 (Food Search)**: High-value feature with complex interactions
- **Bead 3 (Dashboard)**: Core feature providing user value

---

## Appendices

### A. CSS Custom Properties Reference

See section 4.1 for complete design token definitions.

### B. Component API Signatures

See section 5 for detailed Gleam function signatures.

### C. Testing Checklist

See section 10 for testing strategy and examples.

### D. Accessibility Checklist

See section 12 for WCAG 2.1 compliance guidelines.

---

**Document Generated**: 2025-12-03
**Last Updated**: 2025-12-03
**Version**: 1.0
**Status**: Ready for Architecture Review
