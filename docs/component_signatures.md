# Component Function Signatures & Interfaces

This document provides precise Gleam type signatures for all UI components referenced in the architecture.

## Overview

All components follow the pattern:

```gleam
pub fn component_name(
  param1: Type1,
  param2: Type2,
) -> element.Element(msg)
```

Components are pure functions that return Lustre elements, suitable for server-side rendering.

---

## Atomic Components

### Buttons (`ui/components/buttons.gleam`)

```gleam
/// Button variant enumeration
pub type ButtonVariant {
  Primary
  Secondary
  Danger
  Success
  Warning
}

/// Button size enumeration
pub type ButtonSize {
  Small
  Medium
  Large
}

/// Basic button link
/// Renders: <a href="/path" class="btn btn-primary">Label</a>
pub fn button(
  label: String,
  href: String,
  variant: ButtonVariant,
) -> element.Element(msg)

/// Button with custom size
pub fn button_sized(
  label: String,
  href: String,
  variant: ButtonVariant,
  size: ButtonSize,
) -> element.Element(msg)

/// Submit button for forms
/// Renders: <button type="submit" class="btn btn-primary">Label</button>
pub fn submit_button(
  label: String,
  variant: ButtonVariant,
) -> element.Element(msg)

/// Disabled button state
pub fn button_disabled(
  label: String,
  variant: ButtonVariant,
) -> element.Element(msg)

/// Button group container
pub fn button_group(
  buttons: List(element.Element(msg)),
) -> element.Element(msg)
```

### Cards (`ui/components/cards.gleam`)

```gleam
/// Card variant type
pub type CardVariant {
  Basic
  Elevated
  Outlined
}

/// Basic card container
/// Renders: <div class="card">content</div>
pub fn card(
  content: List(element.Element(msg)),
) -> element.Element(msg)

/// Card with header
pub fn card_with_header(
  header: String,
  content: List(element.Element(msg)),
) -> element.Element(msg)

/// Card with header and actions
pub fn card_with_actions(
  header: String,
  content: List(element.Element(msg)),
  actions: List(element.Element(msg)),
) -> element.Element(msg)

/// Statistic card (value-focused)
pub type StatCard {
  StatCard(
    label: String,
    value: String,
    unit: String,
    trend: option.Option(Float),
    color: String,
  )
}

pub fn stat_card(stat: StatCard) -> element.Element(msg)

/// Recipe card for display in grid
pub type RecipeCardData {
  RecipeCardData(
    id: String,
    name: String,
    category: String,
    macros: Macros,
    image_url: option.Option(String),
  )
}

pub fn recipe_card(data: RecipeCardData) -> element.Element(msg)

/// Food search result card
pub type FoodCardData {
  FoodCardData(
    fdc_id: Int,
    description: String,
    data_type: String,
    category: String,
  )
}

pub fn food_card(data: FoodCardData) -> element.Element(msg)
```

### Forms (`ui/components/forms.gleam`)

```gleam
/// Text input field
pub fn input_field(
  name: String,
  placeholder: String,
  value: String,
) -> element.Element(msg)

/// Text input with label
pub fn input_with_label(
  label: String,
  name: String,
  placeholder: String,
  value: String,
) -> element.Element(msg)

/// Search input with integrated button
pub fn search_input(
  query: String,
  placeholder: String,
) -> element.Element(msg)

/// Number input field
pub fn number_input(
  name: String,
  label: String,
  value: Float,
  min: option.Option(Float),
  max: option.Option(Float),
) -> element.Element(msg)

/// Select dropdown
pub type SelectOption {
  SelectOption(value: String, label: String, selected: Bool)
}

pub fn select_field(
  name: String,
  label: String,
  options: List(SelectOption),
) -> element.Element(msg)

/// Form group container with label and error message
pub type FormField {
  FormField(
    label: String,
    input: element.Element(msg),
    error: option.Option(String),
  )
}

pub fn form_field(field: FormField) -> element.Element(msg)

/// Form container
pub fn form(
  action: String,
  method: String,
  fields: List(element.Element(msg)),
  submit_label: String,
) -> element.Element(msg)
```

