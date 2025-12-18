/// Fast Test Runner - Unit tests only, maximum parallelism
///
/// Skips integration tests that require external services
/// Uses EUnit's inparallel for maximum BEAM scheduler utilization
///
/// 100% Gleam implementation using BEAM FFI
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub fn main() {
  io.println("⚡ Fast Test Runner - Unit Tests Only")
  io.println("")

  let all_modules = discover_test_modules("test/**/*_test.gleam")
  let fast_modules = list.filter(all_modules, is_fast_test)
  let module_count = list.length(fast_modules)

  io.println(
    "Running "
    <> int.to_string(module_count)
    <> " fast test modules in parallel",
  )
  io.println("")

  case run_all_parallel(fast_modules) {
    Ok(count) -> {
      io.println("")
      io.println("✅ All " <> int.to_string(count) <> " test modules completed!")
      halt(0)
    }
    Error(msg) -> {
      io.println("")
      io.println("❌ Test failures: " <> msg)
      halt(1)
    }
  }
}

/// Filter out slow integration tests
fn is_fast_test(module_name: String) -> Bool {
  let slow_patterns = [
    "integration", "endpoint", "live", "http_integration", "ncp",
    "orchestration", "sync",
  ]

  list.all(slow_patterns, fn(pattern) { !string.contains(module_name, pattern) })
}

/// Discover test modules matching a glob pattern
fn discover_test_modules(pattern: String) -> List(String) {
  find_files(pattern)
  |> list.map(gleam_to_module_name)
}

/// Convert file path to Gleam module name
fn gleam_to_module_name(path: String) -> String {
  path
  |> string.replace(".gleam", "")
  |> string.replace("test/", "")
  |> string.replace("/", "@")
}

/// Run all tests in parallel using EUnit's inparallel
fn run_all_parallel(module_names: List(String)) -> Result(Int, String) {
  let atoms = list.map(module_names, string_to_atom)
  let tests = wrap_inparallel(atoms)
  let options = make_options()

  case run_eunit(tests, options) {
    Ok(_) -> Ok(list.length(module_names))
    Error(reason) -> Error(format_error(reason))
  }
}

// =============================================================================
// Erlang FFI - Direct calls to BEAM runtime
// =============================================================================

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

@external(erlang, "filelib", "wildcard")
fn find_files(pattern: String) -> List(String)

@external(erlang, "erlang", "binary_to_atom")
fn string_to_atom(name: String) -> Dynamic

@external(erlang, "eunit", "test")
fn run_eunit(tests: Dynamic, options: Dynamic) -> Result(Dynamic, Dynamic)

/// Create EUnit options list
@external(erlang, "test_runner@fast_ffi", "make_options")
fn make_options() -> Dynamic

/// Wrap tests in {inparallel, Tests} tuple
@external(erlang, "test_runner@fast_ffi", "wrap_inparallel")
fn wrap_inparallel(tests: List(Dynamic)) -> Dynamic

/// Format error for display
@external(erlang, "test_runner@fast_ffi", "format_error")
fn format_error(reason: Dynamic) -> String
