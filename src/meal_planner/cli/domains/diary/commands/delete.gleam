/// Delete commands for diary CLI domain
///
/// This module provides commands for deleting food diary entries.
import gleam/io
import meal_planner/cli/domains/diary/helpers
import meal_planner/config.{type Config}
import meal_planner/fatsecret/diary/service as diary_service
import meal_planner/fatsecret/diary/types.{food_entry_id}

/// Handle delete command - remove a food entry from diary
///
/// Deletes a single food entry identified by its ID.
pub fn delete_handler(config: Config, entry_id_str: String) -> Result(Nil, Nil) {
  case helpers.create_db_connection(config) {
    Error(err) -> {
      io.println("Error: " <> err)
      Error(Nil)
    }
    Ok(conn) -> {
      let entry_id = food_entry_id(entry_id_str)
      case diary_service.delete_food_entry(conn, entry_id) {
        Ok(_) -> {
          io.println("✓ Food entry deleted successfully")
          Ok(Nil)
        }
        Error(diary_service.NotConfigured) -> {
          io.println("Error: FatSecret is not configured")
          Error(Nil)
        }
        Error(diary_service.AuthRevoked) -> {
          io.println("Error: FatSecret authentication has been revoked")
          Error(Nil)
        }
        Error(_) -> {
          io.println("Error: Failed to delete entry: " <> entry_id_str)
          Error(Nil)
        }
      }
    }
  }
}
