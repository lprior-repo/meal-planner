/// Example usage of the OpenAPI generator
///
/// This module demonstrates how to use the OpenAPI generator to create
/// and export API specifications in different formats.
import gleam/dict
import gleam/int
import gleam/io
import gleam/json
import gleam/option.{None}
import gleam/string
import meal_planner/openapi/generator

pub fn main() {
  io.println("=== OpenAPI Generator Example ===\n")

  // Generate the specification
  io.println("1. Generating OpenAPI specification...")
  let spec = generator.generate()

  // Show basic info
  io.println("2. Specification details:")
  io.println("   - OpenAPI version: " <> spec.openapi)
  io.println("   - API title: " <> spec.info.title)
  io.println("   - API version: " <> spec.info.version)

  // Convert to JSON
  io.println("\n3. Converting to JSON...")
  let json_spec = generator.to_json(spec)
  let json_string = json.to_string(json_spec)
  io.println(
    "   JSON output length: "
    <> int.to_string(string.length(json_string))
    <> " characters",
  )

  // Convert to YAML
  io.println("\n4. Converting to YAML...")
  let yaml_spec = generator.to_yaml(spec)
  io.println(
    "   YAML output length: "
    <> int.to_string(string.length(yaml_spec))
    <> " characters",
  )

  // Show YAML preview (first 500 characters)
  io.println("\n5. YAML Preview (first 500 chars):")
  io.println("---")
  yaml_spec
  |> string.slice(0, 500)
  |> io.println
  io.println("...")

  io.println("\n✓ Generation complete!")
}

// Additional helper functions for custom specifications

/// Create a minimal OpenAPI spec for testing
pub fn minimal_spec() -> generator.OpenApiSpec {
  generator.OpenApiSpec(
    openapi: "3.1.0",
    info: generator.Info(
      title: "Minimal API",
      description: "A minimal example API",
      version: "0.1.0",
      contact: None,
      license: None,
    ),
    servers: [],
    tags: [],
    paths: dict.new(),
    components: None,
  )
}
