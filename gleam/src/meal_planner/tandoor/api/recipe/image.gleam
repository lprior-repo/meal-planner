/// Recipe Image API
///
/// This module provides functions to upload images to recipes in the Tandoor API.
///
/// ## Current Limitations
///
/// Image upload in Tandoor requires `multipart/form-data` encoding, which is not
/// currently supported by the Gleam HTTP client (gleam_httpc).
///
/// **Workarounds:**
/// 1. Use the Tandoor web UI for image uploads
/// 2. Use a different HTTP client library with multipart support
/// 3. Use external command-line tools (curl) via process execution
///
/// This module provides a stub implementation that returns an error explaining
/// the limitation, maintaining a complete API surface for future enhancement.
import gleam/int
import meal_planner/tandoor/client.{
  type ClientConfig, type Recipe, type TandoorError,
}

/// Upload an image to a recipe in Tandoor API
///
/// **Note:** This function currently returns an error because Tandoor's image
/// upload endpoint requires `multipart/form-data` encoding, which is not yet
/// supported by gleam_httpc.
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `recipe_id` - The ID of the recipe to add image to
/// * `image_data` - Image data (base64 encoded string)
///
/// # Returns
/// Error explaining multipart/form-data requirement
///
/// # Example
/// ```gleam
/// let result = upload_recipe_image(config, 123, base64_image)
/// // Returns: Error(BadRequestError("Image upload requires multipart/form-data..."))
/// ```
///
/// # Future Implementation
/// When multipart support is added, this function will:
/// 1. Accept image as base64 string or binary data
/// 2. Construct multipart/form-data request with image field
/// 3. POST to `/api/recipe/{id}/image/`
/// 4. Return updated recipe with image URL
pub fn upload_recipe_image(
  _config: ClientConfig,
  recipe_id: Int,
  _image_data: String,
) -> Result(Recipe, TandoorError) {
  let endpoint = "/api/recipe/" <> int.to_string(recipe_id) <> "/image/"

  Error(client.BadRequestError(
    "Image upload is not yet supported. Tandoor endpoint "
    <> endpoint
    <> " requires multipart/form-data encoding, which is not available in gleam_httpc. "
    <> "Please use the Tandoor web UI for image uploads, or implement multipart support using a different HTTP client library.",
  ))
}

/// Upload an image from a file path to a recipe in Tandoor API
///
/// **Note:** This function currently returns an error for the same reason as
/// `upload_recipe_image` - multipart/form-data is not yet supported.
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `recipe_id` - The ID of the recipe to add image to
/// * `file_path` - Path to image file on disk
///
/// # Returns
/// Error explaining multipart/form-data requirement
///
/// # Future Implementation
/// When implemented, this function will:
/// 1. Read image file from disk
/// 2. Detect MIME type from file extension
/// 3. Construct multipart/form-data request
/// 4. Upload to Tandoor API
pub fn upload_recipe_image_from_file(
  _config: ClientConfig,
  recipe_id: Int,
  _file_path: String,
) -> Result(Recipe, TandoorError) {
  let endpoint = "/api/recipe/" <> int.to_string(recipe_id) <> "/image/"

  Error(client.BadRequestError(
    "Image upload from file is not yet supported. Tandoor endpoint "
    <> endpoint
    <> " requires multipart/form-data encoding, which is not available in gleam_httpc. "
    <> "Please use the Tandoor web UI for image uploads.",
  ))
}

/// Delete an image from a recipe in Tandoor API
///
/// **Note:** This function may also require special handling. Implementation
/// pending investigation of Tandoor's image deletion API.
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `recipe_id` - The ID of the recipe to remove image from
///
/// # Returns
/// Result with unit or error
pub fn delete_recipe_image(
  _config: ClientConfig,
  recipe_id: Int,
) -> Result(Nil, TandoorError) {
  let endpoint = "/api/recipe/" <> int.to_string(recipe_id) <> "/image/"

  Error(client.BadRequestError(
    "Image deletion is not yet implemented. Endpoint "
    <> endpoint
    <> " requires investigation. Please use the Tandoor web UI to delete recipe images.",
  ))
}
