//// Integration tests for Tandoor Import/Export API endpoints
////
//// Tests CRUD operations for import_logs and export_logs.
//// Tests skip gracefully if Tandoor is not configured.
////
//// Follows TCR workflow: RED -> GREEN -> REFACTOR

import gleam/option.{None, Some}
import gleeunit/should
import integration/harness
import meal_planner/tandoor/api/import_export/import_export_api
import meal_planner/tandoor/client
import meal_planner/tandoor/encoders/import_export/export_log_encoder.{
  ExportLogCreateRequest, ExportLogUpdateRequest,
}
import meal_planner/tandoor/encoders/import_export/import_log_encoder.{
  ImportLogCreateRequest, ImportLogUpdateRequest,
}

// ============================================================================
// Import Logs Tests (5 tests: list, get, create, update, delete)
// ============================================================================

/// Test listing import logs with pagination
pub fn import_logs_list_test() {
  let context = harness.setup()

  let result =
    harness.skip_if_unavailable(context, "tandoor", fn(ctx) {
      let config =
        client.bearer_config(
          ctx.credentials.tandoor.base_url,
          ctx.credentials.tandoor.username,
        )

      case
        import_export_api.list_import_logs(
          config,
          limit: Some(10),
          offset: Some(0),
        )
      {
        Ok(log_list) -> {
          // Verify pagination response structure
          should.be_true(log_list.count >= 0)
          Ok(Nil)
        }
        Error(err) ->
          Error("Failed to list import logs: " <> client.error_to_string(err))
      }
    })

  // Result should be Ok or graceful skip
  case result {
    Ok(_) -> should.be_true(True)
    Error(msg) -> {
      // If it's a skip message, that's fine
      case msg {
        "Skipping - Tandoor not configured" -> should.be_true(True)
        _ -> should.fail()
      }
    }
  }
}

/// Test getting a specific import log by ID
pub fn import_logs_get_test() {
  let context = harness.setup()

  let result =
    harness.skip_if_unavailable(context, "tandoor", fn(ctx) {
      let config =
        client.bearer_config(
          ctx.credentials.tandoor.base_url,
          ctx.credentials.tandoor.username,
        )

      // First create a log to ensure we have something to get
      let create_request =
        ImportLogCreateRequest(
          import_type: "test",
          msg: Some("Test import log"),
          keyword: None,
        )

      case import_export_api.create_import_log(config, create_request) {
        Ok(created_log) -> {
          // Now get the log by ID
          case
            import_export_api.get_import_log(config, log_id: created_log.id)
          {
            Ok(fetched_log) -> {
              should.equal(fetched_log.id, created_log.id)
              should.equal(fetched_log.import_type, "test")
              Ok(Nil)
            }
            Error(err) ->
              Error("Failed to get import log: " <> client.error_to_string(err))
          }
        }
        Error(err) ->
          Error("Failed to create import log: " <> client.error_to_string(err))
      }
    })

  // Result should be Ok or graceful skip
  case result {
    Ok(_) -> should.be_true(True)
    Error(msg) -> {
      case msg {
        "Skipping - Tandoor not configured" -> should.be_true(True)
        _ -> should.fail()
      }
    }
  }
}

/// Test creating an import log
pub fn import_logs_create_test() {
  let context = harness.setup()

  let result =
    harness.skip_if_unavailable(context, "tandoor", fn(ctx) {
      let config =
        client.bearer_config(
          ctx.credentials.tandoor.base_url,
          ctx.credentials.tandoor.username,
        )

      let create_request =
        ImportLogCreateRequest(
          import_type: "nextcloud",
          msg: Some("Starting Nextcloud import"),
          keyword: None,
        )

      case import_export_api.create_import_log(config, create_request) {
        Ok(created_log) -> {
          should.be_true(created_log.id > 0)
          should.equal(created_log.import_type, "nextcloud")
          should.equal(created_log.msg, "Starting Nextcloud import")
          Ok(Nil)
        }
        Error(err) ->
          Error("Failed to create import log: " <> client.error_to_string(err))
      }
    })

  case result {
    Ok(_) -> should.be_true(True)
    Error(msg) -> {
      case msg {
        "Skipping - Tandoor not configured" -> should.be_true(True)
        _ -> should.fail()
      }
    }
  }
}

