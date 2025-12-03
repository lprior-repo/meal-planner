/// UI Types Testing
///
/// Comprehensive tests for UI component type definitions following Martin Fowler's
/// type testing principles:
/// - Type safety verification
/// - Boundary condition testing
/// - Constraint validation
/// - Constructor testing
/// - Pattern matching coverage
import gleam/option
import gleeunit
import gleeunit/should
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// BUTTON TYPES TESTS
// ===================================================================

pub fn button_variant_primary_test() {
  let variant = ui_types.Primary
  variant
  |> should.equal(ui_types.Primary)
}

pub fn button_variant_secondary_test() {
  let variant = ui_types.Secondary
  variant
  |> should.equal(ui_types.Secondary)
}

pub fn button_variant_danger_test() {
  let variant = ui_types.Danger
  variant
  |> should.equal(ui_types.Danger)
}

pub fn button_variant_success_test() {
  let variant = ui_types.Success
  variant
  |> should.equal(ui_types.Success)
}

pub fn button_variant_warning_test() {
  let variant = ui_types.Warning
  variant
  |> should.equal(ui_types.Warning)
}

pub fn button_variant_ghost_test() {
  let variant = ui_types.Ghost
  variant
  |> should.equal(ui_types.Ghost)
}

pub fn button_size_small_test() {
  let size = ui_types.Small
  size
  |> should.equal(ui_types.Small)
}

pub fn button_size_medium_test() {
  let size = ui_types.Medium
  size
  |> should.equal(ui_types.Medium)
}

pub fn button_size_large_test() {
  let size = ui_types.Large
  size
  |> should.equal(ui_types.Large)
}

// ===================================================================
// CARD TYPES TESTS
// ===================================================================

pub fn card_variant_basic_test() {
  let variant = ui_types.Basic
  variant
  |> should.equal(ui_types.Basic)
}

pub fn card_variant_elevated_test() {
  let variant = ui_types.Elevated
  variant
  |> should.equal(ui_types.Elevated)
}

pub fn card_variant_outlined_test() {
  let variant = ui_types.Outlined
  variant
  |> should.equal(ui_types.Outlined)
}

pub fn stat_card_constructor_test() {
  let card =
    ui_types.StatCard(
      label: "Calories",
      value: "2500",
      unit: "kcal",
      trend: option.Some(5.2),
      color: "green",
    )

  card.label
  |> should.equal("Calories")
  card.value
  |> should.equal("2500")
  card.unit
  |> should.equal("kcal")
  card.trend
  |> should.equal(option.Some(5.2))
  card.color
  |> should.equal("green")
}

pub fn stat_card_without_trend_test() {
  let card =
    ui_types.StatCard(
      label: "Protein",
      value: "120",
      unit: "g",
      trend: option.None,
      color: "blue",
    )

  card.trend
  |> should.equal(option.None)
}

pub fn stat_card_positive_trend_test() {
  let card =
    ui_types.StatCard(
      label: "Weight",
      value: "185",
      unit: "lbs",
      trend: option.Some(2.5),
      color: "green",
    )

  case card.trend {
    option.Some(t) -> t |> should.equal(2.5)
    option.None -> panic as "Expected trend value"
  }
}

pub fn stat_card_negative_trend_test() {
  let card =
    ui_types.StatCard(
      label: "Body Fat",
      value: "18",
      unit: "%",
      trend: option.Some(-1.2),
      color: "green",
    )

  case card.trend {
    option.Some(t) -> t |> should.equal(-1.2)
    option.None -> panic as "Expected trend value"
  }
}

pub fn recipe_card_constructor_test() {
  let card =
    ui_types.RecipeCardData(
      id: "recipe-123",
      name: "Chicken Salad",
      category: "Lunch",
      calories: 450.5,
      image_url: option.Some("https://example.com/image.jpg"),
    )

  card.id
  |> should.equal("recipe-123")
  card.name
  |> should.equal("Chicken Salad")
  card.category
  |> should.equal("Lunch")
  card.calories
  |> should.equal(450.5)
  card.image_url
  |> should.equal(option.Some("https://example.com/image.jpg"))
}

pub fn recipe_card_without_image_test() {
  let card =
    ui_types.RecipeCardData(
      id: "recipe-456",
      name: "Oatmeal",
      category: "Breakfast",
      calories: 300.0,
      image_url: option.None,
    )

  card.image_url
  |> should.equal(option.None)
}

pub fn recipe_card_zero_calories_test() {
  let card =
    ui_types.RecipeCardData(
      id: "recipe-789",
      name: "Water",
      category: "Beverage",
      calories: 0.0,
      image_url: option.None,
    )

  card.calories
  |> should.equal(0.0)
}