### Progress Indicators (`ui/components/progress.gleam`)

```gleam
/// Progress bar component
pub fn progress_bar(
  current: Float,
  target: Float,
  color: String,
) -> element.Element(msg)

/// Macro progress bar with label
pub fn macro_bar(
  label: String,
  current: Float,
  target: Float,
  color: String,
) -> element.Element(msg)

/// Macro badge (inline label with value)
pub fn macro_badge(
  label: String,
  value: Float,
) -> element.Element(msg)

/// Multi-macro badges group
pub fn macro_badges(macros: Macros) -> element.Element(msg)

/// Status badge/indicator
pub type StatusType {
  Success
  Warning
  Error
  Info
}

pub fn status_badge(
  label: String,
  status: StatusType,
) -> element.Element(msg)

/// Circular progress indicator (percentage)
pub fn progress_circle(
  percentage: Float,
  label: String,
) -> element.Element(msg)

/// Linear progress bar with percentage text
pub fn progress_with_label(
  current: Float,
  target: Float,
  label: String,
) -> element.Element(msg)
```

### Typography (`ui/components/typography.gleam`)

```gleam
/// Heading levels
pub fn h1(text: String) -> element.Element(msg)
pub fn h2(text: String) -> element.Element(msg)
pub fn h3(text: String) -> element.Element(msg)
pub fn h4(text: String) -> element.Element(msg)
pub fn h5(text: String) -> element.Element(msg)
pub fn h6(text: String) -> element.Element(msg)

/// Heading with optional subtitle
pub fn heading_with_subtitle(
  level: Int,
  title: String,
  subtitle: option.Option(String),
) -> element.Element(msg)

/// Body text
pub fn body_text(text: String) -> element.Element(msg)

/// Small/secondary text
pub fn secondary_text(text: String) -> element.Element(msg)

/// Label text (typically for forms)
pub fn label_text(text: String, for: String) -> element.Element(msg)

/// Text with semantic emphasis
pub type TextEmphasis {
  Normal
  Strong
  Italic
  Code
  Underline
}

pub fn emphasize_text(
  text: String,
  emphasis: TextEmphasis,
) -> element.Element(msg)

/// Monospace text (for code/numbers)
pub fn mono_text(text: String) -> element.Element(msg)
```

### Layout (`ui/components/layout.gleam`)

```gleam
/// Flex container
pub type FlexDirection {
  Row
  Column
  RowReverse
  ColumnReverse
}

pub type FlexAlign {
  Start
  Center
  End
  Stretch
  Between
  Around
}

pub type FlexJustify {
  Start
  Center
  End
  Between
  Around
  Even
}

pub fn flex(
  direction: FlexDirection,
  align: FlexAlign,
  justify: FlexJustify,
  gap: Int,
  children: List(element.Element(msg)),
) -> element.Element(msg)

/// Grid container
pub type GridColumns {
  Auto
  Fixed(Int)
  Repeat(Int)
  Responsive
}

pub fn grid(
  columns: GridColumns,
  gap: Int,
  children: List(element.Element(msg)),
) -> element.Element(msg)

/// Spacing container
pub fn space_around(
  amount: Int,
  children: List(element.Element(msg)),
) -> element.Element(msg)

/// Container with max-width
pub fn container(
  max_width: Int,
  children: List(element.Element(msg)),
) -> element.Element(msg)

/// Page section with padding
pub fn section(
  children: List(element.Element(msg)),
) -> element.Element(msg)
```

---

## Page Components

### Home Page (`ui/pages/home.gleam`)

