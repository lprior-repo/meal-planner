/// Persistent file-based caching layer for CLI
///
/// This module provides a file-based caching system for CLI operations
/// with TTL support, pattern-based invalidation, and offline mode detection.
///
/// Cache entries are stored in ~/.meal-planner/cache/ with JSON encoding.
/// Each cache entry includes the value and expiration timestamp.
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile

/// Cache entry with value and expiration timestamp
pub type CacheEntry {
  CacheEntry(value: String, expires_at: Int)
}

/// Cache directory path (typically ~/.meal-planner/cache/)
pub type CacheDir =
  String

/// TTL configurations for different data types
pub const food_search_ttl_hours = 24

pub const recipe_ttl_hours = 24

pub const diary_ttl_hours = 4

pub const usda_food_ttl_hours = 720

/// Ensure the cache directory exists
pub fn ensure_cache_directory(cache_dir: CacheDir) -> Result(Nil, String) {
  case simplifile.create_directory_all(cache_dir) {
    Ok(_) -> Ok(Nil)
    Error(err) ->
      Error("Failed to create cache directory: " <> string.inspect(err))
  }
}

/// Get current Unix timestamp in seconds
fn now() -> Int {
  erlang_system_time()
}

@external(erlang, "erlang", "system_time")
fn erlang_system_time() -> Int

/// Generate file path for a cache key
fn cache_file_path(cache_dir: CacheDir, key: String) -> String {
  let safe_key =
    key
    |> string.replace(":", "_")
    |> string.replace("/", "_")
    |> string.replace("\\\\", "_")

  cache_dir <> "/" <> safe_key <> ".json"
}

/// Encode a cache entry to JSON string
fn encode_cache_entry(entry: CacheEntry) -> String {
  json.object([
    #("value", json.string(entry.value)),
    #("expires_at", json.int(entry.expires_at)),
  ])
  |> json.to_string()
}

/// Decode a cache entry from JSON string
fn decode_cache_entry(json_str: String) -> Result(CacheEntry, String) {
  use parsed <- result.try(
    json.decode(json_str, decode_entry_dynamic)
    |> result.map_error(fn(_) { "Failed to parse cache entry JSON" }),
  )
  Ok(parsed)
}

fn decode_entry_dynamic(
  data: dynamic.Dynamic,
) -> Result(CacheEntry, List(dynamic.DecodeError)) {
  use value <- result.try(dynamic.field("value", dynamic.string)(data))
  use expires_at <- result.try(dynamic.field("expires_at", dynamic.int)(data))
  Ok(CacheEntry(value: value, expires_at: expires_at))
}

/// Cache a response with TTL in hours
pub fn cache_response(
  cache_dir: CacheDir,
  key: String,
  value: String,
  ttl_hours: Int,
) -> Result(Nil, String) {
  use _ <- result.try(ensure_cache_directory(cache_dir))
  let ttl_seconds = ttl_hours * 3600
  let expires_at = now() + ttl_seconds
  let entry = CacheEntry(value: value, expires_at: expires_at)
  let file_path = cache_file_path(cache_dir, key)
  let json_content = encode_cache_entry(entry)

  case simplifile.write(file_path, json_content) {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error("Failed to write cache file: " <> string.inspect(err))
  }
}

/// Get a cached value if it exists and hasn't expired
pub fn get_cached(cache_dir: CacheDir, key: String) -> Option(String) {
  let file_path = cache_file_path(cache_dir, key)

  case simplifile.read(file_path) {
    Ok(json_content) -> {
      case decode_cache_entry(json_content) {
        Ok(entry) -> {
          let current_time = now()
          case entry.expires_at > current_time {
            True -> Some(entry.value)
            False -> {
              let _ = simplifile.delete(file_path)
              None
            }
          }
        }
        Error(_) -> {
          let _ = simplifile.delete(file_path)
          None
        }
      }
    }
    Error(_) -> None
  }
}

/// Clear cache entries matching a pattern
pub fn clear_cache(cache_dir: CacheDir, pattern: String) -> Result(Int, String) {
  case simplifile.read_directory(cache_dir) {
    Ok(files) -> {
      let deleted =
        list.fold(files, 0, fn(count, filename) {
          let key =
            filename
            |> string.replace(".json", "")
            |> string.replace("_", ":")

          case string.starts_with(key, pattern) {
            True -> {
              let file_path = cache_dir <> "/" <> filename
              case simplifile.delete(file_path) {
                Ok(_) -> count + 1
                Error(_) -> count
              }
            }
            False -> count
          }
        })
      Ok(deleted)
    }
    Error(_) -> Ok(0)
  }
}

/// Remove all expired cache entries
pub fn cleanup_expired(cache_dir: CacheDir) -> Result(Int, String) {
  case simplifile.read_directory(cache_dir) {
    Ok(files) -> {
      let current_time = now()
      let deleted =
        list.fold(files, 0, fn(count, filename) {
          let file_path = cache_dir <> "/" <> filename

          case simplifile.read(file_path) {
            Ok(json_content) -> {
              case decode_cache_entry(json_content) {
                Ok(entry) -> {
                  case entry.expires_at <= current_time {
                    True -> {
                      case simplifile.delete(file_path) {
                        Ok(_) -> count + 1
                        Error(_) -> count
                      }
                    }
                    False -> count
                  }
                }
                Error(_) -> {
                  case simplifile.delete(file_path) {
                    Ok(_) -> count + 1
                    Error(_) -> count
                  }
                }
              }
            }
            Error(_) -> count
          }
        })
      Ok(deleted)
    }
    Error(_) -> Ok(0)
  }
}

/// Check if the system is offline
pub fn is_offline() -> Bool {
  case check_network_connectivity() {
    Ok(_) -> False
    Error(_) -> True
  }
}

fn check_network_connectivity() -> Result(Nil, Nil) {
  case inet_gethostbyname("google.com") {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(Nil)
  }
}

@external(erlang, "inet", "gethostbyname")
fn inet_gethostbyname(hostname: String) -> Result(a, b)

/// Get the default cache directory path
pub fn default_cache_dir() -> String {
  case get_home_directory() {
    Ok(home) -> home <> "/.meal-planner/cache"
    Error(_) -> "/tmp/meal-planner-cache"
  }
}

fn get_home_directory() -> Result(String, Nil) {
  case get_env_var("HOME") {
    Ok(home) -> Ok(home)
    Error(_) -> Error(Nil)
  }
}

@external(erlang, "os", "getenv")
fn get_env_var(name: String) -> Result(String, Nil)
