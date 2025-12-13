/// Test script to verify FatSecret API connection
/// Run with: gleam run -m scripts/test_fatsecret
import envoy
import gleam/io
import gleam/result
import gleam/string
import meal_planner/fatsecret/client as fatsecret

pub fn main() {
  io.println("🔍 Testing FatSecret API Connection...")
  io.println("")

  // Load credentials directly from environment
  let consumer_key = result.unwrap(envoy.get("FATSECRET_CONSUMER_KEY"), "")
  let consumer_secret =
    result.unwrap(envoy.get("FATSECRET_CONSUMER_SECRET"), "")

  case string.is_empty(consumer_key) || string.is_empty(consumer_secret) {
    True -> {
      io.println("❌ FatSecret not configured")
      io.println(
        "   Please set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET in .env",
      )
    }
    False -> {
      io.println("✅ FatSecret credentials loaded:")
      io.println("   Consumer Key: " <> consumer_key)
      io.println("   Consumer Secret: " <> get_last_chars(consumer_secret, 4))
      io.println("")

      let config = fatsecret.FatSecretConfig(consumer_key, consumer_secret)

      // Test connection
      io.println("🔌 Testing API connection...")
      case fatsecret.test_connection(config) {
        Ok(True) -> {
          io.println("✅ Connection successful!")
          io.println("")
          test_search(config)
        }
        Ok(False) -> {
          io.println("❌ Connection failed (returned false)")
        }
        Error(error) -> {
          io.println("❌ Connection error:")
          print_error(error)
        }
      }
    }
  }
}

fn test_search(config: fatsecret.FatSecretConfig) {
  io.println("🔍 Testing food search for 'chicken breast'...")
  case fatsecret.search_foods(config, "chicken breast") {
    Ok(response) -> {
      io.println("✅ Search successful!")
      io.println("   Response preview:")
      io.println("   " <> get_first_chars(response, 200))
    }
    Error(error) -> {
      io.println("❌ Search failed:")
      print_error(error)
    }
  }
}

fn print_error(error: fatsecret.FatSecretError) {
  case error {
    fatsecret.NetworkError(msg) -> io.println("   Network Error: " <> msg)
    fatsecret.ApiError(code, msg) ->
      io.println("   API Error " <> code <> ": " <> msg)
    fatsecret.OAuthError(msg) -> io.println("   OAuth Error: " <> msg)
    fatsecret.ParseError(msg) -> io.println("   Parse Error: " <> msg)
  }
}

fn get_last_chars(s: String, n: Int) -> String {
  let len = string.length(s)
  case len <= n {
    True -> s
    False -> "***" <> string.slice(s, len - n, n)
  }
}

fn get_first_chars(s: String, n: Int) -> String {
  let len = string.length(s)
  case len <= n {
    True -> s
    False -> string.slice(s, 0, n) <> "..."
  }
}