```gleam
/// Render complete home page
pub fn render_home_page() -> element.Element(msg)

/// Hero section
pub fn hero_section() -> element.Element(msg)

/// Navigation cards
pub type NavCard {
  NavCard(
    icon: String,
    label: String,
    href: String,
  )
}

pub fn nav_cards(cards: List(NavCard)) -> element.Element(msg)
```

### Food Search Page (`ui/pages/food_search.gleam`)

```gleam
/// Food search page state
pub type FoodSearchState {
  FoodSearchState(
    query: option.Option(String),
    results: List(UsdaFood),
    total_count: Int,
    loading: Bool,
  )
}

/// Render complete food search page
pub fn render_food_search_page(
  state: FoodSearchState,
) -> element.Element(msg)

/// Search form component
fn search_form(
  query: option.Option(String),
) -> element.Element(msg)

/// Search results list
fn search_results(
  state: FoodSearchState,
) -> element.Element(msg)

/// Individual food result item
fn food_result_item(
  food: UsdaFood,
) -> element.Element(msg)
```

### Food Detail Page (`ui/pages/food_detail.gleam`)

```gleam
/// Food detail page state
pub type FoodDetailState {
  FoodDetailState(
    food: UsdaFood,
    nutrients: List(FoodNutrientValue),
  )
}

/// Render complete food detail page
pub fn render_food_detail_page(
  state: FoodDetailState,
) -> element.Element(msg)

/// Nutrient table
fn nutrients_table(
  nutrients: List(FoodNutrientValue),
) -> element.Element(msg)

/// Key nutrients summary
fn nutrients_summary(
  nutrients: List(FoodNutrientValue),
) -> element.Element(msg)
```

### Dashboard Page (`ui/pages/dashboard.gleam`)

```gleam
/// Dashboard data structure
pub type DashboardData {
  DashboardData(
    profile: UserProfile,
    daily_log: DailyLog,
    date: String,
  )
}

/// Render complete dashboard
pub fn render_dashboard(
  data: DashboardData,
) -> element.Element(msg)

/// Calorie summary section
fn calorie_summary(
  daily_log: DailyLog,
  targets: Macros,
) -> element.Element(msg)

/// Macro progress section
fn macro_progress_section(
  daily_log: DailyLog,
  targets: Macros,
) -> element.Element(msg)

/// Daily log entries section
fn daily_log_section(
  log: DailyLog,
) -> element.Element(msg)

/// Date navigation component
fn date_selector(
  current_date: String,
) -> element.Element(msg)

/// Individual meal entry
fn meal_list_item(
  entry: FoodLogEntry,
) -> element.Element(msg)
```

### Profile Page (`ui/pages/profile.gleam`)

```gleam
/// Render complete profile page
pub fn render_profile_page(
  profile: UserProfile,
  targets: Macros,
) -> element.Element(msg)

/// User stats section
fn user_stats_section(
  profile: UserProfile,
) -> element.Element(msg)

/// Daily targets section
fn daily_targets_section(
  targets: Macros,
) -> element.Element(msg)
```

### Recipe Detail Page (`ui/pages/recipe_detail.gleam`)

```gleam
/// Render complete recipe detail
pub fn render_recipe_detail(
  recipe: Recipe,
) -> element.Element(msg)

/// Recipe header with actions
fn recipe_header(
  recipe: Recipe,
) -> element.Element(msg)

/// Ingredients list
fn ingredients_list(
  ingredients: List(Ingredient),
) -> element.Element(msg)

/// Instructions list
fn instructions_list(
  instructions: List(String),
) -> element.Element(msg)

/// Nutrition summary card
fn nutrition_summary(
  macros: Macros,
) -> element.Element(msg)
```

---

## Page Layout (`ui/pages/layout.gleam`)

```gleam
/// Render full HTML page with template
pub fn render_page(
  title: String,
  content: List(element.Element(msg)),
) -> String

/// Page header component
pub fn page_header(
  title: String,
  back_href: String,
) -> element.Element(msg)

/// Footer component
pub fn page_footer() -> element.Element(msg)

/// Navigation header
pub fn navigation_header() -> element.Element(msg)
```

