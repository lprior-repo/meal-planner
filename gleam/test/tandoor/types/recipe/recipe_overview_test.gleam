import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/types/recipe/recipe_overview.{RecipeOverview}

pub fn recipe_overview_constructor_test() {
  let recipe =
    RecipeOverview(
      id: 1,
      name: "Pasta Carbonara",
      description: "Classic Italian pasta dish",
      image: Some("carbonara.jpg"),
      keywords: ["italian", "pasta"],
      rating: Some(4.5),
      last_cooked: Some("2025-12-10"),
    )

  recipe.id
  |> should.equal(1)

  recipe.name
  |> should.equal("Pasta Carbonara")

  recipe.description
  |> should.equal("Classic Italian pasta dish")

  recipe.image
  |> should.equal(Some("carbonara.jpg"))

  recipe.keywords
  |> should.equal(["italian", "pasta"])

  recipe.rating
  |> should.equal(Some(4.5))

  recipe.last_cooked
  |> should.equal(Some("2025-12-10"))
}

pub fn recipe_overview_minimal_test() {
  let recipe =
    RecipeOverview(
      id: 2,
      name: "Simple Salad",
      description: "Quick and healthy",
      image: None,
      keywords: [],
      rating: None,
      last_cooked: None,
    )

  recipe.id
  |> should.equal(2)

  recipe.name
  |> should.equal("Simple Salad")

  recipe.image
  |> should.equal(None)

  recipe.keywords
  |> should.equal([])

  recipe.rating
  |> should.equal(None)

  recipe.last_cooked
  |> should.equal(None)
}

pub fn recipe_overview_empty_keywords_test() {
  let recipe =
    RecipeOverview(
      id: 3,
      name: "Test",
      description: "Test recipe",
      image: None,
      keywords: [],
      rating: Some(3.0),
      last_cooked: None,
    )

  recipe.keywords
  |> should.equal([])
}
