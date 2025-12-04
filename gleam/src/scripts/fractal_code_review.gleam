/// Fractal code review module for automated code quality checks
/// Implements type safety validation for Gleam code
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import simplifile

/// Check if all function parameters and return types are explicitly typed
/// Returns True if all functions have proper type annotations, False otherwise
pub fn check_type_safety(code: String) -> Bool {
  // Remove comments and empty lines for cleaner analysis
  let cleaned_code = clean_code(code)

  // Find all function definitions
  let function_patterns = extract_functions(cleaned_code)

  // If no functions found, consider it safe (empty or comments-only code)
  case function_patterns {
    [] -> True
    functions -> list.all(functions, is_function_typed)
  }
}

/// Remove comments and clean up code for analysis
fn clean_code(code: String) -> String {
  code
  |> string.split("\n")
  |> list.filter(fn(line) {
    let trimmed = string.trim(line)
    // Keep lines that aren't just comments
    !string.starts_with(trimmed, "///")
    && !string.starts_with(trimmed, "//")
    && trimmed != ""
  })
  |> string.join("\n")
}

/// Extract function definitions from code
fn extract_functions(code: String) -> List(String) {
  // Pattern matches: pub fn, fn, @external
  let lines = string.split(code, "\n")

  list.filter_map(lines, fn(line) {
    let trimmed = string.trim(line)
    case
      string.starts_with(trimmed, "pub fn ")
      || string.starts_with(trimmed, "fn ")
      || string.starts_with(trimmed, "@external")
    {
      True -> Ok(trimmed)
      False -> Error(Nil)
    }
  })
}

/// Check if a function definition has proper type annotations
fn is_function_typed(func_def: String) -> Bool {
  // External functions always have types
  case string.starts_with(func_def, "@external") {
    True -> True
    False -> {
      // Check for parameter types and return type
      has_parameter_types(func_def) && has_return_type(func_def)
    }
  }
}

/// Check if function has typed parameters
fn has_parameter_types(func_def: String) -> Bool {
  // Extract the parameter section between ( and )
  case extract_params_section(func_def) {
    Error(_) -> False
    Ok(params_section) -> {
      // Empty params are ok
      case string.trim(params_section) {
        "" -> True
        _ -> validate_params_typed(params_section)
      }
    }
  }
}

/// Extract the parameters section from function definition
fn extract_params_section(func_def: String) -> Result(String, Nil) {
  // Find the section between first ( and matching )
  case string.split_once(func_def, "(") {
    Error(_) -> Error(Nil)
    Ok(#(_, after_paren)) -> {
      case string.split_once(after_paren, ")") {
        Error(_) -> Error(Nil)
        Ok(#(params, _)) -> Ok(params)
      }
    }
  }
}

/// Validate that all parameters have type annotations
fn validate_params_typed(params: String) -> Bool {
  // Split by comma to get individual parameters
  let param_list =
    params
    |> string.split(",")
    |> list.map(string.trim)
    |> list.filter(fn(p) { p != "" })

  // Each parameter must contain a colon (indicating type annotation)
  list.all(param_list, fn(param) {
    string.contains(param, ":")
  })
}

/// Check if function has return type annotation
fn has_return_type(func_def: String) -> Bool {
  // Look for -> which indicates return type
  string.contains(func_def, "->")
}

/// Calculate test coverage percentage for a given file
/// Returns a Float between 0.0 (no coverage) and 1.0 (full coverage)
///
/// Coverage is calculated as: (number of tested functions) / (total public functions)
pub fn check_coverage(file_path: String) -> Float {
  // Read the source file
  case simplifile.read(file_path) {
    Error(_) -> 0.0
    Ok(source_code) -> {
      // Extract public functions from source
      let public_functions = extract_public_functions(source_code)

      case list.length(public_functions) {
        0 -> 1.0
        total_functions -> {
          // Find corresponding test file
          let test_file_path = get_test_file_path(file_path)

          case simplifile.read(test_file_path) {
            Error(_) -> 0.0
            Ok(test_code) -> {
              // Count how many functions have tests
              let tested_count =
                list.filter(public_functions, fn(func_name) {
                  has_test_for_function(test_code, func_name)
                })
                |> list.length()

              // Calculate coverage ratio
              int.to_float(tested_count) /. int.to_float(total_functions)
            }
          }
        }
      }
    }
  }
}

/// Extract public function names from source code
fn extract_public_functions(code: String) -> List(String) {
  code
  |> string.split("\n")
  |> list.filter_map(fn(line) {
    let trimmed = string.trim(line)
    case string.starts_with(trimmed, "pub fn ") {
      True -> {
        // Extract function name between "pub fn " and "("
        trimmed
        |> string.drop_start(7)
        |> string.split_once("(")
        |> result.map(fn(parts) { parts.0 })
      }
      False -> Error(Nil)
    }
  })
}

/// Convert source file path to test file path
/// Example: gleam/src/meal_planner/web.gleam -> gleam/test/meal_planner/web_test.gleam
fn get_test_file_path(source_path: String) -> String {
  source_path
  |> string.replace("src/", "test/")
  |> string.replace(".gleam", "_test.gleam")
}

/// Check if test file contains a test for the given function
fn has_test_for_function(test_code: String, func_name: String) -> Bool {
  // Look for test functions that reference the function name
  // Common patterns: func_name_test, test_func_name, or contains func_name in test
  let test_pattern = func_name <> "_test"
  string.contains(test_code, test_pattern)
    || string.contains(test_code, func_name)
}