---

## Design System (`ui/styles/design_system.gleam`)

```gleam
/// Color definitions
pub type Color {
  Primary
  Secondary
  Success
  Warning
  Danger
  Info
  Neutral
}

pub type ColorShade {
  Light
  Normal
  Dark
}

/// Get CSS custom property name for color
pub fn color_css_var(color: Color, shade: ColorShade) -> String

/// Spacing scale (0-16)
pub fn spacing(scale: Int) -> String

/// Typography scale
pub type TextSize {
  Xs
  Sm
  Base
  Lg
  Xl
  Xxl
  Xxxl
  Xxxxl
  Xxxxxl
}

pub type FontWeight {
  Normal
  Medium
  Semibold
  Bold
}

pub fn text_style(size: TextSize, weight: FontWeight) -> String

/// Border radius variants
pub type BorderRadius {
  None
  Sm
  Md
  Lg
  Xl
  Full
}

pub fn border_radius_css(radius: BorderRadius) -> String

/// Shadow variants
pub type ShadowSize {
  Sm
  Md
  Lg
  Xl
}

pub fn shadow_css(size: ShadowSize) -> String
```

---

## Type Imports

All components use standard types from existing modules:

```gleam
// From shared/types.gleam
pub type Recipe
pub type UserProfile
pub type Macros
pub type MealType
pub type DailyLog
pub type FoodLogEntry

// From meal_planner/storage.gleam
pub type UsdaFood {
  UsdaFood(
    fdc_id: Int,
    description: String,
    data_type: String,
    category: String,
  )
}

pub type FoodNutrientValue {
  FoodNutrientValue(
    nutrient_name: String,
    amount: Float,
    unit: String,
  )
}

// From lustre
pub type element.Element(msg)
pub type attribute.Attribute(msg)
pub type html
```

---

## Signature Patterns

All components follow these patterns:

### Pattern 1: Simple Component

```gleam
pub fn button(label: String, href: String) -> element.Element(msg) {
  html.a([attribute.href(href), attribute.class("btn")], [
    element.text(label)
  ])
}
```

### Pattern 2: Component with Variant

```gleam
pub fn button(
  label: String,
  href: String,
  variant: ButtonVariant,
) -> element.Element(msg) {
  html.a([
    attribute.href(href),
    attribute.class("btn " <> variant_to_class(variant)),
  ], [element.text(label)])
}

fn variant_to_class(variant: ButtonVariant) -> String {
  case variant {
    Primary -> "btn-primary"
    Secondary -> "btn-secondary"
    // ...
  }
}
```

### Pattern 3: Component with Complex Data

```gleam
pub type StatCard {
  StatCard(label: String, value: String, unit: String)
}

pub fn stat_card(stat: StatCard) -> element.Element(msg) {
  html.div([attribute.class("stat-card")], [
    html.span([], [element.text(stat.value)]),
    html.span([], [element.text(stat.unit)]),
    html.span([], [element.text(stat.label)]),
  ])
}
```

### Pattern 4: Page Component (Composition)

```gleam
pub type PageData {
  PageData(title: String, content: List(element.Element(msg)))
}

pub fn render_page(data: PageData) -> element.Element(msg) {
  html.div([], [
    page_header(data.title),
    html.div([attribute.class("content")], data.content),
    page_footer(),
  ])
}
```

---

## Component Hierarchy Example

How components compose together:

```gleam
// Atomic level
stat_card(StatCard("Calories", "2100", "kcal"))

// Feature level (composed from atomic)
calorie_summary(daily_log, targets)
  |> calls stat_card() internally

// Page level (composed from feature)
render_dashboard(data)
  |> calls calorie_summary()
  |> calls macro_progress_section()
  |> etc.
```

---

**Document Generated**: 2025-12-03
**Status**: Reference Guide