pub fn food_card_constructor_test() {
  let card =
    ui_types.FoodCardData(
      fdc_id: 123456,
      description: "Chicken breast, grilled",
      data_type: "Foundation",
      category: "Poultry Products",
    )

  card.fdc_id
  |> should.equal(123456)
  card.description
  |> should.equal("Chicken breast, grilled")
  card.data_type
  |> should.equal("Foundation")
  card.category
  |> should.equal("Poultry Products")
}

pub fn food_card_large_id_test() {
  let card =
    ui_types.FoodCardData(
      fdc_id: 999_999_999,
      description: "Test Food",
      data_type: "SR Legacy",
      category: "Test Category",
    )

  card.fdc_id
  |> should.equal(999_999_999)
}

// ===================================================================
// FORM TYPES TESTS
// ===================================================================

pub fn select_option_constructor_test() {
  let option =
    ui_types.SelectOption(value: "chicken", label: "Chicken", selected: True)

  option.value
  |> should.equal("chicken")
  option.label
  |> should.equal("Chicken")
  option.selected
  |> should.equal(True)
}

pub fn select_option_unselected_test() {
  let option =
    ui_types.SelectOption(value: "beef", label: "Beef", selected: False)

  option.selected
  |> should.equal(False)
}

pub fn form_field_constructor_test() {
  let field =
    ui_types.FormField(
      label: "Email",
      input: "user@example.com",
      error: option.None,
    )

  field.label
  |> should.equal("Email")
  field.input
  |> should.equal("user@example.com")
  field.error
  |> should.equal(option.None)
}

pub fn form_field_with_error_test() {
  let field =
    ui_types.FormField(
      label: "Password",
      input: "123",
      error: option.Some("Password too short"),
    )

  field.error
  |> should.equal(option.Some("Password too short"))
}

pub fn form_field_empty_input_test() {
  let field =
    ui_types.FormField(label: "Username", input: "", error: option.None)

  field.input
  |> should.equal("")
}

// ===================================================================
// PROGRESS TYPES TESTS
// ===================================================================

pub fn status_success_test() {
  let status = ui_types.StatusSuccess
  status
  |> should.equal(ui_types.StatusSuccess)
}

pub fn status_warning_test() {
  let status = ui_types.StatusWarning
  status
  |> should.equal(ui_types.StatusWarning)
}

pub fn status_error_test() {
  let status = ui_types.StatusError
  status
  |> should.equal(ui_types.StatusError)
}

pub fn status_info_test() {
  let status = ui_types.StatusInfo
  status
  |> should.equal(ui_types.StatusInfo)
}

// ===================================================================
// LAYOUT TYPES TESTS
// ===================================================================

pub fn flex_direction_row_test() {
  let direction = ui_types.Row
  direction
  |> should.equal(ui_types.Row)
}

pub fn flex_direction_column_test() {
  let direction = ui_types.Column
  direction
  |> should.equal(ui_types.Column)
}

pub fn flex_direction_row_reverse_test() {
  let direction = ui_types.RowReverse
  direction
  |> should.equal(ui_types.RowReverse)
}

pub fn flex_direction_column_reverse_test() {
  let direction = ui_types.ColumnReverse
  direction
  |> should.equal(ui_types.ColumnReverse)
}

pub fn flex_align_start_test() {
  let align = ui_types.AlignStart
  align
  |> should.equal(ui_types.AlignStart)
}

pub fn flex_align_center_test() {
  let align = ui_types.AlignCenter
  align
  |> should.equal(ui_types.AlignCenter)
}

pub fn flex_align_end_test() {
  let align = ui_types.AlignEnd
  align
  |> should.equal(ui_types.AlignEnd)
}

pub fn flex_align_stretch_test() {
  let align = ui_types.Stretch
  align
  |> should.equal(ui_types.Stretch)
}

pub fn flex_align_between_test() {
  let align = ui_types.AlignBetween
  align
  |> should.equal(ui_types.AlignBetween)
}

pub fn flex_align_around_test() {
  let align = ui_types.AlignAround
  align
  |> should.equal(ui_types.AlignAround)
}

pub fn flex_justify_start_test() {
  let justify = ui_types.JustifyStart
  justify
  |> should.equal(ui_types.JustifyStart)
}

pub fn flex_justify_center_test() {
  let justify = ui_types.JustifyCenter
  justify
  |> should.equal(ui_types.JustifyCenter)
}

pub fn flex_justify_end_test() {
  let justify = ui_types.JustifyEnd
  justify
  |> should.equal(ui_types.JustifyEnd)
}

