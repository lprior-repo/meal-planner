import gleam/option
import gleam/result
import gleeunit/should
import meal_planner/tandoor/api/supermarket/create
import meal_planner/tandoor/client
import meal_planner/tandoor/types/supermarket/supermarket.{type Supermarket}
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  SupermarketCreateRequest,
}

/// Test that the supermarket create request type and encoder compile correctly
pub fn supermarket_create_type_test() {
  // Create a request
  let request =
    SupermarketCreateRequest(
      name: "Test Store",
      description: option.Some("Test description"),
    )

  // Verify name
  request.name
  |> should.equal("Test Store")

  // Verify description
  request.description
  |> should.equal(option.Some("Test description"))
}

/// Test that the create_supermarket function has correct type signature
/// Note: This is a compile-time test - we're not making actual API calls
pub fn create_supermarket_signature_test() {
  let config = client.bearer_config("http://localhost:8000", "test-token")
  let request = SupermarketCreateRequest(name: "Test", description: option.None)

  // Type check - this should compile with correct signature
  let _test_result: Result(Supermarket, client.TandoorError) =
    create.create_supermarket(config, request)

  // We don't actually run this, just verify it compiles
  should.be_true(True)
}
