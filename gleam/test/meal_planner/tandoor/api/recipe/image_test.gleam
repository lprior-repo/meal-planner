/// Tests for Recipe Image API
///
/// These tests verify that the image API functions exist and return appropriate
/// error messages explaining the multipart/form-data limitation.
import gleam/string
import gleeunit/should
import meal_planner/tandoor/api/recipe/image
import meal_planner/tandoor/client

pub fn upload_recipe_image_returns_error_test() {
  // Setup: Create a test config (doesn't matter since we return error immediately)
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Execute: Try to upload an image
  let result = image.upload_recipe_image(config, 123, "base64data")

  // Verify: Should return BadRequestError explaining the limitation
  case result {
    Error(client.BadRequestError(msg)) -> {
      msg
      |> string.contains("multipart/form-data")
      |> should.be_true()

      msg
      |> string.contains("/api/recipe/123/image/")
      |> should.be_true()

      msg
      |> string.contains("not yet supported")
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

pub fn upload_recipe_image_from_file_returns_error_test() {
  // Setup: Create a test config
  let config = client.session_config("http://localhost:8000", "user", "pass")

  // Execute: Try to upload from file
  let result =
    image.upload_recipe_image_from_file(config, 456, "/path/to/image.jpg")

  // Verify: Should return BadRequestError explaining the limitation
  case result {
    Error(client.BadRequestError(msg)) -> {
      msg
      |> string.contains("multipart/form-data")
      |> should.be_true()

      msg
      |> string.contains("/api/recipe/456/image/")
      |> should.be_true()

      msg
      |> string.contains("not yet supported")
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

pub fn delete_recipe_image_returns_error_test() {
  // Setup: Create a test config
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Execute: Try to delete image
  let result = image.delete_recipe_image(config, 789)

  // Verify: Should return BadRequestError explaining the limitation
  case result {
    Error(client.BadRequestError(msg)) -> {
      msg
      |> string.contains("/api/recipe/789/image/")
      |> should.be_true()

      msg
      |> string.contains("not yet implemented")
      |> should.be_true()
    }
    _ -> should.fail()
  }
}
