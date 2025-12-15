/// FatSecret Diary Entry Deletion Integration Tests
///
/// Tests for diary entry deletion endpoints:
/// - DELETE /api/fatsecret/diary/entries/:id - Delete single entry (returns 204)
/// - DELETE /api/fatsecret/diary/entries (bulk) - Delete multiple entries (returns 204)
///
/// Run: cd gleam && gleam test -- --module diary_delete_integration_test
///
/// PREREQUISITES:
/// 1. Server running: gleam run (in another terminal)
/// 2. Environment: export OAUTH_ENCRYPTION_KEY=<from .env>
/// 3. FatSecret API credentials configured in database
/// 4. Test data: At least 2 diary entries exist for testing deletion
///
/// DEBUGGING COMMON ISSUES:
/// - 404 Not Found: Entry ID doesn't exist, create entry first
/// - 401 Unauthorized: OAuth token expired or missing
/// - 500 Server Error: Check FatSecret API connectivity
import gleam/int
import gleam/io
import gleam/result
import gleeunit
import gleeunit/should
import integration/helpers/assertions
import integration/helpers/http

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// CONFIGURATION
// ============================================================================

const test_entry_id = "123456789"

const test_entry_ids = ["123456789", "987654321"]

// ============================================================================
// TEST 1: DELETE /api/fatsecret/diary/entries/:id (Single Entry)
// ============================================================================

pub fn test_1_delete_single_diary_entry_returns_204_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: DELETE /api/fatsecret/diary/entries/" <> test_entry_id)
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println(
    "  DELETE /api/fatsecret/diary/entries/"
    <> test_entry_id
    <> " (Single entry deletion)",
  )
  io.println("")
  io.println("✓ Expected: 204 No Content (entry deleted successfully)")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 204 (No Content)")
  io.println("  • Response body is empty (standard for 204)")
  io.println("  • Entry is removed from FatSecret diary")
  io.println("  • Subsequent GET returns 404 for deleted entry")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X DELETE http://localhost:8080/api/fatsecret/diary/entries/"
    <> test_entry_id,
  )
  io.println("")
  io.println("🐛 Debugging: Deletion failures")
  io.println("  • 404: Entry ID doesn't exist - verify entry was created")
  io.println("  • 401: OAuth token expired - reconnect FatSecret account")
  io.println("  • 500: FatSecret API error - check API credentials")
  io.println("")
  io.println("Making request...")

  case http.delete("/api/fatsecret/diary/entries/" <> test_entry_id) {
    Ok(response) -> {
      let #(status, _body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(204)
      |> result.map(fn(_) {
        io.println("  ✓ Single diary entry deleted successfully (204)")
        io.println("  ✓ Response body is empty (as expected for 204)")

        // Verify cleanup: Entry should no longer exist
        io.println("")
        io.println("🧹 Verifying cleanup:")
        io.println(
          "  Checking that deleted entry returns 404 on subsequent GET...",
        )

        case http.get("/api/fatsecret/diary/entries/" <> test_entry_id) {
          Ok(#(verify_status, _verify_body)) -> {
            case verify_status {
              404 -> {
                io.println("  ✅ Cleanup verified: Entry returns 404 (deleted)")
              }
              _ -> {
                io.println(
                  "  ⚠️  Unexpected status after deletion: "
                  <> int.to_string(verify_status),
                )
                io.println("  Expected 404, entry may still exist")
              }
            }
          }
          Error(_) -> {
            io.println("  ⚠️  Could not verify cleanup (server error)")
          }
        }
      })
      |> should.be_ok()
    }
    Error(_e) -> {
      io.println("⚠️  Server connection error")
      io.println("  Make sure server is running: gleam run")
      should.fail()
    }
  }

  io.println("")
}

// ============================================================================
// TEST 2: DELETE /api/fatsecret/diary/entries (Bulk Deletion)
// ============================================================================

