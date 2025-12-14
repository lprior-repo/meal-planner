/// Tandoor SDK Core - Pagination Types and Decoders
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/uri

pub type PaginatedResponse(a) {
  PaginatedResponse(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(a),
  )
}

pub type PageParams {
  PageParams(page: Int, page_size: Int)
}

/// Pagination parameters for building requests
pub type PaginationParams {
  PaginationParams(limit: Option(Int), offset: Option(Int))
}

pub fn paginated_decoder(
  item_decoder: decode.Decoder(a),
) -> decode.Decoder(PaginatedResponse(a)) {
  use count <- decode.field("count", decode.int)
  use next <- decode.field("next", decode.optional(decode.string))
  use previous <- decode.field("previous", decode.optional(decode.string))
  use results <- decode.field("results", decode.list(item_decoder))

  decode.success(PaginatedResponse(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}

// ============================================================================
// Pagination Helper Functions
// ============================================================================

/// Check if there is a next page available
///
/// # Arguments
/// * `response` - The paginated response to check
///
/// # Returns
/// `True` if there is a next page, `False` otherwise
///
/// # Example
/// ```gleam
/// let has_more = has_next_page(response)
/// case has_more {
///   True -> fetch_next_page()
///   False -> stop_pagination()
/// }
/// ```
pub fn has_next_page(response: PaginatedResponse(a)) -> Bool {
  option.is_some(response.next)
}

/// Check if there is a previous page available
///
/// # Arguments
/// * `response` - The paginated response to check
///
/// # Returns
/// `True` if there is a previous page, `False` otherwise
pub fn has_previous_page(response: PaginatedResponse(a)) -> Bool {
  option.is_some(response.previous)
}

/// Extract pagination parameters from a next/previous URL
///
/// Parses the URL to extract limit and offset query parameters.
///
/// # Arguments
/// * `response` - The paginated response containing the next URL
///
/// # Returns
/// `Some(#(limit, offset))` if URL exists and parameters can be parsed,
/// `None` if no next URL or parsing fails
///
/// # Example
/// ```gleam
/// case next_page_params(response) {
///   Some(#(limit, offset)) -> fetch_page(limit, offset)
///   None -> // No more pages
/// }
/// ```
pub fn next_page_params(response: PaginatedResponse(a)) -> Option(#(Int, Int)) {
  case response.next {
    None -> None
    Some(url) -> parse_url_params(url)
  }
}

/// Extract pagination parameters from the previous URL
///
/// # Arguments
/// * `response` - The paginated response containing the previous URL
///
/// # Returns
/// `Some(#(limit, offset))` if URL exists and parameters can be parsed,
/// `None` if no previous URL or parsing fails
pub fn previous_page_params(
  response: PaginatedResponse(a),
) -> Option(#(Int, Int)) {
  case response.previous {
    None -> None
    Some(url) -> parse_url_params(url)
  }
}

/// Parse limit and offset from a URL query string
///
/// Internal helper function to extract pagination parameters from URLs.
///
/// # Arguments
/// * `url` - The URL string to parse
///
/// # Returns
/// `Some(#(limit, offset))` if both parameters found, `None` otherwise
fn parse_url_params(url: String) -> Option(#(Int, Int)) {
  case uri.parse(url) {
    Ok(parsed_uri) -> {
      case parsed_uri.query {
        None -> None
        Some(query_string) -> parse_query_string_params(query_string)
      }
    }
    Error(_) -> None
  }
}

/// Parse query string to extract limit and offset
///
/// # Arguments
/// * `query` - Query string (e.g., "limit=10&offset=20")
///
/// # Returns
/// `Some(#(limit, offset))` if both found, `None` otherwise
fn parse_query_string_params(query: String) -> Option(#(Int, Int)) {
  let params =
    query
    |> string.split("&")
    |> list.map(fn(param) {
      case string.split(param, "=") {
        [key, value] -> #(key, value)
        _ -> #("", "")
      }
    })
    |> list.filter(fn(pair) { pair.0 != "" })

  let limit = find_param(params, "limit")
  let offset = find_param(params, "offset")

  case limit, offset {
    Some(l), Some(o) -> Some(#(l, o))
    _, _ -> None
  }
}

/// Find and parse an integer parameter from a list of key-value pairs
///
/// # Arguments
/// * `params` - List of key-value pairs
/// * `key` - The key to search for
///
/// # Returns
/// `Some(value)` if found and can be parsed as int, `None` otherwise
fn find_param(params: List(#(String, String)), key: String) -> Option(Int) {
  params
  |> list.find(fn(pair) { pair.0 == key })
  |> result.map(fn(pair) { pair.1 })
  |> result.then(int.parse)
  |> option.from_result
}

/// Build a query string from a list of optional parameters
///
/// Filters out None values and constructs a properly formatted query string.
///
/// # Arguments
/// * `params` - List of key-value pairs where values are optional
///
/// # Returns
/// Query string without leading "?" (e.g., "limit=10&offset=0")
/// Returns empty string if no parameters provided
///
/// # Example
/// ```gleam
/// let query = build_query_string([
///   #("limit", Some("10")),
///   #("offset", Some("0")),
///   #("filter", None),
/// ])
/// // Returns: "limit=10&offset=0"
/// ```
pub fn build_query_string(params: List(#(String, Option(String)))) -> String {
  params
  |> list.filter_map(fn(pair) {
    case pair {
      #(key, Some(value)) -> Ok(key <> "=" <> value)
      #(_, None) -> Error(Nil)
    }
  })
  |> string.join("&")
}

/// Convert PaginationParams to a query string
///
/// # Arguments
/// * `params` - The pagination parameters
///
/// # Returns
/// Query string with limit and offset (e.g., "limit=10&offset=0")
///
/// # Example
/// ```gleam
/// let params = PaginationParams(limit: Some(10), offset: Some(0))
/// let query = pagination_params_to_query(params)
/// // Returns: "limit=10&offset=0"
/// ```
pub fn pagination_params_to_query(params: PaginationParams) -> String {
  build_query_string([
    #("limit", option.map(params.limit, int.to_string)),
    #("offset", option.map(params.offset, int.to_string)),
  ])
}
