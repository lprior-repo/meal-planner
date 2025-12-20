/// Plan CLI domain - meal plan synchronization
import gleam/int
import gleam/io
import glint
import meal_planner/config.{type Config}
import meal_planner/id
import meal_planner/scheduler/sync_scheduler

pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Sync meal plans with FatSecret diary")
  use _named, unnamed, _flags <- glint.command()

  case unnamed {
    ["sync"] -> {
      io.println("Syncing FatSecret diary with meal plans...")

      // Create a dummy user ID for now (would come from auth in production)
      let user_id = id.user_id("default_user")

      // Trigger the sync
      case sync_scheduler.trigger_auto_sync(user_id) {
        Ok(result) -> {
          io.println(
            "Sync complete: "
            <> "synced="
            <> int.to_string(result.synced)
            <> ", skipped="
            <> int.to_string(result.skipped)
            <> ", failed="
            <> int.to_string(result.failed),
          )
          Ok(Nil)
        }
        Error(_) -> {
          io.println("Error: Sync failed")
          Error(Nil)
        }
      }
    }
    _ -> {
      io.println("Plan commands:")
      io.println("  mp plan sync")
      let _ = config
      Ok(Nil)
    }
  }
}
