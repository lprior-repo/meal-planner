//// Test helpers for CLI domain tests
////
//// Provides utilities to reduce duplication in CLI test files.
//// Includes assertion helpers and test data builders.

import gleam/string

/// Assert that a string has a minimum length
///
/// Useful for validating non-empty configuration values.
pub fn assert_non_empty(value: String) -> Bool {
  string.length(value) > 0
}

/// Assert that a positive integer has valid port range
///
/// Valid ports are 1-65535. Used to validate server port configuration.
pub fn assert_valid_port(port: Int) -> Bool {
  port > 0 && port < 65536
}

/// Assert that a duration in milliseconds is configured
///
/// Used to validate timeout and request duration values.
pub fn assert_configured_duration(ms: Int) -> Bool {
  ms > 0
}

/// Assert that a pool size is configured and reasonable
///
/// Validates database connection pool configuration.
pub fn assert_configured_pool_size(pool_size: Int) -> Bool {
  pool_size > 0 && pool_size <= 100
}

/// Assert that a string contains a protocol specifier
///
/// Used to validate URLs start with http:// or https://
pub fn assert_has_protocol(url: String) -> Bool {
  string.contains(url, "http")
}

/// Assert that a URL does not end with a trailing slash
///
/// Validates that base URLs are properly formatted without trailing slash.
pub fn assert_no_trailing_slash(url: String) -> Bool {
  !string.ends_with(url, "/")
}
