/// Multipart/form-data encoding for HTTP requests
///
/// This module provides utilities to encode multipart/form-data requests,
/// which are required for file uploads in HTTP APIs like Tandoor's image upload.
///
/// ## Multipart Format
///
/// A multipart/form-data request consists of:
/// 1. Content-Type header with boundary: `multipart/form-data; boundary=----Boundary123`
/// 2. Request body with parts separated by boundaries
///
/// Each part contains:
/// - Boundary line: `------Boundary123`
/// - Content-Disposition header: `Content-Disposition: form-data; name="field_name"`
/// - Optional Content-Type header for files
/// - Blank line
/// - Field value or file content
/// - Final boundary with trailing `--`
import gleam/bit_array
import gleam/crypto
import gleam/list
import gleam/result
import gleam/string

/// Represents a single part in a multipart request
pub type MultipartPart {
  /// A text field
  TextField(name: String, value: String)
  /// A file field with binary data
  FileField(
    name: String,
    filename: String,
    content_type: String,
    data: BitArray,
  )
}

/// Multipart request data with boundary
pub type MultipartRequest {
  MultipartRequest(boundary: String, parts: List(MultipartPart))
}

/// Generate a unique boundary string for multipart requests
///
/// Uses random bytes and timestamp to create a unique boundary that's
/// unlikely to appear in the request body.
///
/// # Returns
/// A boundary string like "----gleam_boundary_abc123def456"
pub fn generate_boundary() -> String {
  // Generate random bytes for uniqueness
  let random_bytes = crypto.strong_random_bytes(16)
  let hash = crypto.hash(crypto.Sha256, random_bytes)
  let boundary_id =
    bit_array.base16_encode(hash)
    |> string.lowercase
    |> string.slice(0, 32)

  "----gleam_boundary_" <> boundary_id
}

/// Create a new multipart request with generated boundary
///
/// # Arguments
/// * `parts` - List of multipart parts (fields and files)
///
/// # Returns
/// MultipartRequest with generated boundary
///
/// # Example
/// ```gleam
/// let parts = [
///   TextField("title", "My Recipe"),
///   FileField("image", "photo.jpg", "image/jpeg", image_data)
/// ]
/// let request = new_multipart_request(parts)
/// ```
pub fn new_multipart_request(parts: List(MultipartPart)) -> MultipartRequest {
  MultipartRequest(boundary: generate_boundary(), parts: parts)
}

/// Encode a multipart request into binary data
///
/// Converts the multipart request into the proper format for HTTP transmission.
/// The result is a BitArray that can be used as the request body.
///
/// # Arguments
/// * `request` - The multipart request to encode
///
/// # Returns
/// Encoded multipart body as BitArray
///
/// # Format
/// ```
/// ------boundary
/// Content-Disposition: form-data; name="field1"
///
/// value1
/// ------boundary
/// Content-Disposition: form-data; name="file"; filename="image.jpg"
/// Content-Type: image/jpeg
///
/// [binary data]
/// ------boundary--
/// ```
pub fn encode_multipart(request: MultipartRequest) -> BitArray {
  let boundary = request.boundary
  let parts_data =
    list.map(request.parts, fn(part) { encode_part(part, boundary) })

  // Join all parts
  let body_parts = list.flatten([parts_data, [encode_final_boundary(boundary)]])

  // Combine into single BitArray
  list.fold(body_parts, <<>>, fn(acc, part) { bit_array.append(acc, part) })
}

/// Get the Content-Type header value for a multipart request
///
/// # Arguments
/// * `request` - The multipart request
///
/// # Returns
/// Content-Type header value like "multipart/form-data; boundary=----..."
///
/// # Example
/// ```gleam
/// let content_type = get_content_type(request)
/// // Returns: "multipart/form-data; boundary=----gleam_boundary_abc123"
/// ```
pub fn get_content_type(request: MultipartRequest) -> String {
  "multipart/form-data; boundary=" <> request.boundary
}

