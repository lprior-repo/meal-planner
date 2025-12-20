/// CLI tool for generating OpenAPI specification
///
/// This module provides a simple command-line interface for generating
/// and outputting the OpenAPI specification in JSON or YAML format.
///
/// Usage:
/// ```sh
/// gleam run -m meal_planner/openapi/cli json   # Output JSON
/// gleam run -m meal_planner/openapi/cli yaml   # Output YAML
/// gleam run -m meal_planner/openapi/cli        # Default: YAML
/// ```
import argv
import gleam/io
import gleam/json
import gleam/list
import meal_planner/openapi/generator

pub fn main() {
  case argv.load().arguments {
    ["json"] -> output_json()
    ["yaml"] -> output_yaml()
    [] -> output_yaml()
    _ -> {
      io.println("Usage: gleam run -m meal_planner/openapi/cli [json|yaml]")
      io.println("")
      io.println("Options:")
      io.println("  json    Output OpenAPI spec as JSON")
      io.println("  yaml    Output OpenAPI spec as YAML (default)")
    }
  }
}

fn output_json() {
  let spec = generator.generate()
  let json_output = generator.to_json(spec)

  json_output
  |> json.to_string
  |> io.println
}

fn output_yaml() {
  let spec = generator.generate()
  let yaml_output = generator.to_yaml(spec)

  io.println(yaml_output)
}