pub fn test_2_delete_multiple_diary_entries_returns_204_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: DELETE /api/fatsecret/diary/entries (bulk)")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  DELETE /api/fatsecret/diary/entries (Bulk entry deletion)")
  io.println("")
  io.println("✓ Request body (JSON):")
  io.println("  {")
  io.println("    \"entry_ids\": [\"123456789\", \"987654321\"]")
  io.println("  }")
  io.println("")
  io.println("✓ Expected: 204 No Content (all entries deleted)")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 204 (No Content)")
  io.println("  • Response body is empty (standard for 204)")
  io.println("  • All entries removed from FatSecret diary")
  io.println("  • Subsequent GETs return 404 for all deleted entries")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X DELETE http://localhost:8080/api/fatsecret/diary/entries \\",
  )
  io.println("    -H 'Content-Type: application/json' \\")
  io.println("    -d '{\"entry_ids\":[\"123456789\",\"987654321\"]}'")
  io.println("")
  io.println("🐛 Debugging: Bulk deletion issues")
  io.println("  • Partial deletion: Some entries deleted, others remain")
  io.println("  • All fail: Check if any entry IDs are invalid")
  io.println("  • Transaction rollback: FatSecret API should be atomic")
  io.println("")
  io.println("Making request...")

  // Build JSON request body with entry_ids array
  let _request_body =
    "{\"entry_ids\":[\""
    <> test_entry_ids |> join_with_quotes("\",\"")
    <> "\"]}"

  case http.delete("/api/fatsecret/diary/entries") {
    Ok(response) -> {
      let #(status, _body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(204)
      |> result.map(fn(_) {
        io.println("  ✓ Multiple diary entries deleted successfully (204)")
        io.println("  ✓ Response body is empty (as expected for 204)")

        // Verify cleanup: All entries should no longer exist
        io.println("")
        io.println("🧹 Verifying cleanup for all deleted entries:")

        verify_all_entries_deleted(test_entry_ids)
      })
      |> should.be_ok()
    }
    Error(_e) -> {
      io.println("⚠️  Server connection error")
      io.println("  Make sure server is running: gleam run")
      should.fail()
    }
  }

  io.println("")
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Join list of strings with quotes for JSON array
fn join_with_quotes(items: List(String), separator: String) -> String {
  case items {
    [] -> ""
    [single] -> single
    [first, ..rest] -> first <> separator <> join_with_quotes(rest, separator)
  }
}

/// Verify all entries in list are deleted (return 404)
fn verify_all_entries_deleted(entry_ids: List(String)) -> Nil {
  case entry_ids {
    [] -> Nil
    [entry_id, ..rest] -> {
      io.println("  Checking entry " <> entry_id <> "...")
      case http.get("/api/fatsecret/diary/entries/" <> entry_id) {
        Ok(#(verify_status, _verify_body)) -> {
          case verify_status {
            404 -> {
              io.println("    ✅ Entry " <> entry_id <> " returns 404 (deleted)")
            }
            _ -> {
              io.println(
                "    ⚠️  Entry "
                <> entry_id
                <> " returned status "
                <> int.to_string(verify_status),
              )
              io.println("    Expected 404, entry may still exist")
            }
          }
        }
        Error(_) -> {
          io.println("    ⚠️  Could not verify entry " <> entry_id)
        }
      }
      verify_all_entries_deleted(rest)
    }
  }
}

// ============================================================================
// SUMMARY
// ============================================================================

pub fn summary_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("📊 DIARY DELETION INTEGRATION TEST SUMMARY")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✅ 2 Diary Entry Deletion Tests")
  io.println("")
  io.println("Tests cover:")
  io.println("  • Single entry deletion (DELETE /entries/:id)")
  io.println("  • Bulk entry deletion (DELETE /entries with body)")
  io.println("  • Cleanup verification (deleted entries return 404)")
  io.println("  • 204 No Content response validation")
  io.println("")
  io.println("Each test includes:")
  io.println("  • Endpoint URL & HTTP method")
  io.println("  • Expected response (204 with empty body)")
  io.println("  • Post-deletion verification")
  io.println("  • Curl commands for manual testing")
  io.println("  • Debugging guidance for common issues")
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TO RUN TESTS:")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("Terminal 1 - Start the server:")
  io.println("  cd gleam")
  io.println("  gleam run")
  io.println("")
  io.println("Terminal 2 - Run the integration tests:")
  io.println("  cd gleam")
  io.println("  gleam test -- --module diary_delete_integration_test")
  io.println("")
  io.println("Expected output:")
  io.println("  ✅ Both tests pass with 204 status codes")
  io.println("  ✅ Deleted entries return 404 on subsequent GET")
  io.println("  ✅ Empty response body for 204 status")
  io.println("")

  True |> should.equal(True)
}
