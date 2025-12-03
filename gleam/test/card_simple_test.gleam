import gleam/string
import meal_planner/ui/components/card
import meal_planner/ui/types/ui_types
import gleam/option
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn card_basic_test() {
  let result = card.card([])
  result
  |> should.contain("class=\"card\"")
}

pub fn card_with_content_test() {
  let result = card.card(["<p>Hello</p>"])
  result
  |> should.contain("Hello")
}

pub fn card_with_header_basic_test() {
  let result = card.card_with_header("Title", [])
  result
  |> should.contain("card-header")
  |> should.contain("Title")
}

pub fn stat_card_basic_test() {
  let stat = ui_types.StatCard(
    label: "Calories",
    value: "2100",
    unit: "kcal",
    trend: option.None,
    color: "primary",
  )
  card.stat_card(stat)
  |> should.contain("2100")
}

pub fn recipe_card_basic_test() {
  let recipe = ui_types.RecipeCardData(
    id: "123",
    name: "Chicken",
    category: "Main",
    calories: 450.0,
    image_url: option.None,
  )
  card.recipe_card(recipe)
  |> should.contain("Chicken")
}

pub fn food_card_basic_test() {
  let food = ui_types.FoodCardData(
    fdc_id: 12345,
    description: "Chicken, raw",
    data_type: "SR Legacy",
    category: "Poultry",
  )
  card.food_card(food)
  |> should.contain("Chicken, raw")
}
