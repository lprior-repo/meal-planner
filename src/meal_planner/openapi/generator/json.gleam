/// OpenAPI JSON encoding
///
/// Converts OpenAPI types to JSON format.
/// Used for generating machine-readable OpenAPI specifications.
import gleam/dict.{type Dict}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/openapi/generator/types.{
  type Components, type Contact, type Info, type License, type MediaType,
  type Operation, type Parameter, type ParameterLocation, type PathItem,
  type RequestBody, type Response, type Schema, type Server, type Tag,
  ArraySchema, BoolSchema, FloatSchema, HeaderParam, IntSchema, ObjectSchema,
  PathParam, QueryParam, RefSchema, StringSchema,
}

/// Convert OpenAPI spec to JSON
pub fn to_json(spec: types.OpenApiSpec) -> json.Json {
  json.object([
    #("openapi", json.string(spec.openapi)),
    #("info", encode_info(spec.info)),
    #("servers", json.array(spec.servers, encode_server)),
    #("tags", json.array(spec.tags, encode_tag)),
    #("paths", encode_paths(spec.paths)),
    #("components", case spec.components {
      Some(c) -> encode_components(c)
      None -> json.null()
    }),
  ])
}

/// Encode info object
pub fn encode_info(info: Info) -> json.Json {
  json.object([
    #("title", json.string(info.title)),
    #("description", json.string(info.description)),
    #("version", json.string(info.version)),
    #("contact", case info.contact {
      Some(c) -> encode_contact(c)
      None -> json.null()
    }),
    #("license", case info.license {
      Some(l) -> encode_license(l)
      None -> json.null()
    }),
  ])
}

/// Encode contact object
pub fn encode_contact(contact: Contact) -> json.Json {
  json.object([
    #("name", json.string(contact.name)),
    #("email", case contact.email {
      Some(e) -> json.string(e)
      None -> json.null()
    }),
    #("url", case contact.url {
      Some(u) -> json.string(u)
      None -> json.null()
    }),
  ])
}

/// Encode license object
pub fn encode_license(license: License) -> json.Json {
  json.object([
    #("name", json.string(license.name)),
    #("url", case license.url {
      Some(u) -> json.string(u)
      None -> json.null()
    }),
  ])
}

/// Encode server object
pub fn encode_server(server: Server) -> json.Json {
  json.object([
    #("url", json.string(server.url)),
    #("description", json.string(server.description)),
  ])
}

/// Encode tag object
pub fn encode_tag(tag: Tag) -> json.Json {
  json.object([
    #("name", json.string(tag.name)),
    #("description", json.string(tag.description)),
  ])
}

/// Encode paths dictionary
pub fn encode_paths(paths: Dict(String, PathItem)) -> json.Json {
  paths
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(path, item) = entry
    #(path, encode_path_item(item))
  })
  |> json.object
}

/// Encode path item
pub fn encode_path_item(item: PathItem) -> json.Json {
  let fields =
    []
    |> add_optional_field("get", item.get, encode_operation)
    |> add_optional_field("post", item.post, encode_operation)
    |> add_optional_field("put", item.put, encode_operation)
    |> add_optional_field("patch", item.patch, encode_operation)
    |> add_optional_field("delete", item.delete, encode_operation)

  json.object(fields)
}

/// Add optional field to list
pub fn add_optional_field(
  fields: List(#(String, json.Json)),
  name: String,
  value: Option(a),
  encoder: fn(a) -> json.Json,
) -> List(#(String, json.Json)) {
  case value {
    Some(v) -> [#(name, encoder(v)), ..fields]
    None -> fields
  }
}

/// Encode operation
pub fn encode_operation(op: Operation) -> json.Json {
  json.object([
    #("operationId", json.string(op.operation_id)),
    #("tags", json.array(op.tags, json.string)),
    #("summary", json.string(op.summary)),
    #("description", json.string(op.description)),
    #("parameters", json.array(op.parameters, encode_parameter)),
    #("requestBody", case op.request_body {
      Some(rb) -> encode_request_body(rb)
      None -> json.null()
    }),
    #("responses", encode_responses(op.responses)),
  ])
}

/// Encode parameter
pub fn encode_parameter(param: Parameter) -> json.Json {
  json.object([
    #("name", json.string(param.name)),
    #("in", json.string(encode_param_location(param.in_))),
    #("description", json.string(param.description)),
    #("required", json.bool(param.required)),
    #("schema", encode_schema(param.schema)),
  ])
}

/// Encode parameter location
pub fn encode_param_location(loc: ParameterLocation) -> String {
  case loc {
    PathParam -> "path"
    QueryParam -> "query"
    HeaderParam -> "header"
  }
}

/// Encode request body
pub fn encode_request_body(rb: RequestBody) -> json.Json {
  json.object([
    #("description", json.string(rb.description)),
    #("content", encode_content(rb.content)),
  ])
}

/// Encode responses
pub fn encode_responses(responses: Dict(String, Response)) -> json.Json {
  responses
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(code, response) = entry
    #(code, encode_response(response))
  })
  |> json.object
}

/// Encode response
pub fn encode_response(response: Response) -> json.Json {
  json.object([
    #("description", json.string(response.description)),
    #("content", case response.content {
      Some(c) -> encode_content(c)
      None -> json.null()
    }),
  ])
}

/// Encode content dictionary
pub fn encode_content(content: Dict(String, MediaType)) -> json.Json {
  content
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(media_type, mt) = entry
    #(media_type, encode_media_type(mt))
  })
  |> json.object
}

/// Encode media type
pub fn encode_media_type(mt: MediaType) -> json.Json {
  json.object([#("schema", encode_schema(mt.schema))])
}

/// Encode schema
pub fn encode_schema(schema: Schema) -> json.Json {
  case schema {
    StringSchema -> json.object([#("type", json.string("string"))])
    IntSchema -> json.object([#("type", json.string("integer"))])
    FloatSchema -> json.object([#("type", json.string("number"))])
    BoolSchema -> json.object([#("type", json.string("boolean"))])
    ArraySchema(items) ->
      json.object([
        #("type", json.string("array")),
        #("items", encode_schema(items)),
      ])
    ObjectSchema(properties) ->
      json.object([
        #("type", json.string("object")),
        #("properties", encode_schema_properties(properties)),
      ])
    RefSchema(ref) -> json.object([#("$ref", json.string(ref))])
  }
}

/// Encode schema properties
pub fn encode_schema_properties(properties: Dict(String, Schema)) -> json.Json {
  properties
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(name, schema) = entry
    #(name, encode_schema(schema))
  })
  |> json.object
}

/// Encode components
pub fn encode_components(components: Components) -> json.Json {
  json.object([#("schemas", encode_schema_properties(components.schemas))])
}
