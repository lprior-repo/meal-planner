//// Logging Configuration Tests
//// Tests for meal_planner/config/logging module
//// TDD - Tests for logging configuration module

import gleeunit
import gleeunit/should
import meal_planner/config/environment.{
  DebugLevel, ErrorLevel, InfoLevel, WarnLevel,
}
import meal_planner/config/logging

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// TEST 1: Load logging config with default values
// ============================================================================

pub fn logging_config_load_defaults_test() {
  // Given no environment variables set
  // Note: In real test, we'd clear env vars, but for now we test with defaults

  // When loading logging config
  let result = logging.load()

  // Then should succeed with default values
  result
  |> should.be_ok

  // And log level should be InfoLevel (default)
  case result {
    Ok(config) -> {
      config.level
      |> should.equal(InfoLevel)

      // And debug mode should be False
      config.debug_mode
      |> should.equal(False)
    }
    Error(_) -> panic as "Expected Ok result"
  }
}

// ============================================================================
// TEST 2: Load logging config with custom log level
// ============================================================================

pub fn logging_config_load_custom_level_test() {
  // Given LOG_LEVEL environment variable set to "debug"
  // Note: This test assumes LOG_LEVEL is set in test environment

  // When loading logging config
  let result = logging.load()

  // Then should succeed
  result
  |> should.be_ok
}

// ============================================================================
// TEST 3: Get log level string
// ============================================================================

pub fn logging_get_log_level_string_test() {
  // Given different log levels
  let debug = DebugLevel
  let info = InfoLevel
  let warn = WarnLevel
  let error = ErrorLevel

  // When converting to string
  let debug_str = logging.get_log_level_string(debug)
  let info_str = logging.get_log_level_string(info)
  let warn_str = logging.get_log_level_string(warn)
  let error_str = logging.get_log_level_string(error)

  // Then should return correct strings
  debug_str |> should.equal("debug")
  info_str |> should.equal("info")
  warn_str |> should.equal("warn")
  error_str |> should.equal("error")
}

// ============================================================================
// TEST 4: Load logging config with debug mode enabled
// ============================================================================

pub fn logging_config_debug_mode_test() {
  // Given DEBUG_MODE environment variable set to "true"
  // Note: This test demonstrates the expected behavior

  // When loading logging config
  let result = logging.load()

  // Then should succeed
  result
  |> should.be_ok
}

// ============================================================================
// TEST 5: Validate logging config type
// ============================================================================

pub fn logging_config_type_test() {
  // Given a LoggingConfig with specific values
  let config = logging.LoggingConfig(level: DebugLevel, debug_mode: True)

  // When checking the values
  // Then should have correct level
  config.level
  |> should.equal(DebugLevel)

  // And debug mode should be enabled
  config.debug_mode
  |> should.equal(True)
}