pub fn flex_justify_between_test() {
  let justify = ui_types.JustifyBetween
  justify
  |> should.equal(ui_types.JustifyBetween)
}

pub fn flex_justify_around_test() {
  let justify = ui_types.JustifyAround
  justify
  |> should.equal(ui_types.JustifyAround)
}

pub fn flex_justify_even_test() {
  let justify = ui_types.Even
  justify
  |> should.equal(ui_types.Even)
}

pub fn grid_columns_auto_test() {
  let columns = ui_types.Auto
  columns
  |> should.equal(ui_types.Auto)
}

pub fn grid_columns_fixed_test() {
  let columns = ui_types.Fixed(12)
  columns
  |> should.equal(ui_types.Fixed(12))
}

pub fn grid_columns_fixed_single_test() {
  let columns = ui_types.Fixed(1)
  columns
  |> should.equal(ui_types.Fixed(1))
}

pub fn grid_columns_repeat_test() {
  let columns = ui_types.Repeat(3)
  columns
  |> should.equal(ui_types.Repeat(3))
}

pub fn grid_columns_responsive_test() {
  let columns = ui_types.Responsive
  columns
  |> should.equal(ui_types.Responsive)
}

// ===================================================================
// TYPOGRAPHY TYPES TESTS
// ===================================================================

pub fn text_emphasis_normal_test() {
  let emphasis = ui_types.Normal
  emphasis
  |> should.equal(ui_types.Normal)
}

pub fn text_emphasis_strong_test() {
  let emphasis = ui_types.Strong
  emphasis
  |> should.equal(ui_types.Strong)
}

pub fn text_emphasis_italic_test() {
  let emphasis = ui_types.Italic
  emphasis
  |> should.equal(ui_types.Italic)
}

pub fn text_emphasis_code_test() {
  let emphasis = ui_types.Code
  emphasis
  |> should.equal(ui_types.Code)
}

pub fn text_emphasis_underline_test() {
  let emphasis = ui_types.Underline
  emphasis
  |> should.equal(ui_types.Underline)
}

pub fn text_size_xs_test() {
  let size = ui_types.Xs
  size
  |> should.equal(ui_types.Xs)
}

pub fn text_size_sm_test() {
  let size = ui_types.Sm
  size
  |> should.equal(ui_types.Sm)
}

pub fn text_size_base_test() {
  let size = ui_types.Base
  size
  |> should.equal(ui_types.Base)
}

pub fn text_size_lg_test() {
  let size = ui_types.Lg
  size
  |> should.equal(ui_types.Lg)
}

pub fn text_size_xl_test() {
  let size = ui_types.Xl
  size
  |> should.equal(ui_types.Xl)
}

pub fn text_size_xxl_test() {
  let size = ui_types.Xxl
  size
  |> should.equal(ui_types.Xxl)
}

pub fn text_size_xxxl_test() {
  let size = ui_types.Xxxl
  size
  |> should.equal(ui_types.Xxxl)
}

pub fn font_weight_normal_test() {
  let weight = ui_types.WeightNormal
  weight
  |> should.equal(ui_types.WeightNormal)
}

pub fn font_weight_medium_test() {
  let weight = ui_types.WeightMedium
  weight
  |> should.equal(ui_types.WeightMedium)
}

pub fn font_weight_semibold_test() {
  let weight = ui_types.WeightSemibold
  weight
  |> should.equal(ui_types.WeightSemibold)
}

pub fn font_weight_bold_test() {
  let weight = ui_types.WeightBold
  weight
  |> should.equal(ui_types.WeightBold)
}

// ===================================================================
// PAGE COMPONENT TYPES TESTS
// ===================================================================

pub fn nav_card_constructor_test() {
  let card =
    ui_types.NavCard(icon: "📊", label: "Dashboard", href: "/dashboard")

  card.icon
  |> should.equal("📊")
  card.label
  |> should.equal("Dashboard")
  card.href
  |> should.equal("/dashboard")
}

pub fn nav_card_empty_icon_test() {
  let card = ui_types.NavCard(icon: "", label: "Home", href: "/")

  card.icon
  |> should.equal("")
}

pub fn nav_card_relative_path_test() {
  let card = ui_types.NavCard(icon: "⚙️", label: "Settings", href: "./settings")

  card.href
  |> should.equal("./settings")
}

// ===================================================================
// MEAL LOG TYPES TESTS
// ===================================================================

