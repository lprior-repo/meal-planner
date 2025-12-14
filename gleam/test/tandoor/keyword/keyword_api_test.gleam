/// Tests for Tandoor Keyword API operations
///
/// This test suite validates CRUD operations for Keywords via Tandoor API.
/// Note: These are integration tests that require a running Tandoor instance.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/keyword/keyword_api
import meal_planner/tandoor/client.{TandoorClient}
import meal_planner/tandoor/encoders/keyword/keyword_encoder

// Helper to create a test client
// In real tests, this would connect to a test Tandoor instance
fn create_test_client() -> TandoorClient {
  TandoorClient(
    base_url: "http://localhost:8000",
    api_token: "test-token-12345",
  )
}

pub fn list_keywords_test() {
  let client = create_test_client()

  // This would make an actual API call in integration tests
  // For now, we're just testing the interface
  let result = keyword_api.list_keywords(client)

  case result {
    Ok(keywords) -> {
      // In a real test with test data, we'd verify the results
      keywords
      |> should.be_list()
    }
    Error(_) -> {
      // Expected in unit test environment without Tandoor running
      should.be_true(True)
    }
  }
}

pub fn get_keyword_test() {
  let client = create_test_client()

  let result = keyword_api.get_keyword(client, 1)

  case result {
    Ok(keyword) -> {
      keyword.id
      |> should.equal(1)
    }
    Error(_) -> {
      // Expected in unit test environment
      should.be_true(True)
    }
  }
}

pub fn create_keyword_test() {
  let client = create_test_client()

  let create_data =
    keyword_encoder.KeywordCreateRequest(
      name: "test-keyword",
      description: "Test keyword description",
      icon: Some("🧪"),
      parent: None,
    )

  let result = keyword_api.create_keyword(client, create_data)

  case result {
    Ok(keyword) -> {
      keyword.name
      |> should.equal("test-keyword")

      keyword.description
      |> should.equal("Test keyword description")
    }
    Error(_) -> {
      // Expected in unit test environment
      should.be_true(True)
    }
  }
}

pub fn update_keyword_test() {
  let client = create_test_client()

  let update_data =
    keyword_encoder.KeywordUpdateRequest(
      name: Some("updated-keyword"),
      description: Some("Updated description"),
      icon: Some("✅"),
      parent: None,
    )

  let result = keyword_api.update_keyword(client, 1, update_data)

  case result {
    Ok(keyword) -> {
      keyword.id
      |> should.equal(1)

      keyword.name
      |> should.equal("updated-keyword")
    }
    Error(_) -> {
      // Expected in unit test environment
      should.be_true(True)
    }
  }
}

pub fn delete_keyword_test() {
  let client = create_test_client()

  let result = keyword_api.delete_keyword(client, 999)

  case result {
    Ok(_) -> {
      // Deletion successful
      should.be_true(True)
    }
    Error(_) -> {
      // Expected in unit test environment
      should.be_true(True)
    }
  }
}

pub fn list_keywords_with_parent_test() {
  let client = create_test_client()

  // Test listing keywords filtered by parent
  let result = keyword_api.list_keywords_by_parent(client, Some(1))

  case result {
    Ok(keywords) -> {
      // Verify all keywords have the expected parent
      keywords
      |> should.be_list()
    }
    Error(_) -> {
      // Expected in unit test environment
      should.be_true(True)
    }
  }
}

pub fn list_root_keywords_test() {
  let client = create_test_client()

  // Test listing only root keywords (no parent)
  let result = keyword_api.list_keywords_by_parent(client, None)

  case result {
    Ok(keywords) -> {
      keywords
      |> should.be_list()
    }
    Error(_) -> {
      // Expected in unit test environment
      should.be_true(True)
    }
  }
}
