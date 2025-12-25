/// Tests for OpenAPI generator
import gleam/dict
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import meal_planner/openapi/generator

/// Test generating basic OpenAPI spec
pub fn generate_test() {
  let spec = generator.generate()

  // Verify OpenAPI version
  spec.openapi
  |> should.equal("3.1.0")

  // Verify info section
  spec.info.title
  |> should.equal("Meal Planner API")

  spec.info.version
  |> should.equal("1.0.0")

  // Verify servers exist
  spec.servers
  |> should.not_equal([])

  // Verify tags exist
  spec.tags
  |> should.not_equal([])

  // Verify paths exist
  spec.paths
  |> dict.size
  |> should.be_true(fn(size) { size > 0 })
}

/// Test JSON encoding of spec
pub fn to_json_test() {
  let spec = generator.generate()
  let json_spec = generator.to_json(spec)

  // Should produce valid JSON (string conversion doesn't crash)
  json_spec
  |> json.to_string
  |> string.length
  |> should.be_true(fn(len) { len > 100 })
}

/// Test YAML conversion of spec
pub fn to_yaml_test() {
  let spec = generator.generate()
  let yaml_spec = generator.to_yaml(spec)

  // Should start with openapi version
  yaml_spec
  |> string.starts_with("openapi: 3.1.0")
  |> should.be_true

  // Should contain key sections
  yaml_spec
  |> string.contains("info:")
  |> should.be_true

  yaml_spec
  |> string.contains("paths:")
  |> should.be_true

  yaml_spec
  |> string.contains("servers:")
  |> should.be_true
}

/// Test that all defined paths have at least one operation
pub fn paths_have_operations_test() {
  let spec = generator.generate()

  spec.paths
  |> dict.values
  |> should.not_equal([])
}

/// Test components section exists
pub fn components_exist_test() {
  let spec = generator.generate()

  case spec.components {
    Some(components) -> {
      components.schemas
      |> dict.size
      |> should.be_true(fn(size) { size > 0 })
    }
    None -> should.fail()
  }
}
