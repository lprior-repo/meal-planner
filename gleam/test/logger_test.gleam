import gleeunit
import gleeunit/should
import logging
import meal_planner/logger

pub fn main() {
  gleeunit.main()
}

// Test that logger module exposes standard logging functions
pub fn info_test() {
  // Should not panic when logging info
  logger.info("Test info message")
  |> should.equal(Nil)
}

pub fn warning_test() {
  // Should not panic when logging warning
  logger.warning("Test warning message")
  |> should.equal(Nil)
}

pub fn error_test() {
  // Should not panic when logging error
  logger.error("Test error message")
  |> should.equal(Nil)
}

pub fn debug_test() {
  // Should not panic when logging debug
  logger.debug("Test debug message")
  |> should.equal(Nil)
}

pub fn configure_test() {
  // Should not panic when configuring logger
  logger.configure()
  |> should.equal(Nil)
}

pub fn set_level_test() {
  // Should not panic when setting log level
  logger.set_level(logging.Info)
  |> should.equal(Nil)
}
