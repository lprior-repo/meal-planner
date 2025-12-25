/// OpenAPI type definitions
///
/// Contains all type definitions for OpenAPI 3.1.0 specification.
/// These types represent the structure of an OpenAPI document.
import gleam/dict.{type Dict}
import gleam/option.{type Option}

// ============================================================================
// Core Types
// ============================================================================

/// OpenAPI specification root object
pub type OpenApiSpec {
  OpenApiSpec(
    openapi: String,
    info: Info,
    servers: List(Server),
    tags: List(Tag),
    paths: Dict(String, PathItem),
    components: Option(Components),
  )
}

/// API information
pub type Info {
  Info(
    title: String,
    description: String,
    version: String,
    contact: Option(Contact),
    license: Option(License),
  )
}

/// Contact information
pub type Contact {
  Contact(name: String, email: Option(String), url: Option(String))
}

/// License information
pub type License {
  License(name: String, url: Option(String))
}

/// Server configuration
pub type Server {
  Server(url: String, description: String)
}

/// API tag for grouping
pub type Tag {
  Tag(name: String, description: String)
}

// ============================================================================
// Path and Operation Types
// ============================================================================

/// Path item for an endpoint
pub type PathItem {
  PathItem(
    get: Option(Operation),
    post: Option(Operation),
    put: Option(Operation),
    patch: Option(Operation),
    delete: Option(Operation),
  )
}

/// HTTP operation
pub type Operation {
  Operation(
    operation_id: String,
    tags: List(String),
    summary: String,
    description: String,
    parameters: List(Parameter),
    request_body: Option(RequestBody),
    responses: Dict(String, Response),
  )
}

/// Parameter definition
pub type Parameter {
  Parameter(
    name: String,
    in_: ParameterLocation,
    description: String,
    required: Bool,
    schema: Schema,
  )
}

/// Parameter location
pub type ParameterLocation {
  PathParam
  QueryParam
  HeaderParam
}

/// Request body
pub type RequestBody {
  RequestBody(description: String, content: Dict(String, MediaType))
}

/// Response definition
pub type Response {
  Response(description: String, content: Option(Dict(String, MediaType)))
}

/// Media type definition
pub type MediaType {
  MediaType(schema: Schema)
}

// ============================================================================
// Schema Types
// ============================================================================

/// JSON Schema
pub type Schema {
  StringSchema
  IntSchema
  FloatSchema
  BoolSchema
  ArraySchema(items: Schema)
  ObjectSchema(properties: Dict(String, Schema))
  RefSchema(ref: String)
}

/// Components section
pub type Components {
  Components(schemas: Dict(String, Schema))
}
