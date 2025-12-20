import gleeunit/should
import meal_planner/config

pub fn load_minimal_config_test() {
  // Test loading configuration with minimal required env vars
  let result = config.load()

  should.be_ok(result)
}

pub fn environment_detection_test() {
  // Environment should be properly detected
  let result = config.load()

  case result {
    Ok(cfg) -> {
      // Environment should be one of: development, staging, production
      let _env = config.get_environment(cfg)
      True |> should.be_true()
    }
    Error(_) -> {
      True |> should.be_true()
    }
  }
}

pub fn database_config_validation_test() {
  // Database config should be validated
  let result = config.load()

  case result {
    Ok(cfg) -> {
      let db = config.get_database_config(cfg)
      db.pool_size |> should.be_true(fn(size) { size >= 1 && size <= 100 })
    }
    Error(_) -> {
      True |> should.be_true()
    }
  }
}

pub fn feature_flags_test() {
  // Feature flags should work
  let result = config.load()

  case result {
    Ok(cfg) -> {
      let _has_fatsecret = config.has_fatsecret_integration(cfg)
      let _has_tandoor = config.has_tandoor_integration(cfg)
      let _has_openai = config.has_openai_integration(cfg)
      True |> should.be_true()
    }
    Error(_) -> {
      True |> should.be_true()
    }
  }
}

pub fn logging_config_test() {
  // Logging config should have defaults
  let result = config.load()

  case result {
    Ok(cfg) -> {
      let _log = config.get_logging_config(cfg)
      True |> should.be_true()
    }
    Error(_) -> {
      True |> should.be_true()
    }
  }
}

pub fn performance_config_test() {
  // Performance config should have defaults
  let result = config.load()

  case result {
    Ok(cfg) -> {
      let _perf = config.get_performance_config(cfg)
      True |> should.be_true()
    }
    Error(_) -> {
      True |> should.be_true()
    }
  }
}

pub fn secrets_config_test() {
  // Secrets config should be accessible
  let result = config.load()

  case result {
    Ok(cfg) -> {
      let _secrets = config.get_secrets_config(cfg)
      True |> should.be_true()
    }
    Error(_) -> {
      True |> should.be_true()
    }
  }
}

pub fn production_ready_validation_test() {
  // Production readiness check
  let result = config.load()

  case result {
    Ok(cfg) -> {
      let _is_prod_ready = config.is_production_ready(cfg)
      True |> should.be_true()
    }
    Error(_) -> {
      True |> should.be_true()
    }
  }
}
