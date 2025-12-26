//// API versioning module for handling version headers and routing
////
//// This module provides:
//// - API version parsing from Accept-Version header
//// - Version-specific request routing
//// - Deprecation warnings for old API versions
//// - Version negotiation logic
////
//// Supported versions:
//// - v1: Current stable API (default)
//// - v2: Next major version (when available)
////
//// Header format:
//// - Accept-Version: v1
//// - Accept-Version: v2
//// - Accept-Version: latest (resolves to newest version)

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import wisp

// ============================================================================
// Types
// ============================================================================

/// API version identifier
pub type ApiVersion {
  V1
  V2
  Latest
}

/// Version compatibility status
pub type VersionStatus {
  /// Version is current and fully supported
  Current
  /// Version is deprecated but still functional
  Deprecated(sunset_date: String, message: String)
  /// Version is no longer supported
  Sunset(message: String)
}

/// Versioned request context
pub type VersionedRequest {
  VersionedRequest(request: wisp.Request, version: ApiVersion)
}

/// Version negotiation result
pub type VersionNegotiation {
  /// Successfully negotiated version
  Accepted(version: ApiVersion, status: VersionStatus)
  /// No valid version could be negotiated
  Rejected(reason: String)
}

// ============================================================================
// Constants
// ============================================================================

/// Default API version when none specified
const default_version = V1

/// Current latest API version
const latest_version = V1

/// Accept-Version header name
const version_header = "accept-version"

/// Warning header name for deprecation notices
const warning_header = "warning"

// ============================================================================
// Version Parsing
// ============================================================================

/// Parse API version from string
///
/// Examples:
/// ```gleam
/// parse_version("v1") // Ok(V1)
/// parse_version("v2") // Ok(V2)
/// parse_version("latest") // Ok(Latest)
/// parse_version("invalid") // Error("Unknown version: invalid")
/// ```
pub fn parse_version(version_str: String) -> Result(ApiVersion, String) {
  case string.lowercase(string.trim(version_str)) {
    "v1" | "1" -> Ok(V1)
    "v2" | "2" -> Ok(V2)
    "latest" -> Ok(Latest)
    other -> Error("Unknown version: " <> other)
  }
}

/// Convert API version to string
///
/// Examples:
/// ```gleam
/// version_to_string(V1) // "v1"
/// version_to_string(V2) // "v2"
/// version_to_string(Latest) // "latest"
/// ```
pub fn version_to_string(version: ApiVersion) -> String {
  case version {
    V1 -> "v1"
    V2 -> "v2"
    Latest -> "latest"
  }
}

/// Resolve Latest to concrete version
pub fn resolve_latest(version: ApiVersion) -> ApiVersion {
  case version {
    Latest -> latest_version
    other -> other
  }
}

// ============================================================================
// Version Extraction
// ============================================================================

/// Extract version from request headers
///
/// Checks Accept-Version header. Returns default version if not found.
pub fn extract_version(req: wisp.Request) -> ApiVersion {
  case
    req.headers
    |> list.find(fn(header) {
      string.lowercase(header.0) == string.lowercase(version_header)
    })
  {
    Ok(header) -> {
      header.1
      |> parse_version
      |> result.unwrap(default_version)
      |> resolve_latest
    }
    Error(_) -> {
      default_version
      |> resolve_latest
    }
  }
}

/// Create versioned request wrapper
pub fn to_versioned_request(req: wisp.Request) -> VersionedRequest {
  let version = extract_version(req)
  VersionedRequest(request: req, version: version)
}

// ============================================================================
// Version Status
// ============================================================================

/// Get version compatibility status
pub fn get_version_status(version: ApiVersion) -> VersionStatus {
  case version {
    V1 -> Current
    V2 ->
      Deprecated(
        sunset_date: "2026-12-31",
        message: "API v2 will be sunset on 2026-12-31. Please migrate to v3.",
      )
    Latest -> Current
  }
}

