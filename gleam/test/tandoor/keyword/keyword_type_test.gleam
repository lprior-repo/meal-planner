/// Tests for Tandoor Keyword type definition
///
/// This test suite validates the Keyword type structure and field access.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/types/keyword/keyword.{type Keyword, Keyword}

pub fn keyword_create_test() {
  let keyword =
    Keyword(
      id: 1,
      name: "vegetarian",
      label: "Vegetarian",
      description: "Vegetarian recipes",
      icon: Some("🥗"),
      parent: None,
      numchild: 0,
      created_at: "2024-01-01T00:00:00Z",
      updated_at: "2024-01-01T00:00:00Z",
      full_name: "Vegetarian",
    )

  keyword.id
  |> should.equal(1)

  keyword.name
  |> should.equal("vegetarian")

  keyword.label
  |> should.equal("Vegetarian")

  keyword.description
  |> should.equal("Vegetarian recipes")

  keyword.icon
  |> should.equal(Some("🥗"))

  keyword.parent
  |> should.equal(None)

  keyword.numchild
  |> should.equal(0)

  keyword.created_at
  |> should.equal("2024-01-01T00:00:00Z")

  keyword.updated_at
  |> should.equal("2024-01-01T00:00:00Z")

  keyword.full_name
  |> should.equal("Vegetarian")
}

pub fn keyword_with_parent_test() {
  let keyword =
    Keyword(
      id: 2,
      name: "vegan",
      label: "Vegan",
      description: "Vegan recipes",
      icon: None,
      parent: Some(1),
      numchild: 0,
      created_at: "2024-01-02T00:00:00Z",
      updated_at: "2024-01-02T00:00:00Z",
      full_name: "Vegetarian > Vegan",
    )

  keyword.parent
  |> should.equal(Some(1))

  keyword.full_name
  |> should.equal("Vegetarian > Vegan")
}

pub fn keyword_with_children_test() {
  let keyword =
    Keyword(
      id: 3,
      name: "cuisine",
      label: "Cuisine",
      description: "Cuisine types",
      icon: Some("🍽️"),
      parent: None,
      numchild: 5,
      created_at: "2024-01-03T00:00:00Z",
      updated_at: "2024-01-03T00:00:00Z",
      full_name: "Cuisine",
    )

  keyword.numchild
  |> should.equal(5)
}
