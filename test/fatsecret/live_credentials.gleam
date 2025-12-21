/// Live Test Credentials Helper (meal-planner-zzxy)
///
/// Provides credential loading and test skip mechanism for live integration tests.
/// Live tests require valid FatSecret API credentials and are excluded from fast test runs.
import gleam/option
import meal_planner/env

/// Require FatSecret credentials for live tests
///
/// Loads credentials from environment using env.load_fatsecret_config().
/// Returns Ok(FatSecretConfig) if credentials are present and valid.
/// Returns Error(Nil) if credentials are missing - signals test should be skipped.
///
/// ## Usage in tests
/// ```gleam
/// pub fn autocomplete_live_test() {
///   case require_credentials() {
///     Error(Nil) -> {
///       io.println("SKIP: FatSecret credentials not configured")
///       Nil
///     }
///     Ok(config) -> {
///       // Run live test with config
///       let result = autocomplete_foods(config, "apple")
///       should.be_ok(result)
///     }
///   }
/// }
/// ```
pub fn require_credentials() -> Result(env.FatSecretConfig, Nil) {
  case env.load_fatsecret_config() {
    option.Some(cfg) -> Ok(cfg)
    option.None -> Error(Nil)
  }
}
