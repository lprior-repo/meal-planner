//// Tests for error handling module
////
//// Verifies exit codes, error formatting, and error recovery suggestions

import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/error

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Exit Code Tests
// ============================================================================

pub fn exit_code_success_test() {
  error.exit_code_to_int(error.Success)
  |> should.equal(0)
}

pub fn exit_code_general_error_test() {
  error.exit_code_to_int(error.GeneralError)
  |> should.equal(1)
}

pub fn exit_code_invalid_usage_test() {
  error.exit_code_to_int(error.InvalidUsage)
  |> should.equal(2)
}

pub fn exit_code_auth_error_test() {
  error.exit_code_to_int(error.AuthError)
  |> should.equal(3)
}

pub fn exit_code_network_error_test() {
  error.exit_code_to_int(error.NetworkError)
  |> should.equal(4)
}

pub fn exit_code_database_error_test() {
  error.exit_code_to_int(error.DatabaseError)
  |> should.equal(5)
}

// ============================================================================
// App Error Exit Code Mapping Tests
// ============================================================================

pub fn config_error_maps_to_general_error_test() {
  let app_err =
    error.ConfigError("Missing DATABASE_HOST", "Set DATABASE_HOST env var")
  error.get_exit_code(app_err)
  |> error.exit_code_to_int
  |> should.equal(1)
}

pub fn database_error_maps_to_database_error_test() {
  let app_err = error.DbError("Connection refused", "Check database is running")
  error.get_exit_code(app_err)
  |> error.exit_code_to_int
  |> should.equal(5)
}

pub fn network_error_maps_to_network_error_test() {
  let app_err = error.NetError("Timeout", "Check network connection")
  error.get_exit_code(app_err)
  |> error.exit_code_to_int
  |> should.equal(4)
}

pub fn auth_error_maps_to_auth_error_test() {
  let app_err =
    error.AuthenticationError("Invalid token", "Refresh your credentials")
  error.get_exit_code(app_err)
  |> error.exit_code_to_int
  |> should.equal(3)
}

pub fn usage_error_maps_to_invalid_usage_test() {
  let app_err = error.UsageError("Invalid argument", "Use --help for usage")
  error.get_exit_code(app_err)
  |> error.exit_code_to_int
  |> should.equal(2)
}

pub fn io_error_maps_to_general_error_test() {
  let app_err = error.IoError("File not found", "Check file path")
  error.get_exit_code(app_err)
  |> error.exit_code_to_int
  |> should.equal(1)
}

pub fn application_error_maps_to_general_error_test() {
  let app_err = error.ApplicationError("Something went wrong", "Check logs")
  error.get_exit_code(app_err)
  |> error.exit_code_to_int
  |> should.equal(1)
}

// ============================================================================
// Error Formatting Tests
// ============================================================================

pub fn format_config_error_includes_title_test() {
  let app_err = error.ConfigError("Missing DATABASE_HOST", "Set DATABASE_HOST")
  let formatted = error.format_error(app_err)
  formatted
  |> string.contains("Configuration Error")
  |> should.be_true
}

pub fn format_config_error_includes_message_test() {
  let app_err = error.ConfigError("Missing DATABASE_HOST", "Set DATABASE_HOST")
  let formatted = error.format_error(app_err)
  formatted
  |> string.contains("Missing DATABASE_HOST")
  |> should.be_true
}

pub fn format_config_error_includes_hint_test() {
  let app_err = error.ConfigError("Missing DATABASE_HOST", "Set DATABASE_HOST")
  let formatted = error.format_error(app_err)
  formatted
  |> string.contains("Set DATABASE_HOST")
  |> should.be_true
}

pub fn format_database_error_test() {
  let app_err = error.DbError("Connection refused", "Restart database")
  let formatted = error.format_error(app_err)
  formatted
  |> string.contains("Database Error")
  |> should.be_true
}

pub fn format_network_error_test() {
  let app_err = error.NetError("Timeout connecting to server", "Check network")
  let formatted = error.format_error(app_err)
  formatted
  |> string.contains("Network Error")
  |> should.be_true
}

pub fn format_auth_error_test() {
  let app_err =
    error.AuthenticationError("Invalid credentials", "Check your API key")
  let formatted = error.format_error(app_err)
  formatted
  |> string.contains("Authentication Error")
  |> should.be_true
}

pub fn format_usage_error_test() {
  let app_err = error.UsageError("Unknown command", "Use --help for usage info")
  let formatted = error.format_error(app_err)
  formatted
  |> string.contains("Invalid Usage")
  |> should.be_true
}

pub fn format_io_error_test() {
  let app_err =
    error.IoError("File not found: config.json", "Create the file first")
  let formatted = error.format_error(app_err)
  formatted
  |> string.contains("File/IO Error")
  |> should.be_true
}

pub fn format_error_without_hint_test() {
  let app_err = error.ApplicationError("Generic error", "")
  let formatted = error.format_error(app_err)
  formatted
  |> string.contains("Application Error")
  |> should.be_true
}

// ============================================================================
// Error Constructor Tests
// ============================================================================

pub fn config_error_constructor_test() {
  let err = error.config_error("Missing var", "Set it")
  case err {
    error.ConfigError(msg, hint) -> {
      msg
      |> should.equal("Missing var")
      hint
      |> should.equal("Set it")
    }
    _ -> Nil
  }
}

pub fn database_error_constructor_test() {
  let err = error.database_error("Connection failed", "Restart DB")
  case err {
    error.DbError(msg, hint) -> {
      msg
      |> should.equal("Connection failed")
      hint
      |> should.equal("Restart DB")
    }
    _ -> Nil
  }
}

pub fn network_error_constructor_test() {
  let err = error.network_error("Timeout", "Check network")
  case err {
    error.NetError(msg, hint) -> {
      msg
      |> should.equal("Timeout")
      hint
      |> should.equal("Check network")
    }
    _ -> Nil
  }
}

pub fn auth_error_constructor_test() {
  let err = error.auth_error("Unauthorized", "Login again")
  case err {
    error.AuthenticationError(msg, hint) -> {
      msg
      |> should.equal("Unauthorized")
      hint
      |> should.equal("Login again")
    }
    _ -> Nil
  }
}

pub fn io_error_constructor_test() {
  let err = error.io_error("File not found", "Create file")
  case err {
    error.IoError(msg, hint) -> {
      msg
      |> should.equal("File not found")
      hint
      |> should.equal("Create file")
    }
    _ -> Nil
  }
}

pub fn usage_error_constructor_test() {
  let err = error.usage_error("Invalid arg", "Use --help")
  case err {
    error.UsageError(msg, hint) -> {
      msg
      |> should.equal("Invalid arg")
      hint
      |> should.equal("Use --help")
    }
    _ -> Nil
  }
}

pub fn app_error_constructor_test() {
  let err = error.app_error("Something failed", "Try again")
  case err {
    error.ApplicationError(msg, hint) -> {
      msg
      |> should.equal("Something failed")
      hint
      |> should.equal("Try again")
    }
    _ -> Nil
  }
}
