/// Test script to verify FatSecret API connection (OAuth 1.0a)
/// Run with: gleam run -m scripts/test_fatsecret
import dot_env
import envoy
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import meal_planner/env
import meal_planner/fatsecret/client as fatsecret

pub fn main() {
  dot_env.new()
  |> dot_env.set_path("../.env")
  |> dot_env.set_debug(False)
  |> dot_env.load
  io.println("Testing FatSecret API Connection (OAuth 1.0a)...")
  io.println("")

  let consumer_key = result.unwrap(envoy.get("FATSECRET_CONSUMER_KEY"), "")
  let consumer_secret =
    result.unwrap(envoy.get("FATSECRET_CONSUMER_SECRET"), "")

  case string.is_empty(consumer_key) || string.is_empty(consumer_secret) {
    True -> {
      io.println("FatSecret not configured")
      io.println("Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET")
    }
    False -> {
      io.println("Credentials loaded:")
      io.println("  Key: " <> string.slice(consumer_key, 0, 8) <> "...")
      io.println("")

      let config = env.FatSecretConfig(consumer_key, consumer_secret)

      io.println("Step 1: Testing 2-legged OAuth 1.0a (food search)...")
      test_search(config)

      io.println("")
      io.println("Step 2: Testing 3-legged OAuth 1.0a (request token)...")
      test_request_token(config)
    }
  }
}

fn test_search(config: env.FatSecretConfig) {
  case fatsecret.search_foods_parsed(config, "chicken breast") {
    Ok(foods) -> {
      io.println("  Found " <> string.inspect(list.length(foods)) <> " results")
      io.println("")

      list.take(foods, 3)
      |> list.each(fn(food) {
        io.println("  " <> food.food_name)
        io.println("    ID: " <> food.food_id)
        io.println(
          "    " <> string.slice(food.food_description, 0, 50) <> "...",
        )
        io.println("")
      })

      io.println("  2-LEGGED OAUTH 1.0a SUCCESS!")
    }
    Error(error) -> {
      io.println("  Search failed:")
      print_error(error)
    }
  }
}

fn test_request_token(config: env.FatSecretConfig) {
  io.println("  Debug OAuth 1.0a:")
  io.println(fatsecret.debug_oauth1(config))
  io.println("")
  io.println("  Attempting request...")
  case fatsecret.get_request_token(config, "oob") {
    Ok(token) -> {
      io.println("  Request token obtained!")
      io.println(
        "    Token: " <> string.slice(token.oauth_token, 0, 20) <> "...",
      )
      io.println(
        "    Callback confirmed: "
        <> string.inspect(token.oauth_callback_confirmed),
      )
      io.println("")

      let auth_url = fatsecret.get_authorization_url(token)
      io.println("  Authorization URL:")
      io.println("    " <> auth_url)
      io.println("")
      io.println("  3-LEGGED OAUTH 1.0a REQUEST TOKEN SUCCESS!")
    }
    Error(error) -> {
      io.println("  Request token failed:")
      print_error(error)
    }
  }
}

fn print_error(error: fatsecret.FatSecretError) {
  case error {
    fatsecret.ConfigMissing -> io.println("    Config missing")
    fatsecret.NetworkError(msg) -> io.println("    Network: " <> msg)
    fatsecret.ApiError(code, msg) ->
      io.println("    API " <> code <> ": " <> msg)
    fatsecret.OAuthError(msg) -> io.println("    OAuth: " <> msg)
    fatsecret.ParseError(msg) -> io.println("    Parse: " <> msg)
    fatsecret.RequestFailed(status, body) ->
      io.println(
        "    Request failed: " <> string.inspect(status) <> " " <> body,
      )
    fatsecret.InvalidResponse(msg) -> io.println("    Invalid: " <> msg)
  }
}
