/// Parallel Test Runner using BEAM concurrency
///
/// Runs all test modules concurrently using OTP processes for massive speedup
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list

/// Run tests in parallel across all available schedulers
pub fn main() {
  io.println("🚀 Parallel Test Runner - Using BEAM Concurrency")
  io.println("")

  let test_modules = discover_test_modules()
  let module_count = list.length(test_modules)
  io.println("Found " <> int.to_string(module_count) <> " test modules")
  io.println("")

  // Run all test modules in parallel
  let results = run_tests_parallel(test_modules)

  // Collect and report results
  let #(passed, failed) = summarize_results(results)

  io.println("")
  io.println("═══════════════════════════════════════════")
  io.println(
    "Results: "
    <> int.to_string(passed)
    <> " passed, "
    <> int.to_string(failed)
    <> " failed",
  )
  io.println("═══════════════════════════════════════════")

  case failed {
    0 -> halt(0)
    _ -> halt(1)
  }
}

type TestResult {
  TestPassed(module: String, count: Int)
  TestFailed(module: String, count: Int, errors: List(String))
}

fn run_tests_parallel(modules: List(String)) -> List(TestResult) {
  // Spawn a process for each test module
  let subjects: List(Subject(TestResult)) =
    list.map(modules, fn(module) {
      let subject = process.new_subject()

      // Spawn async test runner for this module
      process.spawn(fn() {
        let result = run_module_tests(module)
        process.send(subject, result)
      })

      subject
    })

  // Wait for all results (with timeout)
  list.map(subjects, fn(subject) {
    case process.receive(subject, 60_000) {
      Ok(result) -> result
      Error(_) -> TestFailed(module: "timeout", count: 0, errors: ["Timeout"])
    }
  })
}

fn run_module_tests(module_name: String) -> TestResult {
  let atom = string_to_atom(module_name)
  case run_eunit_module(atom) {
    Ok(count) -> TestPassed(module: module_name, count: count)
    Error(errors) -> TestFailed(module: module_name, count: 0, errors: errors)
  }
}

fn summarize_results(results: List(TestResult)) -> #(Int, Int) {
  list.fold(results, #(0, 0), fn(acc, result) {
    let #(passed, failed) = acc
    case result {
      TestPassed(_, count) -> #(passed + count, failed)
      TestFailed(_, count, _) -> #(passed, failed + 1)
    }
  })
}

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

@external(erlang, "erlang", "binary_to_atom")
fn string_to_atom(name: String) -> a

@external(erlang, "test_runner_ffi", "discover_test_modules")
fn discover_test_modules() -> List(String)

@external(erlang, "test_runner_ffi", "run_eunit_module")
fn run_eunit_module(module: a) -> Result(Int, List(String))
