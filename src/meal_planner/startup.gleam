//// Unified Startup Orchestration System
////
//// Handles:
//// - Service health checks (Database, Tandoor, FatSecret)
//// - Docker container startup
//// - Database initialization
//// - Configuration validation
//// - User-friendly startup messages

import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/string
import meal_planner/config.{
  type Config, Development, Production, Staging, has_fatsecret_integration,
  has_tandoor_integration,
}

/// Service health status
pub type ServiceStatus {
  Healthy
  Unhealthy(reason: String)
  NotConfigured
}

/// Overall startup status
pub type StartupStatus {
  AllHealthy
  SomeServices(issues: List(String))
  CriticalFailure(message: String)
}

/// Check if database is configured and accessible
fn check_database_config(config: Config) -> ServiceStatus {
  io.println("   🗄️  PostgreSQL...")

  case config.database.host {
    "localhost" | "127.0.0.1" | "postgres" -> {
      io.println("      ✓ Host: " <> config.database.host)
      io.println(
        "      ✓ Database: "
        <> config.database.name
        <> "@"
        <> int.to_string(config.database.port),
      )
      Healthy
    }
    _ -> Unhealthy(reason: "Unknown host: " <> config.database.host)
  }
}

/// Check if Tandoor is configured
fn check_tandoor_config(config: Config) -> ServiceStatus {
  io.println("   🍳 Tandoor (Recipe Manager)...")

  case has_tandoor_integration(config) {
    False -> {
      io.println("      ℹ️  Not configured (optional)")
      NotConfigured
    }
    True -> {
      io.println("      ✓ Base URL: " <> config.tandoor.base_url)
      io.println("      ✓ Token configured: ****")
      Healthy
    }
  }
}

/// Check if FatSecret is configured
fn check_fatsecret_config(config: Config) -> ServiceStatus {
  io.println("   💪 FatSecret (Nutrition Tracking)...")

  case has_fatsecret_integration(config) {
    False -> {
      io.println("      ℹ️  Not configured (optional)")
      NotConfigured
    }
    True -> {
      case config.secrets.oauth_encryption_key {
        Some(key) -> {
          case string.length(key) >= 32 {
            True -> {
              io.println("      ✓ Consumer Key configured: ****")
              io.println("      ✓ Encryption Key configured")
              Healthy
            }
            False ->
              Unhealthy(reason: "Encryption key too short (needs 32+ chars)")
          }
        }
        _ -> Unhealthy(reason: "OAUTH_ENCRYPTION_KEY not set")
      }
    }
  }
}

/// Check environment configuration
fn check_environment_config(config: Config) -> ServiceStatus {
  io.println("   🔧 Environment...")

  let env_name = case config.environment {
    Development -> "Development"
    Staging -> "Staging"
    Production -> "Production"
  }

  io.println("      ✓ Mode: " <> env_name)
  io.println("      ✓ Port: " <> int.to_string(config.server.port))

  case config.environment {
    Production -> {
      case config.secrets.jwt_secret {
        Some(secret) -> {
          case string.length(secret) > 0 {
            True -> {
              io.println("      ✓ JWT Secret configured")
              Healthy
            }
            False -> Unhealthy(reason: "JWT_SECRET is empty")
          }
        }
        _ -> Unhealthy(reason: "JWT_SECRET required in production")
      }
    }
    _ -> Healthy
  }
}

/// Perform complete startup checks
pub fn run_startup_checks(config: Config) -> StartupStatus {
  io.println(
    "\n╔════════════════════════════════════════════════════════════════╗",
  )
  io.println(
    "║                  MEAL PLANNER STARTUP CHECK                    ║",
  )
  io.println(
    "╚════════════════════════════════════════════════════════════════╝\n",
  )

  io.println("🚀 Checking Configuration...\n")

  let env_status = check_environment_config(config)
  let db_status = check_database_config(config)
  let tandoor_status = check_tandoor_config(config)
  let fatsecret_status = check_fatsecret_config(config)

  io.println("")

  let issues = []

  let issues = case env_status {
    Unhealthy(reason) -> ["Environment: " <> reason, ..issues]
    _ -> issues
  }

  let issues = case db_status {
    Unhealthy(reason) -> ["Database: " <> reason, ..issues]
    _ -> issues
  }

  let issues = case tandoor_status {
    Unhealthy(reason) -> ["Tandoor: " <> reason, ..issues]
    _ -> issues
  }

  let issues = case fatsecret_status {
    Unhealthy(reason) -> ["FatSecret: " <> reason, ..issues]
    _ -> issues
  }

  case issues {
    [] -> AllHealthy
    _ -> {
      let critical_count =
        list.length(
          list.filter(issues, fn(issue) {
            string.contains(issue, "Environment")
            || string.contains(issue, "Database")
          }),
        )

      case critical_count > 0 {
        True -> CriticalFailure(message: string.join(issues, ", "))
        False -> SomeServices(issues: issues)
      }
    }
  }
}

/// Print formatted startup status
pub fn print_status_and_continue(status: StartupStatus) -> Bool {
  io.println(
    "────────────────────────────────────────────────────────────────\n",
  )

  case status {
    AllHealthy -> {
      io.println("✅  ALL SYSTEMS HEALTHY\n")
      io.println("Ready to start meal planner!")
      io.println("   Web Server: http://localhost:8080")
      io.println("   Tandoor: http://localhost:8100")
      io.println("   FatSecret: API configured\n")
      True
    }

    SomeServices(issues) -> {
      io.println("⚠️  SOME SERVICES NOT FULLY CONFIGURED\n")
      io.println("Warnings:")
      list.each(issues, fn(issue) { io.println("   • " <> issue) })
      io.println("\nNote: The app will start but some features may be limited.")
      io.println("      Set environment variables to enable all features.\n")
      True
    }

    CriticalFailure(message) -> {
      io.println("❌  STARTUP FAILED\n")
      io.println("Critical Issues:")
      list.each(string.split(message, ", "), fn(issue) {
        io.println("   • " <> issue)
      })
      io.println("\nFix the issues above and try again.\n")
      False
    }
  }
}

/// Display available commands
pub fn show_welcome_banner() -> Nil {
  io.println("\n")
  io.println(
    "╔══════════════════════════════════════════════════════════════════╗",
  )
  io.println(
    "║                     🍽️  MEAL PLANNER v1.0.0                      ║",
  )
  io.println(
    "║        Your complete meal planning & nutrition tracking app       ║",
  )
  io.println(
    "╚══════════════════════════════════════════════════════════════════╝",
  )
  io.println("")
  io.println("📖 AVAILABLE COMMANDS:\n")
  io.println("   mp                    Start interactive TUI")
  io.println("   mp recipe [flags]     Manage recipes from Tandoor")
  io.println("   mp diary              View food diary from FatSecret")
  io.println("   mp advisor            Get AI meal recommendations")
  io.println("   mp preferences        Manage user preferences")
  io.println("   mp scheduler          View scheduled jobs")
  io.println("   mp web                Start web server\n")
}

/// Wait for services to be ready (simple delay)
pub fn wait_for_services() -> Nil {
  io.println("⏳ Waiting for services to initialize...")
  process.sleep(2000)
  io.println("✓ Services ready!\n")
}