// ============================================================================
// Internal Functions
// ============================================================================

/// Encode a single multipart part
fn encode_part(part: MultipartPart, boundary: String) -> BitArray {
  case part {
    TextField(name, value) -> encode_text_field(name, value, boundary)
    FileField(name, filename, content_type, data) ->
      encode_file_field(name, filename, content_type, data, boundary)
  }
}

/// Encode a text field part
fn encode_text_field(name: String, value: String, boundary: String) -> BitArray {
  let boundary_line = "--" <> boundary <> "\r\n"
  let disposition =
    "Content-Disposition: form-data; name=\"" <> name <> "\"\r\n"
  let blank_line = "\r\n"
  let value_line = value <> "\r\n"

  let header = boundary_line <> disposition <> blank_line
  let body = value_line

  bit_array.from_string(header <> body)
}

/// Encode a file field part
fn encode_file_field(
  name: String,
  filename: String,
  content_type: String,
  data: BitArray,
  boundary: String,
) -> BitArray {
  let boundary_line = "--" <> boundary <> "\r\n"
  let disposition =
    "Content-Disposition: form-data; name=\""
    <> name
    <> "\"; filename=\""
    <> filename
    <> "\"\r\n"
  let content_type_line = "Content-Type: " <> content_type <> "\r\n"
  let blank_line = "\r\n"
  let trailing_crlf = "\r\n"

  // Build header as string
  let header = boundary_line <> disposition <> content_type_line <> blank_line

  // Combine header + data + trailing CRLF
  bit_array.from_string(header)
  |> bit_array.append(data)
  |> bit_array.append(bit_array.from_string(trailing_crlf))
}

/// Encode the final boundary marker
fn encode_final_boundary(boundary: String) -> BitArray {
  let final_boundary = "--" <> boundary <> "--\r\n"
  bit_array.from_string(final_boundary)
}

// ============================================================================
// Utility Functions
// ============================================================================

/// Detect MIME type from filename extension
///
/// # Arguments
/// * `filename` - The filename to analyze
///
/// # Returns
/// MIME type string (defaults to "application/octet-stream" if unknown)
///
/// # Supported Types
/// - .jpg, .jpeg -> image/jpeg
/// - .png -> image/png
/// - .gif -> image/gif
/// - .webp -> image/webp
/// - .svg -> image/svg+xml
/// - .bmp -> image/bmp
/// - .ico -> image/x-icon
///
/// # Example
/// ```gleam
/// detect_mime_type("photo.jpg") // "image/jpeg"
/// detect_mime_type("image.png") // "image/png"
/// ```
pub fn detect_mime_type(filename: String) -> String {
  let lower_filename = string.lowercase(filename)

  case
    string.ends_with(lower_filename, ".jpg")
    || string.ends_with(lower_filename, ".jpeg")
  {
    True -> "image/jpeg"
    False ->
      case string.ends_with(lower_filename, ".png") {
        True -> "image/png"
        False ->
          case string.ends_with(lower_filename, ".gif") {
            True -> "image/gif"
            False ->
              case string.ends_with(lower_filename, ".webp") {
                True -> "image/webp"
                False ->
                  case string.ends_with(lower_filename, ".svg") {
                    True -> "image/svg+xml"
                    False ->
                      case string.ends_with(lower_filename, ".bmp") {
                        True -> "image/bmp"
                        False ->
                          case string.ends_with(lower_filename, ".ico") {
                            True -> "image/x-icon"
                            False -> "application/octet-stream"
                          }
                      }
                  }
              }
          }
      }
  }
}

/// Convert base64 string to binary data
///
/// # Arguments
/// * `base64_string` - Base64 encoded string
///
/// # Returns
/// Result with BitArray or error message
pub fn base64_to_binary(base64_string: String) -> Result(BitArray, String) {
  bit_array.base64_decode(base64_string)
  |> result.map_error(fn(_) { "Invalid base64 encoding" })
}
