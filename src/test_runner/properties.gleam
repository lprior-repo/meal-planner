/// Property-based Test Runner
///
/// Runs only property-based tests in test/fatsecret/properties/
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub fn main() {
  io.println("🔬 Property-based Test Runner")
  io.println("")

  let all_modules = discover_test_modules("test/**/*_test.gleam")
  let property_modules = list.filter(all_modules, is_property_test)
  let module_count = list.length(property_modules)

  io.println(
    "Running " <> int.to_string(module_count) <> " property test modules",
  )
  io.println("")

  case run_all_parallel(property_modules) {
    True -> {
      io.println("")
      io.println(
        "✅ All " <> int.to_string(module_count) <> " property tests passed!",
      )
      halt(0)
    }
    False -> {
      io.println("")
      io.println("❌ Some property tests failed")
      halt(1)
    }
  }
}

/// Filter for property-based tests
fn is_property_test(module_name: String) -> Bool {
  string.contains(module_name, "properties")
}

/// Discover test modules matching a glob pattern
fn discover_test_modules(pattern: String) -> List(String) {
  pattern
  |> to_charlist
  |> find_files_charlist
  |> list.map(charlist_to_string)
  |> list.map(gleam_to_module_name)
}

/// Convert file path to Gleam module name
fn gleam_to_module_name(path: String) -> String {
  path
  |> string.replace(".gleam", "")
  |> string.replace("test/", "")
  |> string.replace("/", "@")
}

/// Run all tests in parallel using EUnit's inparallel wrapper
fn run_all_parallel(module_names: List(String)) -> Bool {
  let atoms = list.map(module_names, to_atom)

  // Create {inparallel, [atoms]} tuple for EUnit
  let tests = make_inparallel_tuple(atoms)

  // Run with verbose option
  let verbose_atom = to_atom("verbose")
  run_eunit_tests(tests, [verbose_atom])
}

// =============================================================================
// Erlang FFI - Pure Gleam with @external declarations
// =============================================================================

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

/// Convert Gleam string (binary) to Erlang charlist
@external(erlang, "erlang", "binary_to_list")
fn to_charlist(binary: String) -> Dynamic

/// Convert Erlang charlist to Gleam string (binary)
@external(erlang, "erlang", "list_to_binary")
fn charlist_to_string(charlist: Dynamic) -> String

/// Find files matching a glob pattern (takes charlist, returns list of charlists)
@external(erlang, "filelib", "wildcard")
fn find_files_charlist(pattern: Dynamic) -> List(Dynamic)

/// Convert string to Erlang atom
@external(erlang, "erlang", "binary_to_atom")
fn to_atom(name: String) -> Dynamic

/// Create {inparallel, Tests} tuple - Gleam tuples work directly!
fn make_inparallel_tuple(tests: List(Dynamic)) -> Dynamic {
  // Gleam #() tuples are Erlang tuples at runtime
  coerce(#(to_atom("inparallel"), tests))
}

/// Type coercion helper - identity at runtime
@external(erlang, "gleam_stdlib", "identity")
fn coerce(value: a) -> Dynamic

/// Run EUnit and check if all tests pass
fn run_eunit_tests(tests: Dynamic, options: List(Dynamic)) -> Bool {
  case eunit_test(tests, options) {
    // EUnit returns 'ok' atom on success
    "ok" -> True
    _ -> False
  }
}

/// Call eunit:test/2 and convert result to string for pattern matching
fn eunit_test(tests: Dynamic, options: List(Dynamic)) -> String {
  let result = eunit_test_raw(tests, options)
  atom_to_string(result)
}

@external(erlang, "eunit", "test")
fn eunit_test_raw(tests: Dynamic, options: List(Dynamic)) -> Dynamic

@external(erlang, "erlang", "atom_to_binary")
fn atom_to_string(atom: Dynamic) -> String