/// Check if version is supported
pub fn is_supported(version: ApiVersion) -> Bool {
  case get_version_status(version) {
    Current | Deprecated(..) -> True
    Sunset(..) -> False
  }
}

// ============================================================================
// Version Negotiation
// ============================================================================

/// Negotiate API version with client
///
/// Returns negotiation result with version and status
pub fn negotiate_version(req: wisp.Request) -> VersionNegotiation {
  let version = extract_version(req)
  let status = get_version_status(version)

  case status {
    Current -> Accepted(version: version, status: status)
    Deprecated(..) -> Accepted(version: version, status: status)
    Sunset(message) -> Rejected(reason: message)
  }
}

// ============================================================================
// Response Helpers
// ============================================================================

/// Add deprecation warning header to response
pub fn add_deprecation_warning(
  response: wisp.Response,
  version: ApiVersion,
) -> wisp.Response {
  case get_version_status(version) {
    Deprecated(sunset_date, message) -> {
      let warning_text =
        "299 - \"API "
        <> version_to_string(version)
        <> " is deprecated. "
        <> message
        <> " Sunset date: "
        <> sunset_date
        <> "\""
      wisp.set_header(response, warning_header, warning_text)
    }
    _ -> response
  }
}

/// Add API version header to response
pub fn add_version_header(
  response: wisp.Response,
  version: ApiVersion,
) -> wisp.Response {
  wisp.set_header(response, "api-version", version_to_string(version))
}

/// Create version not supported error response
pub fn version_not_supported(version: ApiVersion) -> wisp.Response {
  let message =
    "API version " <> version_to_string(version) <> " is no longer supported"

  wisp.response(410)
  |> wisp.set_header("content-type", "application/json")
  |> wisp.string_body(
    "{\"error\":\"Version Not Supported\",\"message\":\"" <> message <> "\"}",
  )
}

// ============================================================================
// Routing Helpers
// ============================================================================

/// Route request to version-specific handler
///
/// Handles version negotiation and deprecation warnings automatically.
/// Returns None if version is not supported.
///
/// Example:
/// ```gleam
/// pub fn handle_request(req: wisp.Request) -> Option(wisp.Response) {
///   use response <- route_versioned(req, fn(version, req) {
///     case version {
///       V1 -> Some(handle_v1(req))
///       V2 -> Some(handle_v2(req))
///       _ -> None
///     }
///   })
///   response
/// }
/// ```
pub fn route_versioned(
  req: wisp.Request,
  handler: fn(ApiVersion, wisp.Request) -> Option(wisp.Response),
) -> Option(wisp.Response) {
  case negotiate_version(req) {
    Rejected(_) -> {
      let version = extract_version(req)
      Some(version_not_supported(version))
    }
    Accepted(version: version, status: status) -> {
      case handler(version, req) {
        None -> None
        Some(response) -> {
          let response = add_version_header(response, version)
          let response = case status {
            Deprecated(..) -> add_deprecation_warning(response, version)
            _ -> response
          }
          Some(response)
        }
      }
    }
  }
}

/// Extract version number as integer (for comparison)
///
/// Latest resolves to the latest version number.
pub fn version_number(version: ApiVersion) -> Int {
  case version {
    V1 -> 1
    V2 -> 2
    Latest -> version_number(latest_version)
  }
}

/// Compare two versions
///
/// Returns:
/// - Negative if version1 < version2
/// - Zero if version1 == version2
/// - Positive if version1 > version2
pub fn compare_versions(version1: ApiVersion, version2: ApiVersion) -> Int {
  let v1 = version_number(version1)
  let v2 = version_number(version2)
  int.compare(v1, v2) |> order_to_int
}

/// Check if version meets minimum requirement
pub fn meets_minimum(version: ApiVersion, minimum: ApiVersion) -> Bool {
  compare_versions(version, minimum) >= 0
}

// ============================================================================
// Internal Helpers
// ============================================================================

/// Convert order to integer
fn order_to_int(ord) -> Int {
  case ord {
    order.Lt -> -1
    order.Eq -> 0
    order.Gt -> 1
  }
}
