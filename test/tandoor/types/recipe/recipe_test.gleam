import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/keyword/keyword.{Keyword}
import meal_planner/tandoor/types/mealplan/user.{User}
import meal_planner/tandoor/types/recipe/nutrition.{NutritionInfo}
import meal_planner/tandoor/types/recipe/recipe.{Recipe}
import meal_planner/tandoor/types/recipe/step.{Step}

pub fn recipe_full_constructor_test() {
  let recipe =
    Recipe(
      id: 1,
      name: "Pasta Carbonara",
      description: "Classic Italian pasta",
      image: Some("carbonara.jpg"),
      servings: 4,
      servings_text: "4 servings",
      keywords: [
        Keyword(
          id: 1,
          name: "italian",
          label: "Italian",
          description: "Italian cuisine",
          icon: None,
          parent: None,
          numchild: 0,
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-01T00:00:00Z",
          full_name: "Cuisine > Italian",
        ),
      ],
      working_time: 15,
      waiting_time: 10,
      source_url: Some("https://example.com/recipe"),
      internal: False,
      nutrition: Some(NutritionInfo(
        id: 1,
        carbohydrates: Some(45.0),
        fats: Some(12.0),
        proteins: Some(25.0),
        calories: Some(450.0),
        source: Some("USDA"),
      )),
      steps: [
        Step(
          id: ids.step_id_from_int(1),
          name: "Prep",
          instruction: "Boil water",
          instruction_markdown: None,
          ingredients: [],
          time: 5,
          order: 1,
          show_as_header: False,
          show_ingredients_table: True,
          file: None,
        ),
      ],
      created_by: User(
        id: 1,
        username: "testuser",
        first_name: "Test",
        last_name: "User",
        display_name: "Test User",
        is_staff: False,
        is_superuser: False,
        is_active: True,
      ),
      show_ingredient_overview: True,
      file_path: "/recipes/pasta-carbonara",
      private: False,
      properties: [],
      food_properties: [],
      rating: Some(4.5),
      last_cooked: Some("2025-12-10T12:00:00Z"),
      shared: [],
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
      servings_text: "2 servings",
      keywords: [],
      working_time: 5,
      waiting_time: 0,
      source_url: None,
      internal: True,
      nutrition: None,
      steps: [],
      created_by: User(
        id: 2,
        username: "user2",
        first_name: "User",
        last_name: "Two",
        display_name: "User Two",
        is_staff: False,
        is_superuser: False,
        is_active: True,
      ),
      show_ingredient_overview: False,
      file_path: "/recipes/salad",
      private: True,
      properties: [],
      food_properties: [],
      rating: None,
      last_cooked: None,
      shared: [],
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
      servings_text: "1 serving",
      keywords: [
        Keyword(
          id: 3,
          name: "test",
          label: "Test",
          description: "Test keyword",
          icon: None,
          parent: None,
          numchild: 0,
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-01T00:00:00Z",
          full_name: "Test",
        ),
      ],
      working_time: 0,
      waiting_time: 0,
      source_url: None,
      internal: True,
      nutrition: Some(NutritionInfo(
        id: 3,
        carbohydrates: None,
        fats: None,
        proteins: None,
        calories: None,
        source: None,
      )),
      steps: [
        Step(
          id: ids.step_id_from_int(3),
          name: "Step 1",
          instruction: "step1",
          instruction_markdown: None,
          ingredients: [],
          time: 0,
          order: 1,
          show_as_header: False,
          show_ingredients_table: True,
          file: None,
        ),
      ],
      created_by: User(
        id: 3,
        username: "user3",
        first_name: "User",
        last_name: "Three",
        display_name: "User Three",
        is_staff: False,
        is_superuser: False,
        is_active: True,
      ),
      show_ingredient_overview: True,
      file_path: "/recipes/test",
      private: False,
      properties: [],
      food_properties: [],
      rating: Some(3.5),
      last_cooked: Some("2025-01-01T00:00:00Z"),
      shared: [],
      created_at: "2025-01-01T00:00:00Z",
      updated_at: "2025-01-01T00:00:00Z",
    )

  should.equal(recipe.image, Some("test.jpg"))
  should.equal(recipe.source_url, None)
  should.equal(recipe.nutrition, Some(NutritionInfo(
    id: 3,
    carbohydrates: None,
    fats: None,
    proteins: None,
    calories: None,
    source: None,
  )))
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
      servings_text: "1 serving",
      keywords: [],
      working_time: 0,
      waiting_time: 0,
      source_url: None,
      internal: False,
      nutrition: None,
      steps: [],
      created_by: User(
        id: 1,
        username: "testuser",
        first_name: "Test",
        last_name: "User",
        display_name: "Test User",
        is_staff: False,
        is_superuser: False,
        is_active: True,
      ),
      show_ingredient_overview: False,
      file_path: "/recipes/time-test",
      private: False,
      properties: [],
      food_properties: [],
      rating: None,
      last_cooked: None,
      shared: [],
      created_at: created,
      updated_at: updated,
    )

  should.equal(recipe.created_at, created)
  should.equal(recipe.updated_at, updated)
}