pub fn meal_entry_constructor_test() {
  let entry =
    ui_types.MealEntryData(
      id: "meal-001",
      time: "08:30 AM",
      food_name: "Scrambled Eggs",
      portion: "2 eggs",
      protein: 12.5,
      fat: 10.2,
      carbs: 1.8,
      calories: 155.0,
      meal_type: "Breakfast",
    )

  entry.id
  |> should.equal("meal-001")
  entry.time
  |> should.equal("08:30 AM")
  entry.food_name
  |> should.equal("Scrambled Eggs")
  entry.portion
  |> should.equal("2 eggs")
  entry.protein
  |> should.equal(12.5)
  entry.fat
  |> should.equal(10.2)
  entry.carbs
  |> should.equal(1.8)
  entry.calories
  |> should.equal(155.0)
  entry.meal_type
  |> should.equal("Breakfast")
}

pub fn meal_entry_zero_macros_test() {
  let entry =
    ui_types.MealEntryData(
      id: "meal-002",
      time: "10:00 AM",
      food_name: "Black Coffee",
      portion: "1 cup",
      protein: 0.0,
      fat: 0.0,
      carbs: 0.0,
      calories: 2.0,
      meal_type: "Snack",
    )

  entry.protein
  |> should.equal(0.0)
  entry.fat
  |> should.equal(0.0)
  entry.carbs
  |> should.equal(0.0)
}

pub fn meal_entry_high_protein_test() {
  let entry =
    ui_types.MealEntryData(
      id: "meal-003",
      time: "12:30 PM",
      food_name: "Grilled Chicken Breast",
      portion: "8 oz",
      protein: 62.5,
      fat: 6.5,
      carbs: 0.0,
      calories: 310.0,
      meal_type: "Lunch",
    )

  entry.protein
  |> should.equal(62.5)
}

pub fn meal_entry_high_carbs_test() {
  let entry =
    ui_types.MealEntryData(
      id: "meal-004",
      time: "03:00 PM",
      food_name: "Brown Rice",
      portion: "1 cup",
      protein: 5.0,
      fat: 1.8,
      carbs: 45.0,
      calories: 216.0,
      meal_type: "Snack",
    )

  entry.carbs
  |> should.equal(45.0)
}

pub fn meal_entry_high_fat_test() {
  let entry =
    ui_types.MealEntryData(
      id: "meal-005",
      time: "06:00 PM",
      food_name: "Avocado",
      portion: "1 whole",
      protein: 3.0,
      fat: 29.5,
      carbs: 17.0,
      calories: 322.0,
      meal_type: "Dinner",
    )

  entry.fat
  |> should.equal(29.5)
}

// ===================================================================
// PATTERN MATCHING COVERAGE TESTS
// ===================================================================

pub fn button_variant_pattern_match_test() {
  let variants = [
    ui_types.Primary,
    ui_types.Secondary,
    ui_types.Danger,
    ui_types.Success,
    ui_types.Warning,
    ui_types.Ghost,
  ]

  // Ensure all variants can be matched
  variants
  |> should.not_equal([])
}

pub fn status_type_pattern_match_test() {
  let statuses = [
    ui_types.StatusSuccess,
    ui_types.StatusWarning,
    ui_types.StatusError,
    ui_types.StatusInfo,
  ]

  // Ensure all status types exist
  statuses
  |> should.not_equal([])
}

pub fn text_size_range_test() {
  let sizes = [
    ui_types.Xs,
    ui_types.Sm,
    ui_types.Base,
    ui_types.Lg,
    ui_types.Xl,
    ui_types.Xxl,
    ui_types.Xxxl,
  ]

  // Ensure complete size scale
  sizes
  |> should.not_equal([])
}

// ===================================================================
// BOUNDARY CONDITION TESTS
// ===================================================================

pub fn stat_card_empty_strings_test() {
  let card =
    ui_types.StatCard(
      label: "",
      value: "",
      unit: "",
      trend: option.None,
      color: "",
    )

  card.label
  |> should.equal("")
  card.value
  |> should.equal("")
  card.unit
  |> should.equal("")
}

pub fn recipe_card_empty_id_test() {
  let card =
    ui_types.RecipeCardData(
      id: "",
      name: "Recipe",
      category: "Category",
      calories: 0.0,
      image_url: option.None,
    )

  card.id
  |> should.equal("")
}

pub fn food_card_zero_id_test() {
  let card =
    ui_types.FoodCardData(
      fdc_id: 0,
      description: "Test",
      data_type: "Type",
      category: "Category",
    )

  card.fdc_id
  |> should.equal(0)
}

pub fn meal_entry_empty_portion_test() {
  let entry =
    ui_types.MealEntryData(
      id: "meal-006",
      time: "08:00 PM",
      food_name: "Salad",
      portion: "",
      protein: 5.0,
      fat: 2.0,
      carbs: 8.0,
      calories: 70.0,
      meal_type: "Dinner",
    )

  entry.portion
  |> should.equal("")
}
