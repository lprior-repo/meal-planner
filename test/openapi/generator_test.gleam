import gleam/dict
import gleam/json
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/openapi/generator

pub fn main() {
  gleeunit.main()
}

pub fn generate_spec_test() {
  let spec = generator.generate()

  spec.openapi
  |> should.equal("3.1.0")

  spec.info.title
  |> should.equal("Meal Planner API")

  spec.info.version
  |> should.equal("1.0.0")
}

pub fn generate_has_paths_test() {
  let spec = generator.generate()

  dict.has_key(spec.paths, "/")
  |> should.be_true

  dict.has_key(spec.paths, "/health")
  |> should.be_true

  dict.has_key(spec.paths, "/api/nutrition/daily-status")
  |> should.be_true

  dict.has_key(spec.paths, "/api/ai/score-recipe")
  |> should.be_true
}

pub fn generate_has_tags_test() {
  let spec = generator.generate()

  spec.tags
  |> should.not_equal([])

  let tag_names =
    spec.tags
    |> list.map(fn(tag) { tag.name })

  tag_names
  |> should.contain("Health")

  tag_names
  |> should.contain("Nutrition Control")

  tag_names
  |> should.contain("Meal Planning")
}

pub fn to_json_test() {
  let spec = generator.generate()
  let json = generator.to_json(spec)

  // JSON should be a valid object
  json
  |> should.not_equal(json.null())
}

pub fn to_yaml_test() {
  let spec = generator.generate()
  let yaml = generator.to_yaml(spec)

  // Should start with openapi version
  yaml
  |> string.starts_with("openapi: 3.1.0")
  |> should.be_true

  // Should contain info section
  yaml
  |> string.contains("info:")
  |> should.be_true

  // Should contain paths section
  yaml
  |> string.contains("paths:")
  |> should.be_true

  // Should contain tags section
  yaml
  |> string.contains("tags:")
  |> should.be_true
}
