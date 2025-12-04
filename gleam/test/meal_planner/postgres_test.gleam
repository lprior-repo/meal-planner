import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/postgres

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Configuration Tests
// ============================================================================

pub fn default_config_test() {
  let config = postgres.default_config()

  config.host
  |> should.equal("localhost")

  config.port
  |> should.equal(5432)

  config.database
  |> should.equal("meal_planner")

  config.user
  |> should.equal("postgres")

  config.password
  |> should.equal(Some("postgres"))

  config.pool_size
  |> should.equal(10)
}

pub fn config_from_env_uses_defaults_test() {
  // When no env vars are set, should use defaults
  let config = postgres.config_from_env()

  config.host
  |> should.equal("localhost")

  config.database
  |> should.equal("meal_planner")
}

// ============================================================================
// Error Formatting Tests
// ============================================================================

pub fn format_init_timeout_error_test() {
  let error = postgres.InitTimeout
  let formatted = postgres.format_error(error)

  formatted
  |> should.equal("Database connection timeout")
}

pub fn format_init_failed_error_test() {
  let error = postgres.InitFailed("connection refused")
  let formatted = postgres.format_error(error)

  formatted
  |> should.equal("Database connection failed: connection refused")
}

pub fn format_init_exited_error_test() {
  let error = postgres.InitExited("process crashed")
  let formatted = postgres.format_error(error)

  formatted
  |> should.equal("Database process exited: process crashed")
}

pub fn format_invalid_config_error_test() {
  let error = postgres.InvalidConfig("host cannot be empty")
  let formatted = postgres.format_error(error)

  formatted
  |> should.equal("Invalid configuration: host cannot be empty")
}

// ============================================================================
// Configuration Validation Tests
// ============================================================================

pub fn connect_validates_empty_host_test() {
  let config =
    postgres.Config(
      host: "",
      port: 5432,
      database: "test_db",
      user: "user",
      password: None,
      pool_size: 10,
    )

  let result = postgres.connect(config)

  case result {
    Error(postgres.InvalidConfig(msg)) -> {
      msg
      |> should.equal("Host cannot be empty")
    }
    _ -> should.fail()
  }
}

pub fn connect_validates_empty_database_test() {
  let config =
    postgres.Config(
      host: "localhost",
      port: 5432,
      database: "",
      user: "user",
      password: None,
      pool_size: 10,
    )

  let result = postgres.connect(config)

  case result {
    Error(postgres.InvalidConfig(msg)) -> {
      msg
      |> should.equal("Database name cannot be empty")
    }
    _ -> should.fail()
  }
}

pub fn connect_validates_empty_user_test() {
  let config =
    postgres.Config(
      host: "localhost",
      port: 5432,
      database: "test_db",
      user: "",
      password: None,
      pool_size: 10,
    )

  let result = postgres.connect(config)

  case result {
    Error(postgres.InvalidConfig(msg)) -> {
      msg
      |> should.equal("User cannot be empty")
    }
    _ -> should.fail()
  }
}

pub fn connect_validates_pool_size_too_small_test() {
  let config =
    postgres.Config(
      host: "localhost",
      port: 5432,
      database: "test_db",
      user: "user",
      password: None,
      pool_size: 0,
    )

  let result = postgres.connect(config)

  case result {
    Error(postgres.InvalidConfig(msg)) -> {
      msg
      |> should.equal("Pool size must be at least 1")
    }
    _ -> should.fail()
  }
}

pub fn connect_validates_pool_size_too_large_test() {
  let config =
    postgres.Config(
      host: "localhost",
      port: 5432,
      database: "test_db",
      user: "user",
      password: None,
      pool_size: 101,
    )

  let result = postgres.connect(config)

  case result {
    Error(postgres.InvalidConfig(msg)) -> {
      msg
      |> should.equal("Pool size cannot exceed 100")
    }
    _ -> should.fail()
  }
}

pub fn connect_to_database_helper_test() {
  // This will fail to connect in test environment, but we can verify
  // it properly constructs the config and attempts connection
  let result =
    postgres.connect_to_database(
      "localhost",
      5432,
      "postgres",
      "postgres",
      Some("postgres"),
    )

  // Should get connection error (not validation error)
  case result {
    Error(postgres.InitFailed(_)) -> should.be_true(True)
    Error(postgres.InitTimeout) -> should.be_true(True)
    Error(postgres.InitExited(_)) -> should.be_true(True)
    Error(postgres.InvalidConfig(_)) -> should.fail()
    Ok(_) -> should.be_true(True)
  }
}
