/// Restore meal_planner database from pg_dump
/// Downloads from GitHub Release if not present locally
///
/// Run with: gleam run -m scripts/restore_db

import envoy
import gleam/io
import gleam/list
import gleam/string
import simplifile

const dump_url = "https://github.com/lprior-repo/meal-planner/releases/download/v1.0.0/meal_planner.dump"

const db_name = "meal_planner"

pub fn main() {
  io.println("=== Meal Planner Database Restore ===")
  io.println("")

  let dump_file = get_dump_path()
  io.println("Dump file: " <> dump_file)

  // Check if dump file exists, download if not
  case simplifile.is_file(dump_file) {
    Ok(True) -> {
      io.println("Found local dump file")
    }
    _ -> {
      io.println("Downloading database dump from GitHub...")
      case download_dump(dump_file) {
        Ok(_) -> io.println("Download complete!")
        Error(e) -> {
          io.println("Download failed: " <> e)
          io.println("")
          io.println("Please download manually from:")
          io.println("  " <> dump_url)
          io.println("And save to:")
          io.println("  " <> dump_file)
          panic
        }
      }
    }
  }

  io.println("")

  // Get psql and pg_restore paths
  let pg_bin = get_pg_bin_path()
  let psql = pg_bin <> "psql"
  let pg_restore = pg_bin <> "pg_restore"

  // Drop and create database
  io.println("Dropping existing database...")
  case run_command(psql, ["-h", "localhost", "-U", "postgres", "-c", "DROP DATABASE IF EXISTS " <> db_name]) {
    Ok(_) -> Nil
    Error(e) -> {
      io.println("Warning: " <> e)
    }
  }

  io.println("Creating database...")
  case run_command(psql, ["-h", "localhost", "-U", "postgres", "-c", "CREATE DATABASE " <> db_name]) {
    Ok(_) -> Nil
    Error(e) -> {
      io.println("Failed to create database: " <> e)
      panic
    }
  }

  io.println("")
  io.println("Restoring database (this may take a few minutes)...")
  io.println("Using 4 parallel jobs for faster restore...")
  io.println("")

  // Restore with parallel jobs
  case run_command(pg_restore, ["-h", "localhost", "-U", "postgres", "-d", db_name, "-j", "4", dump_file]) {
    Ok(_) -> Nil
    Error(e) -> {
      // pg_restore returns non-zero even on warnings, check if data was restored
      io.println("Restore completed with warnings: " <> e)
    }
  }

  io.println("")
  io.println("Verifying restore...")

  // Verify the restore
  case run_command(psql, [
    "-h", "localhost", "-U", "postgres", "-d", db_name,
    "-c", "SELECT 'Nutrients' as tbl, count(*) FROM nutrients UNION ALL SELECT 'Foods', count(*) FROM foods UNION ALL SELECT 'Food Nutrients', count(*) FROM food_nutrients"
  ]) {
    Ok(output) -> {
      io.println(output)
      io.println("")
      io.println("=== Database Restore Complete! ===")
    }
    Error(e) -> {
      io.println("Verification failed: " <> e)
    }
  }
}

fn get_dump_path() -> String {
  case envoy.get("LOCALAPPDATA") {
    Ok(local_app_data) -> local_app_data <> "\\meal-planner\\meal_planner.dump"
    Error(_) -> {
      case envoy.get("HOME") {
        Ok(home) -> home <> "/.local/share/meal-planner/meal_planner.dump"
        Error(_) -> "/tmp/meal-planner/meal_planner.dump"
      }
    }
  }
}

fn get_pg_bin_path() -> String {
  // Try common PostgreSQL installation paths
  case envoy.get("LOCALAPPDATA") {
    Ok(_) -> {
      // Windows - try common paths
      let paths = [
        "C:\\Program Files\\PostgreSQL\\17\\bin\\",
        "C:\\Program Files\\PostgreSQL\\16\\bin\\",
        "C:\\Program Files\\PostgreSQL\\15\\bin\\",
      ]
      case list.find(paths, fn(p) {
        case simplifile.is_file(p <> "psql.exe") {
          Ok(True) -> True
          _ -> False
        }
      }) {
        Ok(path) -> path
        Error(_) -> ""  // Hope it's in PATH
      }
    }
    Error(_) -> ""  // Unix - assume psql is in PATH
  }
}

fn download_dump(dest: String) -> Result(Nil, String) {
  // Ensure directory exists
  let dir = string.replace(dest, "\\meal_planner.dump", "")
  let dir = string.replace(dir, "/meal_planner.dump", "")
  case simplifile.create_directory_all(dir) {
    Error(_) -> Error("Failed to create directory: " <> dir)
    Ok(_) -> {
      // Use curl or Invoke-WebRequest depending on platform
      case envoy.get("LOCALAPPDATA") {
        Ok(_) -> {
          // Windows - use PowerShell
          case run_command("powershell", [
            "-Command",
            "Invoke-WebRequest -Uri '" <> dump_url <> "' -OutFile '" <> dest <> "'"
          ]) {
            Ok(_) -> Ok(Nil)
            Error(e) -> Error(e)
          }
        }
        Error(_) -> {
          // Unix - use curl
          case run_command("curl", ["-L", "-o", dest, dump_url]) {
            Ok(_) -> Ok(Nil)
            Error(e) -> Error(e)
          }
        }
      }
    }
  }
}

/// Run a shell command and return output
fn run_command(cmd: String, args: List(String)) -> Result(String, String) {
  // Set PGPASSWORD environment variable
  set_env("PGPASSWORD", "postgres")

  let args_str = string.join(args, " ")
  let full_cmd = cmd <> " " <> args_str

  case os_cmd(full_cmd) {
    output -> {
      let trimmed = string.trim(output)
      case string.contains(string.lowercase(trimmed), "error") {
        True -> Error(trimmed)
        False -> Ok(trimmed)
      }
    }
  }
}

@external(erlang, "os", "cmd")
fn os_cmd(cmd: String) -> String

@external(erlang, "os", "putenv")
fn os_putenv(key: String, value: String) -> Bool

fn set_env(key: String, value: String) -> Nil {
  os_putenv(key, value)
  Nil
}
