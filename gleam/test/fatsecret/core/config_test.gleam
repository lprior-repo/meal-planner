import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/core/config

pub fn main() {
  gleeunit.main()
}

// Test config creation

pub fn new_creates_config_with_defaults_test() {
  let cfg = config.new("test_key", "test_secret")

  cfg.consumer_key |> should.equal("test_key")
  cfg.consumer_secret |> should.equal("test_secret")
  cfg.api_host |> should.equal(None)
  cfg.auth_host |> should.equal(None)
}

// Test host getters

pub fn get_api_host_uses_default_test() {
  let cfg = config.new("key", "secret")

  config.get_api_host(cfg)
  |> should.equal("platform.fatsecret.com")
}

pub fn get_api_host_uses_custom_test() {
  let cfg =
    config.FatSecretConfig(
      consumer_key: "key",
      consumer_secret: "secret",
      api_host: Some("custom.api.host"),
      auth_host: None,
    )

  config.get_api_host(cfg)
  |> should.equal("custom.api.host")
}

pub fn get_auth_host_uses_default_test() {
  let cfg = config.new("key", "secret")

  config.get_auth_host(cfg)
  |> should.equal("authentication.fatsecret.com")
}

pub fn get_auth_host_uses_custom_test() {
  let cfg =
    config.FatSecretConfig(
      consumer_key: "key",
      consumer_secret: "secret",
      api_host: None,
      auth_host: Some("custom.auth.host"),
    )

  config.get_auth_host(cfg)
  |> should.equal("custom.auth.host")
}

// Test URL builders

pub fn api_url_with_default_host_test() {
  let cfg = config.new("key", "secret")

  config.api_url(cfg)
  |> should.equal("https://platform.fatsecret.com/rest/server.api")
}

pub fn api_url_with_custom_host_test() {
  let cfg =
    config.FatSecretConfig(
      consumer_key: "key",
      consumer_secret: "secret",
      api_host: Some("api.example.com"),
      auth_host: None,
    )

  config.api_url(cfg)
  |> should.equal("https://api.example.com/rest/server.api")
}

pub fn authorization_url_with_default_host_test() {
  let cfg = config.new("key", "secret")

  config.authorization_url(cfg, "test_token")
  |> should.equal(
    "https://authentication.fatsecret.com/authorize?oauth_token=test_token",
  )
}

pub fn authorization_url_with_custom_host_test() {
  let cfg =
    config.FatSecretConfig(
      consumer_key: "key",
      consumer_secret: "secret",
      api_host: None,
      auth_host: Some("auth.example.com"),
    )

  config.authorization_url(cfg, "my_token")
  |> should.equal("https://auth.example.com/authorize?oauth_token=my_token")
}

// Test constants

pub fn default_api_host_constant_test() {
  config.default_api_host
  |> should.equal("platform.fatsecret.com")
}

pub fn default_auth_host_constant_test() {
  config.default_auth_host
  |> should.equal("authentication.fatsecret.com")
}

pub fn api_path_constant_test() {
  config.api_path
  |> should.equal("/rest/server.api")
}
// Note: from_env() tests are not included here because they depend on environment variables
// which should be tested in integration tests, not unit tests. The function will return None
// if the required environment variables are not set, and Some(config) if they are.
