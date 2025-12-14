import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/types/recipe/recipe.{Recipe}

pub fn recipe_full_constructor_test() {
  let recipe =
    Recipe(
      id: 1,
      name: "Pasta Carbonara",
      description: "Classic Italian pasta",
      image: Some("carbonara.jpg"),
      servings: 4,
      keywords: ["italian", "pasta"],
      working_time: 15,
      waiting_time: 10,
      source_url: Some("https://example.com/recipe"),
      internal: False,
      nutrition: Some("calories: 450"),
      steps: ["Boil water", "Cook pasta", "Mix eggs"],
      created_by: 1,
      created_at: "2025-12-01T10:00:00Z",
      updated_at: "2025-12-10T12:00:00Z",
    )

  recipe.id
  |> should.equal(1)

  recipe.name
  |> should.equal("Pasta Carbonara")

  recipe.description
  |> should.equal("Classic Italian pasta")

  recipe.servings
  |> should.equal(4)

  recipe.working_time
  |> should.equal(15)

  recipe.waiting_time
  |> should.equal(10)

  recipe.internal
  |> should.equal(False)
}

pub fn recipe_minimal_test() {
  let recipe =
    Recipe(
      id: 2,
      name: "Quick Salad",
      description: "Simple salad",
      image: None,
      servings: 2,
      keywords: [],
      working_time: 5,
      waiting_time: 0,
      source_url: None,
      internal: True,
      nutrition: None,
      steps: [],
      created_by: 2,
      created_at: "2025-12-14T00:00:00Z",
      updated_at: "2025-12-14T00:00:00Z",
    )

  recipe.id
  |> should.equal(2)

  recipe.name
  |> should.equal("Quick Salad")

  recipe.image
  |> should.equal(None)

  recipe.source_url
  |> should.equal(None)

  recipe.nutrition
  |> should.equal(None)

  recipe.keywords
  |> should.equal([])

  recipe.steps
  |> should.equal([])
}

pub fn recipe_optional_fields_test() {
  let recipe =
    Recipe(
      id: 3,
      name: "Test Recipe",
      description: "Testing optional fields",
      image: Some("test.jpg"),
      servings: 1,
      keywords: ["test"],
      working_time: 0,
      waiting_time: 0,
      source_url: None,
      internal: True,
      nutrition: Some("nutrition info"),
      steps: ["step1"],
      created_by: 3,
      created_at: "2025-01-01T00:00:00Z",
      updated_at: "2025-01-01T00:00:00Z",
    )

  should.equal(recipe.image, Some("test.jpg"))
  should.equal(recipe.source_url, None)
  should.equal(recipe.nutrition, Some("nutrition info"))
}

pub fn recipe_timestamps_test() {
  let created = "2025-12-01T10:00:00Z"
  let updated = "2025-12-14T12:00:00Z"

  let recipe =
    Recipe(
      id: 4,
      name: "Time Test",
      description: "Testing timestamps",
      image: None,
      servings: 1,
      keywords: [],
      working_time: 0,
      waiting_time: 0,
      source_url: None,
      internal: False,
      nutrition: None,
      steps: [],
      created_by: 1,
      created_at: created,
      updated_at: updated,
    )

  should.equal(recipe.created_at, created)
  should.equal(recipe.updated_at, updated)
}
