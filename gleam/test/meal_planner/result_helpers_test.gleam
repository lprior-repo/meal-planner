import gleeunit/should
import meal_planner/result_helpers
import meal_planner/storage/profile.{DatabaseError}
import pog

pub fn result_to_storage_error_with_ok_test() {
  // Test that Ok values pass through unchanged
  let result = Ok(42)
  let converted = result_helpers.result_to_storage_error(result)

  should.equal(converted, Ok(42))
}

pub fn result_to_storage_error_with_postgresql_error_test() {
  // Test that pog.PostgresqlError is converted to DatabaseError
  let pog_error =
    pog.PostgresqlError("23505", "unique_violation", "duplicate key")
  let result: Result(Int, pog.QueryError) = Error(pog_error)
  let converted = result_helpers.result_to_storage_error(result)

  // Should be converted to DatabaseError with formatted message
  case converted {
    Error(DatabaseError(msg)) -> {
      should.equal(msg, "PostgreSQL error: duplicate key")
    }
    _ -> should.fail()
  }
}

pub fn result_to_storage_error_with_connection_unavailable_test() {
  // Test ConnectionUnavailable error
  let pog_error = pog.ConnectionUnavailable
  let result: Result(String, pog.QueryError) = Error(pog_error)
  let converted = result_helpers.result_to_storage_error(result)

  case converted {
    Error(DatabaseError(msg)) -> {
      should.equal(msg, "Database connection unavailable")
    }
    _ -> should.fail()
  }
}

pub fn result_to_storage_error_with_unexpected_result_type_test() {
  // Test UnexpectedResultType error
  let decoder_errors = []
  let pog_error = pog.UnexpectedResultType(decoder_errors)
  let result: Result(Bool, pog.QueryError) = Error(pog_error)
  let converted = result_helpers.result_to_storage_error(result)

  case converted {
    Error(DatabaseError(msg)) -> {
      should.equal(msg, "Decode error: ")
    }
    _ -> should.fail()
  }
}