/// Test updating an import log
pub fn import_logs_update_test() {
  let context = harness.setup()

  let result =
    harness.skip_if_unavailable(context, "tandoor", fn(ctx) {
      let config =
        client.bearer_config(
          ctx.credentials.tandoor.base_url,
          ctx.credentials.tandoor.username,
        )

      // First create a log
      let create_request =
        ImportLogCreateRequest(
          import_type: "test",
          msg: Some("Initial message"),
          keyword: None,
        )

      case import_export_api.create_import_log(config, create_request) {
        Ok(created_log) -> {
          // Now update it
          let update_request =
            ImportLogUpdateRequest(
              import_type: None,
              msg: Some("Updated message"),
              running: Some(False),
              keyword: None,
            )

          case
            import_export_api.update_import_log(
              config,
              update_request,
              log_id: created_log.id,
            )
          {
            Ok(updated_log) -> {
              should.equal(updated_log.id, created_log.id)
              should.equal(updated_log.msg, "Updated message")
              should.equal(updated_log.running, False)
              Ok(Nil)
            }
            Error(err) ->
              Error(
                "Failed to update import log: " <> client.error_to_string(err),
              )
          }
        }
        Error(err) ->
          Error("Failed to create import log: " <> client.error_to_string(err))
      }
    })

  case result {
    Ok(_) -> should.be_true(True)
    Error(msg) -> {
      case msg {
        "Skipping - Tandoor not configured" -> should.be_true(True)
        _ -> should.fail()
      }
    }
  }
}

/// Test deleting an import log
pub fn import_logs_delete_test() {
  let context = harness.setup()

  let result =
    harness.skip_if_unavailable(context, "tandoor", fn(ctx) {
      let config =
        client.bearer_config(
          ctx.credentials.tandoor.base_url,
          ctx.credentials.tandoor.username,
        )

      // First create a log
      let create_request =
        ImportLogCreateRequest(
          import_type: "test",
          msg: Some("To be deleted"),
          keyword: None,
        )

      case import_export_api.create_import_log(config, create_request) {
        Ok(created_log) -> {
          // Now delete it
          case
            import_export_api.delete_import_log(config, log_id: created_log.id)
          {
            Ok(Nil) -> {
              // Verify deletion by trying to get it (should fail)
              case
                import_export_api.get_import_log(config, log_id: created_log.id)
              {
                Ok(_) -> Error("Import log still exists after deletion")
                Error(_) -> Ok(Nil)
                // Expected - log should not exist
              }
            }
            Error(err) ->
              Error(
                "Failed to delete import log: " <> client.error_to_string(err),
              )
          }
        }
        Error(err) ->
          Error("Failed to create import log: " <> client.error_to_string(err))
      }
    })

  case result {
    Ok(_) -> should.be_true(True)
    Error(msg) -> {
      case msg {
        "Skipping - Tandoor not configured" -> should.be_true(True)
        _ -> should.fail()
      }
    }
  }
}

// ============================================================================
// Export Logs Tests (5 tests: list, get, create, update, delete)
// ============================================================================

/// Test listing export logs with pagination
pub fn export_logs_list_test() {
  let context = harness.setup()

  let result =
    harness.skip_if_unavailable(context, "tandoor", fn(ctx) {
      let config =
        client.bearer_config(
          ctx.credentials.tandoor.base_url,
          ctx.credentials.tandoor.username,
        )

      case
        import_export_api.list_export_logs(
          config,
          limit: Some(10),
          offset: Some(0),
        )
      {
        Ok(log_list) -> {
          // Verify pagination response structure
          should.be_true(log_list.count >= 0)
          Ok(Nil)
        }
        Error(err) ->
          Error("Failed to list export logs: " <> client.error_to_string(err))
      }
    })

  case result {
    Ok(_) -> should.be_true(True)
    Error(msg) -> {
      case msg {
        "Skipping - Tandoor not configured" -> should.be_true(True)
        _ -> should.fail()
      }
    }
  }
}

/// Test getting a specific export log by ID
pub fn export_logs_get_test() {
  let context = harness.setup()

  let result =
    harness.skip_if_unavailable(context, "tandoor", fn(ctx) {
      let config =
        client.bearer_config(
          ctx.credentials.tandoor.base_url,
          ctx.credentials.tandoor.username,
        )

      // First create a log to ensure we have something to get
      let create_request =
        ExportLogCreateRequest(
          export_type: "test",
          msg: Some("Test export log"),
          cache_duration: None,
        )

      case import_export_api.create_export_log(config, create_request) {
        Ok(created_log) -> {
          // Now get the log by ID
          case
            import_export_api.get_export_log(config, log_id: created_log.id)
          {
            Ok(fetched_log) -> {
              should.equal(fetched_log.id, created_log.id)
              should.equal(fetched_log.export_type, "test")
              Ok(Nil)
            }
            Error(err) ->
              Error("Failed to get export log: " <> client.error_to_string(err))
          }
        }
        Error(err) ->
          Error("Failed to create export log: " <> client.error_to_string(err))
      }
    })

  case result {
    Ok(_) -> should.be_true(True)
    Error(msg) -> {
      case msg {
        "Skipping - Tandoor not configured" -> should.be_true(True)
        _ -> should.fail()
      }
    }
  }
}

