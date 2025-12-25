/// OpenAPI YAML conversion
///
/// Converts OpenAPI types to YAML string format.
/// Used for generating human-readable OpenAPI specifications.
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/openapi/generator/types.{
  type Components, type Info, type License, type PathItem, type Response,
  type Schema, type Server, type Tag, ArraySchema, BoolSchema, FloatSchema,
  IntSchema, ObjectSchema, RefSchema, StringSchema,
}

/// Convert OpenAPI spec to YAML string
pub fn to_yaml(spec: types.OpenApiSpec) -> String {
  // Start with basic info
  let yaml =
    "openapi: "
    <> spec.openapi
    <> "\n"
    <> yaml_info(spec.info)
    <> yaml_servers(spec.servers)
    <> yaml_tags(spec.tags)
    <> yaml_paths(spec.paths)

  // Add components if present
  case spec.components {
    Some(c) -> yaml <> yaml_components(c)
    None -> yaml
  }
}

/// Convert info to YAML
pub fn yaml_info(info: Info) -> String {
  let contact_yaml = case info.contact {
    Some(c) -> "  contact:\n    name: " <> c.name <> "\n"
    None -> ""
  }

  let license_yaml = case info.license {
    Some(l) -> "  license:\n    name: " <> l.name <> "\n"
    None -> ""
  }

  "info:\n"
  <> "  title: "
  <> info.title
  <> "\n"
  <> "  description: |\n"
  <> indent_text(info.description, 4)
  <> "\n"
  <> "  version: "
  <> info.version
  <> "\n"
  <> contact_yaml
  <> license_yaml
}

/// Convert servers to YAML
pub fn yaml_servers(servers: List(Server)) -> String {
  "servers:\n"
  <> {
    servers
    |> list.map(fn(s) {
      "  - url: " <> s.url <> "\n    description: " <> s.description <> "\n"
    })
    |> string.join("")
  }
}

/// Convert tags to YAML
pub fn yaml_tags(tags: List(Tag)) -> String {
  "tags:\n"
  <> {
    tags
    |> list.map(fn(t) {
      "  - name: " <> t.name <> "\n    description: " <> t.description <> "\n"
    })
    |> string.join("")
  }
}

/// Convert paths to YAML
pub fn yaml_paths(paths: Dict(String, PathItem)) -> String {
  "paths:\n"
  <> {
    paths
    |> dict.to_list
    |> list.map(fn(entry) {
      let #(path, item) = entry
      "  " <> path <> ":\n" <> yaml_path_item(item, "    ")
    })
    |> string.join("")
  }
}

/// Convert path item to YAML
pub fn yaml_path_item(item: PathItem, indent: String) -> String {
  let get_yaml = case item.get {
    Some(op) -> indent <> "get:\n" <> yaml_operation(op, indent <> "  ")
    None -> ""
  }

  let post_yaml = case item.post {
    Some(op) -> indent <> "post:\n" <> yaml_operation(op, indent <> "  ")
    None -> ""
  }

  let put_yaml = case item.put {
    Some(op) -> indent <> "put:\n" <> yaml_operation(op, indent <> "  ")
    None -> ""
  }

  let patch_yaml = case item.patch {
    Some(op) -> indent <> "patch:\n" <> yaml_operation(op, indent <> "  ")
    None -> ""
  }

  let delete_yaml = case item.delete {
    Some(op) -> indent <> "delete:\n" <> yaml_operation(op, indent <> "  ")
    None -> ""
  }

  get_yaml <> post_yaml <> put_yaml <> patch_yaml <> delete_yaml
}

/// Convert operation to YAML
pub fn yaml_operation(op: types.Operation, indent: String) -> String {
  indent
  <> "operationId: "
  <> op.operation_id
  <> "\n"
  <> indent
  <> "tags:\n"
  <> {
    op.tags
    |> list.map(fn(t) { indent <> "  - " <> t <> "\n" })
    |> string.join("")
  }
  <> indent
  <> "summary: "
  <> op.summary
  <> "\n"
  <> indent
  <> "description: "
  <> op.description
  <> "\n"
  <> {
    case op.request_body {
      Some(_) -> indent <> "requestBody:\n" <> indent <> "  # TODO\n"
      None -> ""
    }
  }
  <> indent
  <> "responses:\n"
  <> yaml_responses(op.responses, indent <> "  ")
}

/// Convert responses to YAML
pub fn yaml_responses(
  responses: Dict(String, Response),
  indent: String,
) -> String {
  responses
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(code, response) = entry
    indent <> code <> ":\n" <> yaml_response(response, indent <> "  ")
  })
  |> string.join("")
}

/// Convert response to YAML
pub fn yaml_response(response: Response, indent: String) -> String {
  indent <> "description: " <> response.description <> "\n"
}

/// Convert components to YAML
pub fn yaml_components(components: Components) -> String {
  "components:\n  schemas:\n" <> yaml_schemas(components.schemas, "    ")
}

/// Convert schemas to YAML
pub fn yaml_schemas(schemas: Dict(String, Schema), indent: String) -> String {
  schemas
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(name, schema) = entry
    indent <> name <> ":\n" <> yaml_schema(schema, indent <> "  ")
  })
  |> string.join("")
}

/// Convert schema to YAML
pub fn yaml_schema(schema: Schema, indent: String) -> String {
  case schema {
    StringSchema -> indent <> "type: string\n"
    IntSchema -> indent <> "type: integer\n"
    FloatSchema -> indent <> "type: number\n"
    BoolSchema -> indent <> "type: boolean\n"
    ArraySchema(_) -> indent <> "type: array\n" <> indent <> "items: {}\n"
    ObjectSchema(properties) ->
      indent
      <> "type: object\n"
      <> indent
      <> "properties:\n"
      <> yaml_schema_properties(properties, indent <> "  ")
    RefSchema(ref) -> indent <> "$ref: " <> ref <> "\n"
  }
}

/// Convert schema properties to YAML
pub fn yaml_schema_properties(
  properties: Dict(String, Schema),
  indent: String,
) -> String {
  properties
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(name, schema) = entry
    indent <> name <> ":\n" <> yaml_schema(schema, indent <> "  ")
  })
  |> string.join("")
}

/// Indent text by adding spaces to each line
pub fn indent_text(text: String, spaces: Int) -> String {
  let prefix = string.repeat(" ", spaces)
  text
  |> string.split("\n")
  |> list.map(fn(line) {
    case line {
      "" -> ""
      _ -> prefix <> line
    }
  })
  |> string.join("\n")
}
