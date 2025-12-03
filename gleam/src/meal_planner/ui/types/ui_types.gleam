/// UI Component Type Definitions
///
/// This module defines all type signatures for UI components used throughout
/// the meal planner application. These types ensure type safety when building
/// and composing components.
///
/// See: docs/component_signatures.md
import gleam/option

// ===================================================================
// BUTTON TYPES
// ===================================================================

pub type ButtonVariant {
  Primary
  Secondary
  Danger
  Success
  Warning
  Ghost
}

pub type ButtonSize {
  Small
  Medium
  Large
}

// ===================================================================
// CARD TYPES
// ===================================================================

pub type CardVariant {
  Basic
  Elevated
  Outlined
}

pub type StatCard {
  StatCard(
    label: String,
    value: String,
    unit: String,
    trend: option.Option(Float),
    color: String,
  )
}

pub type RecipeCardData {
  RecipeCardData(
    id: String,
    name: String,
    category: String,
    calories: Float,
    image_url: option.Option(String),
  )
}

pub type FoodCardData {
  FoodCardData(
    fdc_id: Int,
    description: String,
    data_type: String,
    category: String,
  )
}

// ===================================================================
// FORM TYPES
// ===================================================================

pub type SelectOption {
  SelectOption(value: String, label: String, selected: Bool)
}

pub type FormField {
  FormField(label: String, input: String, error: option.Option(String))
}

// ===================================================================
// PROGRESS TYPES
// ===================================================================

pub type StatusType {
  StatusSuccess
  StatusWarning
  StatusError
  StatusInfo
}

// ===================================================================
// LAYOUT TYPES
// ===================================================================

pub type FlexDirection {
  Row
  Column
  RowReverse
  ColumnReverse
}

pub type FlexAlign {
  AlignStart
  AlignCenter
  AlignEnd
  Stretch
  AlignBetween
  AlignAround
}

pub type FlexJustify {
  JustifyStart
  JustifyCenter
  JustifyEnd
  JustifyBetween
  JustifyAround
  Even
}

pub type GridColumns {
  Auto
  Fixed(Int)
  Repeat(Int)
  Responsive
}

// ===================================================================
// TYPOGRAPHY TYPES
// ===================================================================

pub type TextEmphasis {
  Normal
  Strong
  Italic
  Code
  Underline
}

pub type TextSize {
  Xs
  Sm
  Base
  Lg
  Xl
  Xxl
  Xxxl
}

pub type FontWeight {
  WeightNormal
  WeightMedium
  WeightSemibold
  WeightBold
}

// ===================================================================
// PAGE COMPONENT TYPES
// ===================================================================

pub type NavCard {
  NavCard(icon: String, label: String, href: String)
}

// ===================================================================
// MEAL LOG TYPES
// ===================================================================

/// Meal entry for daily log display
pub type MealEntryData {
  MealEntryData(
    id: String,
    time: String,
    food_name: String,
    portion: String,
    protein: Float,
    fat: Float,
    carbs: Float,
    calories: Float,
    meal_type: String,
  )
}
// ===================================================================
// Additional types will be added as specific features are implemented
// ===================================================================
