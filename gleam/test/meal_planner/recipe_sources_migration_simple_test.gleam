/// Simplified recipe_sources migration test (doesn't depend on broken test_helpers)
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/list
import gleam/option.{Some}
import gleam/string
import gleeunit/should
import pog

/// Get a test database connection
fn get_test_db() -> pog.Connection {
  let pool_name = process.new_name(prefix: "migration_test_simple")
  let result =
    pog.default_config(pool_name)
    |> pog.host("localhost")
    |> pog.port(5432)
    |> pog.database("meal_planner_test")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(1)
    |> pog.start()

  case result {
    Ok(started) -> started.data
    Error(_) -> panic as "Failed to connect to test database"
  }
}

/// Test that recipe_sources table exists
pub fn recipe_sources_table_exists_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'recipe_sources'
      );",
    )
    |> pog.returning(decode.at([0], decode.bool))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [True])) -> should.be_true(True)
    Ok(pog.Returned(_, [False])) ->
      panic as "recipe_sources table does not exist"
    Ok(_) -> panic as "Unexpected result"
    Error(e) -> panic as "Query failed"
  }
}

/// Test that recipe_sources has correct columns
pub fn recipe_sources_has_correct_columns_test() {
  let db = get_test_db()

  let decoder = {
    use column_name <- decode.field(0, decode.string)
    use data_type <- decode.field(1, decode.string)
    decode.success(#(column_name, data_type))
  }

  let query =
    pog.query(
      "SELECT column_name, data_type
       FROM information_schema.columns
       WHERE table_name = 'recipe_sources'
       ORDER BY ordinal_position;",
    )
    |> pog.returning(decoder)

  case pog.execute(query, db) {
    Ok(pog.Returned(_, columns)) -> {
      let column_count = list.length(columns)
      case column_count == 7 {
        True -> should.be_true(True)
        False ->
          panic as "Expected 7 columns"
      }
    }
    Error(e) -> panic as "Query failed"
  }
}

/// Test that primary key exists
pub fn recipe_sources_has_primary_key_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "SELECT COUNT(*)
       FROM information_schema.table_constraints
       WHERE table_name = 'recipe_sources'
       AND constraint_type = 'PRIMARY KEY';",
    )
    |> pog.returning(decode.at([0], decode.int))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [count])) ->
      case count == 1 {
        True -> should.be_true(True)
        False -> panic as "Primary key not found"
      }
    Ok(_) -> panic as "Unexpected result format"
    Error(_) -> panic as "Query failed"
  }
}

/// Test that indexes exist
pub fn recipe_sources_has_required_indexes_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "SELECT indexname FROM pg_indexes
       WHERE tablename = 'recipe_sources'
       AND (indexname = 'idx_recipe_sources_type'
            OR indexname = 'idx_recipe_sources_enabled');",
    )
    |> pog.returning(decode.at([0], decode.string))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, indexes)) ->
      case list.length(indexes) >= 2 {
        True -> should.be_true(True)
        False -> panic as "Expected at least 2 indexes"
      }
    Error(e) -> panic as "Query failed"
  }
}

fn format_error(e: pog.QueryError) -> String {
  case e {
    pog.ConstraintViolated(msg, _, _) -> "Constraint violated: " <> msg
    pog.PostgresqlError(code, _, msg) ->
      "PostgreSQL error " <> code <> ": " <> msg
    pog.UnexpectedArgumentCount(_, _) -> "Unexpected argument count"
    pog.UnexpectedArgumentType(_, _) -> "Unexpected argument type"
    pog.UnexpectedResultType(_) -> "Unexpected result type"
    pog.QueryTimeout -> "Query timeout"
    pog.ConnectionUnavailable -> "Connection unavailable"
  }
}
