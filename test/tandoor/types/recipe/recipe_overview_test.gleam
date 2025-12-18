/// RED Phase Tests - RecipeOverview Type Alignment with Tandoor API spec
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/types/keyword/keyword_label.{
  type KeywordLabel, KeywordLabel,
}
import meal_planner/tandoor/types/mealplan/user.{type User, User}
import meal_planner/tandoor/types/recipe/recipe_overview.{
  type RecipeOverview, RecipeOverview,
}

pub fn main() {
  gleeunit.main()
}

/// Test: RecipeOverview has keyword field with KeywordLabel type
pub fn test_recipe_overview_keywords_are_keyword_labels() {
  let keyword1: KeywordLabel =
    KeywordLabel(id: 1, name: "protein", label: "High Protein")
  let keyword2: KeywordLabel =
    KeywordLabel(id: 2, name: "quick", label: "Quick & Easy")

  let creator: User =
    User(
      id: 1,
      username: "admin",
      first_name: "Admin",
      last_name: "User",
      display_name: "Admin User",
      is_staff: True,
      is_superuser: False,
      is_active: True,
    )

  let overview: RecipeOverview =
    RecipeOverview(
      id: 123,
      name: "Grilled Salmon",
      description: "Pan-seared salmon",
      image: Some("https://example.com/salmon.jpg"),
      keywords: [keyword1, keyword2],
      rating: Some(4.5),
      last_cooked: Some("2025-12-17T19:30:00Z"),
      working_time: 15,
      waiting_time: 0,
      created_by: creator,
      created_at: "2025-01-01T10:00:00Z",
      updated_at: "2025-12-18T08:00:00Z",
      internal: False,
      private: False,
      servings: 2,
      servings_text: "2 servings",
    )

  let keywords_count = list.length(overview.keywords)
  keywords_count |> should.equal(2)
}

/// Test: RecipeOverview has all readonly metadata fields
pub fn test_recipe_overview_has_readonly_metadata_fields() {
  let user: User =
    User(
      id: 1,
      username: "chef",
      first_name: "Chef",
      last_name: "Lewis",
      display_name: "Chef Lewis",
      is_staff: False,
      is_superuser: False,
      is_active: True,
    )

  let overview: RecipeOverview =
    RecipeOverview(
      id: 456,
      name: "Pasta Carbonara",
      description: "Classic Italian pasta",
      image: None,
      keywords: [],
      rating: None,
      last_cooked: None,
      working_time: 20,
      waiting_time: 5,
      created_by: user,
      created_at: "2025-01-15T14:30:00Z",
      updated_at: "2025-12-18T09:15:00Z",
      internal: False,
      private: False,
      servings: 4,
      servings_text: "4 servings",
    )

  overview.working_time |> should.equal(20)
  overview.waiting_time |> should.equal(5)
  overview.created_at |> should.equal("2025-01-15T14:30:00Z")
  overview.updated_at |> should.equal("2025-12-18T09:15:00Z")
  overview.internal |> should.equal(False)
  overview.servings |> should.equal(4)
  overview.servings_text |> should.equal("4 servings")
}

/// Test: RecipeOverview private and internal fields
pub fn test_recipe_overview_has_privacy_fields() {
  let user: User =
    User(
      id: 1,
      username: "chef",
      first_name: "Chef",
      last_name: "Lewis",
      display_name: "Chef Lewis",
      is_staff: False,
      is_superuser: False,
      is_active: True,
    )

  let public_recipe: RecipeOverview =
    RecipeOverview(
      id: 789,
      name: "Public Recipe",
      description: "Shared with everyone",
      image: None,
      keywords: [],
      rating: None,
      last_cooked: None,
      working_time: 10,
      waiting_time: 0,
      created_by: user,
      created_at: "2025-01-01T00:00:00Z",
      updated_at: "2025-01-01T00:00:00Z",
      internal: False,
      private: False,
      servings: 1,
      servings_text: "1 serving",
    )

  let private_recipe: RecipeOverview =
    RecipeOverview(
      id: 790,
      name: "Private Recipe",
      description: "Only for me",
      image: None,
      keywords: [],
      rating: None,
      last_cooked: None,
      working_time: 15,
      waiting_time: 0,
      created_by: user,
      created_at: "2025-01-01T00:00:00Z",
      updated_at: "2025-01-01T00:00:00Z",
      internal: False,
      private: True,
      servings: 2,
      servings_text: "2 servings",
    )

  public_recipe.private |> should.equal(False)
  private_recipe.private |> should.equal(True)
}