/// Test creating an export log
pub fn export_logs_create_test() {
  let context = harness.setup()

  let result =
    harness.skip_if_unavailable(context, "tandoor", fn(ctx) {
      let config =
        client.bearer_config(
          ctx.credentials.tandoor.base_url,
          ctx.credentials.tandoor.username,
        )

      let create_request =
        ExportLogCreateRequest(
          export_type: "zip",
          msg: Some("Starting ZIP export"),
          cache_duration: Some(3600),
        )

      case import_export_api.create_export_log(config, create_request) {
        Ok(created_log) -> {
          should.be_true(created_log.id > 0)
          should.equal(created_log.export_type, "zip")
          should.equal(created_log.msg, "Starting ZIP export")
          Ok(Nil)
        }
        Error(err) ->
          Error("Failed to create export log: " <> client.error_to_string(err))
      }
    })

  case result {
    Ok(_) -> should.be_true(True)
    Error(msg) -> {
      case msg {
        "Skipping - Tandoor not configured" -> should.be_true(True)
        _ -> should.fail()
      }
    }
  }
}

/// Test updating an export log
pub fn export_logs_update_test() {
  let context = harness.setup()

  let result =
    harness.skip_if_unavailable(context, "tandoor", fn(ctx) {
      let config =
        client.bearer_config(
          ctx.credentials.tandoor.base_url,
          ctx.credentials.tandoor.username,
        )

      // First create a log
      let create_request =
        ExportLogCreateRequest(
          export_type: "test",
          msg: Some("Initial message"),
          cache_duration: Some(1800),
        )

      case import_export_api.create_export_log(config, create_request) {
        Ok(created_log) -> {
          // Now update it
          let update_request =
            ExportLogUpdateRequest(
              export_type: None,
              msg: Some("Updated message"),
              running: Some(False),
              cache_duration: Some(7200),
            )

          case
            import_export_api.update_export_log(
              config,
              update_request,
              log_id: created_log.id,
            )
          {
            Ok(updated_log) -> {
              should.equal(updated_log.id, created_log.id)
              should.equal(updated_log.msg, "Updated message")
              should.equal(updated_log.running, False)
              Ok(Nil)
            }
            Error(err) ->
              Error(
                "Failed to update export log: " <> client.error_to_string(err),
              )
          }
        }
        Error(err) ->
          Error("Failed to create export log: " <> client.error_to_string(err))
      }
    })

  case result {
    Ok(_) -> should.be_true(True)
    Error(msg) -> {
      case msg {
        "Skipping - Tandoor not configured" -> should.be_true(True)
        _ -> should.fail()
      }
    }
  }
}

/// Test deleting an export log
pub fn export_logs_delete_test() {
  let context = harness.setup()

  let result =
    harness.skip_if_unavailable(context, "tandoor", fn(ctx) {
      let config =
        client.bearer_config(
          ctx.credentials.tandoor.base_url,
          ctx.credentials.tandoor.username,
        )

      // First create a log
      let create_request =
        ExportLogCreateRequest(
          export_type: "test",
          msg: Some("To be deleted"),
          cache_duration: None,
        )

      case import_export_api.create_export_log(config, create_request) {
        Ok(created_log) -> {
          // Now delete it
          case
            import_export_api.delete_export_log(config, log_id: created_log.id)
          {
            Ok(Nil) -> {
              // Verify deletion by trying to get it (should fail)
              case
                import_export_api.get_export_log(config, log_id: created_log.id)
              {
                Ok(_) -> Error("Export log still exists after deletion")
                Error(_) -> Ok(Nil)
                // Expected - log should not exist
              }
            }
            Error(err) ->
              Error(
                "Failed to delete export log: " <> client.error_to_string(err),
              )
          }
        }
        Error(err) ->
          Error("Failed to create export log: " <> client.error_to_string(err))
      }
    })

  case result {
    Ok(_) -> should.be_true(True)
    Error(msg) -> {
      case msg {
        "Skipping - Tandoor not configured" -> should.be_true(True)
        _ -> should.fail()
      }
    }
  }
}
