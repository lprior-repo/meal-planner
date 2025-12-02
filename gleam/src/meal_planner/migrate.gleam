/// Database migration system
/// Runs numbered SQL migration files from gleam/migrations/
import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile
import sqlight

/// Migration error types
pub type MigrateError {
  FileError(simplifile.FileError)
  DatabaseError(String)
  ParseError(String)
}

/// A parsed migration
pub type Migration {
  Migration(version: Int, name: String, sql: String)
}

/// Get the application data directory (cross-platform)
/// - Windows: %LOCALAPPDATA%\meal-planner
/// - Unix/Linux: $XDG_DATA_HOME/meal-planner or ~/.local/share/meal-planner
pub fn get_data_dir() -> String {
  // Try Windows LOCALAPPDATA first
  case envoy_get("LOCALAPPDATA") {
    Ok(local_app_data) -> local_app_data <> "\\meal-planner"
    Error(_) -> {
      // Fall back to XDG/Unix paths
      case simplifile.is_directory(get_xdg_data_home()) {
        Ok(True) -> get_xdg_data_home() <> "/meal-planner"
        _ -> get_home() <> "/.local/share/meal-planner"
      }
    }
  }
}

fn get_xdg_data_home() -> String {
  case envoy_get("XDG_DATA_HOME") {
    Ok(path) -> path
    Error(_) -> get_home() <> "/.local/share"
  }
}

fn get_home() -> String {
  // Try USERPROFILE (Windows) first, then HOME (Unix)
  case envoy_get("USERPROFILE") {
    Ok(path) -> path
    Error(_) ->
      case envoy_get("HOME") {
        Ok(path) -> path
        Error(_) -> "/tmp"
      }
  }
}

@external(erlang, "envoy_ffi", "get")
fn envoy_get(name: String) -> Result(String, Nil)

/// Get the default database path
pub fn get_db_path() -> String {
  let dir = get_data_dir()
  // Use appropriate path separator
  case envoy_get("LOCALAPPDATA") {
    Ok(_) -> dir <> "\\meal-planner.db"
    Error(_) -> dir <> "/meal-planner.db"
  }
}

/// Ensure data directory exists
pub fn ensure_data_dir() -> Result(Nil, MigrateError) {
  let dir = get_data_dir()
  case simplifile.is_directory(dir) {
    Ok(True) -> Ok(Nil)
    _ ->
      simplifile.create_directory_all(dir)
      |> result.map_error(FileError)
  }
}

/// Parse migration files from a directory
pub fn parse_migrations(
  migrations_dir: String,
) -> Result(List(Migration), MigrateError) {
  case simplifile.read_directory(migrations_dir) {
    Error(e) -> Error(FileError(e))
    Ok(files) -> {
      files
      |> list.filter(fn(f) { string.ends_with(f, ".sql") })
      |> list.sort(string.compare)
      |> list.try_map(fn(filename) {
        parse_migration_file(migrations_dir <> "/" <> filename)
      })
    }
  }
}

/// Parse a single migration file
fn parse_migration_file(path: String) -> Result(Migration, MigrateError) {
  let filename =
    path
    |> string.split("/")
    |> list.last
    |> result.unwrap("")

  // Extract version number from filename (e.g., "001_name.sql" -> 1)
  case string.split(filename, "_") {
    [version_str, ..rest] -> {
      case int.parse(version_str) {
        Error(_) -> Error(ParseError("Invalid version in: " <> filename))
        Ok(version) -> {
          let name =
            rest
            |> string.join("_")
            |> string.replace(".sql", "")

          case simplifile.read(path) {
            Error(e) -> Error(FileError(e))
            Ok(sql) -> Ok(Migration(version: version, name: name, sql: sql))
          }
        }
      }
    }
    _ -> Error(ParseError("Invalid migration filename: " <> filename))
  }
}

/// Get the current schema version from the database
pub fn get_current_version(conn: sqlight.Connection) -> Int {
  let sql = "SELECT COALESCE(MAX(version), 0) FROM schema_migrations"

  let decoder = {
    use version <- decode.field(0, decode.int)
    decode.success(version)
  }

  case sqlight.query(sql, on: conn, with: [], expecting: decoder) {
    Ok([version]) -> version
    _ -> 0
  }
}

/// Record a migration as applied
fn record_migration(
  conn: sqlight.Connection,
  migration: Migration,
) -> Result(Nil, MigrateError) {
  let sql = "INSERT INTO schema_migrations (version, name) VALUES (?, ?)"

  case
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.int(migration.version), sqlight.text(migration.name)],
      expecting: decode.dynamic,
    )
  {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(_) -> Ok(Nil)
  }
}

/// Run a single migration
fn run_migration(
  conn: sqlight.Connection,
  migration: Migration,
) -> Result(Nil, MigrateError) {
  io.println(
    "Running migration "
    <> int.to_string(migration.version)
    <> ": "
    <> migration.name,
  )

  case sqlight.exec(migration.sql, on: conn) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(Nil) -> record_migration(conn, migration)
  }
}

/// Run all pending migrations
pub fn run_migrations(
  conn: sqlight.Connection,
  migrations_dir: String,
) -> Result(Int, MigrateError) {
  // First ensure schema_migrations table exists (bootstrap)
  let bootstrap_sql =
    "CREATE TABLE IF NOT EXISTS schema_migrations (
      version INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      applied_at TEXT NOT NULL DEFAULT (datetime('now'))
    )"

  case sqlight.exec(bootstrap_sql, on: conn) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(Nil) -> {
      let current_version = get_current_version(conn)

      case parse_migrations(migrations_dir) {
        Error(e) -> Error(e)
        Ok(migrations) -> {
          let pending =
            migrations
            |> list.filter(fn(m) { m.version > current_version })
            |> list.sort(fn(a, b) { int.compare(a.version, b.version) })

          case run_pending_migrations(conn, pending) {
            Error(e) -> Error(e)
            Ok(_) -> Ok(list.length(pending))
          }
        }
      }
    }
  }
}

fn run_pending_migrations(
  conn: sqlight.Connection,
  migrations: List(Migration),
) -> Result(Nil, MigrateError) {
  case migrations {
    [] -> Ok(Nil)
    [migration, ..rest] -> {
      case run_migration(conn, migration) {
        Error(e) -> Error(e)
        Ok(Nil) -> run_pending_migrations(conn, rest)
      }
    }
  }
}

/// Initialize database with migrations
pub fn init_database(migrations_dir: String) -> Result(Int, MigrateError) {
  case ensure_data_dir() {
    Error(e) -> Error(e)
    Ok(Nil) -> {
      let db_path = get_db_path()
      io.println("Database: " <> db_path)

      sqlight.with_connection(db_path, fn(conn) {
        run_migrations(conn, migrations_dir)
      })
    }
  }
}
