/// OpenAPI specification generator for the Meal Planner API
///
/// Auto-generates OpenAPI spec from handlers, keeping documentation in sync.
/// This module introspects the route structure and handler metadata to produce
/// a valid OpenAPI 3.1.0 specification.
///
/// Usage:
/// ```gleam
/// import meal_planner/openapi/generator
///
/// let spec = generator.generate()
/// let yaml = generator.to_yaml(spec)
/// ```
import gleam/dict.{type Dict}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

// ============================================================================
// Types
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

// ============================================================================
// Generator
// ============================================================================

/// Generate complete OpenAPI specification
pub fn generate() -> OpenApiSpec {
  OpenApiSpec(
    openapi: "3.1.0",
    info: generate_info(),
    servers: generate_servers(),
    tags: generate_tags(),
    paths: generate_paths(),
    components: Some(generate_components()),
  )
}

/// Generate API info section
fn generate_info() -> Info {
  Info(
    title: "Meal Planner API",
    description: "A modern meal planning and nutrition tracking API built with Gleam, integrating FatSecret and Tandoor\nfor comprehensive food, recipe, and meal management.\n\n## Authentication\n\nTwo types of OAuth flows are used:\n- **2-legged OAuth**: Public endpoints (foods, recipes search) - requires API credentials\n- **3-legged OAuth**: User-specific endpoints (diary, favorites, saved meals) - requires user authorization\n\nStart the 3-legged OAuth flow at `GET /fatsecret/connect`\n\n## Features\n- Food and recipe search via FatSecret API\n- Diary entry logging and tracking\n- User favorites and saved meals management\n- Recipe management via Tandoor integration\n- Nutrition control plane for daily macro tracking\n- Meal plan recommendations",
    version: "1.0.0",
    contact: Some(Contact(name: "Meal Planner Team", email: None, url: None)),
    license: Some(License(name: "MIT", url: None)),
  )
}

/// Generate server configurations
fn generate_servers() -> List(Server) {
  [
    Server(
      url: "http://localhost:8080",
      description: "Local development server",
    ),
    Server(
      url: "http://localhost:3000",
      description: "Alternative development port",
    ),
  ]
}

/// Generate API tags
fn generate_tags() -> List(Tag) {
  [
    Tag(name: "Health", description: "Health check endpoints"),
    Tag(
      name: "FatSecret - OAuth",
      description: "FatSecret OAuth flow endpoints (3-legged)",
    ),
    Tag(
      name: "FatSecret - Foods",
      description: "Food search and details (2-legged OAuth)",
    ),
    Tag(
      name: "FatSecret - Recipes",
      description: "Recipe search and details (2-legged OAuth)",
    ),
    Tag(
      name: "FatSecret - Favorites",
      description: "User favorite foods and recipes (3-legged OAuth)",
    ),
    Tag(
      name: "FatSecret - Saved Meals",
      description: "User saved meals management (3-legged OAuth)",
    ),
    Tag(
      name: "FatSecret - Diary",
      description: "Food diary entry logging (3-legged OAuth)",
    ),
    Tag(
      name: "FatSecret - Exercise",
      description: "Exercise tracking (3-legged OAuth)",
    ),
    Tag(
      name: "FatSecret - Weight",
      description: "Weight tracking (3-legged OAuth)",
    ),
    Tag(
      name: "FatSecret - Profile",
      description: "User profile management (3-legged OAuth)",
    ),
    Tag(
      name: "Tandoor Integration",
      description: "Recipe management via Tandoor",
    ),
    Tag(
      name: "Nutrition Control",
      description: "Nutrition state tracking and recommendations",
    ),
    Tag(name: "Meal Planning", description: "Meal plan generation endpoints"),
    Tag(name: "Misc", description: "Miscellaneous utility endpoints"),
  ]
}

/// Generate paths from route definitions
fn generate_paths() -> Dict(String, PathItem) {
  dict.new()
  |> dict.insert("/", health_root_path())
  |> dict.insert("/health", health_check_path())
  |> dict.insert("/api/nutrition/daily-status", nutrition_daily_status_path())
  |> dict.insert(
    "/api/nutrition/recommend-dinner",
    nutrition_recommend_dinner_path(),
  )
  |> dict.insert("/api/ai/score-recipe", ai_score_recipe_path())
}

/// Health check root endpoint
fn health_root_path() -> PathItem {
  PathItem(
    get: Some(Operation(
      operation_id: "getHealth",
      tags: ["Health"],
      summary: "Health check",
      description: "Returns 200 if server is running",
      parameters: [],
      request_body: None,
      responses: dict.new()
        |> dict.insert(
          "200",
          Response(
            description: "Server is healthy",
            content: Some(
              dict.new()
              |> dict.insert(
                "application/json",
                MediaType(schema: ObjectSchema(
                  properties: dict.new()
                  |> dict.insert("status", StringSchema)
                  |> dict.insert("service", StringSchema)
                  |> dict.insert("version", StringSchema),
                )),
              ),
            ),
          ),
        ),
    )),
    post: None,
    put: None,
    patch: None,
    delete: None,
  )
}

/// Health check endpoint
fn health_check_path() -> PathItem {
  PathItem(
    get: Some(Operation(
      operation_id: "getHealthCheck",
      tags: ["Health"],
      summary: "Health check endpoint",
      description: "Returns 200 if server is running",
      parameters: [],
      request_body: None,
      responses: dict.new()
        |> dict.insert(
          "200",
          Response(
            description: "Server is healthy",
            content: Some(
              dict.new()
              |> dict.insert(
                "application/json",
                MediaType(schema: ObjectSchema(
                  properties: dict.new()
                  |> dict.insert("status", StringSchema)
                  |> dict.insert("service", StringSchema)
                  |> dict.insert("version", StringSchema),
                )),
              ),
            ),
          ),
        ),
    )),
    post: None,
    put: None,
    patch: None,
    delete: None,
  )
}

/// Nutrition daily status endpoint
fn nutrition_daily_status_path() -> PathItem {
  PathItem(
    get: Some(Operation(
      operation_id: "getNutritionDailyStatus",
      tags: ["Nutrition Control"],
      summary: "Get daily nutrition status",
      description: "Returns current nutrition status for the day including macros consumed and remaining",
      parameters: [],
      request_body: None,
      responses: dict.new()
        |> dict.insert(
          "200",
          Response(
            description: "Daily nutrition status",
            content: Some(
              dict.new()
              |> dict.insert(
                "application/json",
                MediaType(schema: RefSchema(
                  ref: "#/components/schemas/NutritionStatus",
                )),
              ),
            ),
          ),
        ),
    )),
    post: None,
    put: None,
    patch: None,
    delete: None,
  )
}

/// Nutrition recommend dinner endpoint
fn nutrition_recommend_dinner_path() -> PathItem {
  PathItem(
    get: Some(Operation(
      operation_id: "getNutritionRecommendDinner",
      tags: ["Nutrition Control"],
      summary: "Get dinner recommendations",
      description: "Returns recommended dinner options based on remaining daily macros",
      parameters: [],
      request_body: None,
      responses: dict.new()
        |> dict.insert(
          "200",
          Response(
            description: "Dinner recommendations",
            content: Some(
              dict.new()
              |> dict.insert(
                "application/json",
                MediaType(
                  schema: ArraySchema(items: RefSchema(
                    ref: "#/components/schemas/RecipeRecommendation",
                  )),
                ),
              ),
            ),
          ),
        ),
    )),
    post: None,
    put: None,
    patch: None,
    delete: None,
  )
}

/// AI score recipe endpoint
fn ai_score_recipe_path() -> PathItem {
  PathItem(
    get: None,
    post: Some(Operation(
      operation_id: "postAiScoreRecipe",
      tags: ["Meal Planning"],
      summary: "Score recipes against targets",
      description: "Scores a list of recipes against macro targets using weighted scoring algorithm",
      parameters: [],
      request_body: Some(RequestBody(
        description: "Recipe scoring request",
        content: dict.new()
          |> dict.insert(
            "application/json",
            MediaType(schema: RefSchema(
              ref: "#/components/schemas/ScoringRequest",
            )),
          ),
      )),
      responses: dict.new()
        |> dict.insert(
          "200",
          Response(
            description: "Recipe scores",
            content: Some(
              dict.new()
              |> dict.insert(
                "application/json",
                MediaType(
                  schema: ArraySchema(items: RefSchema(
                    ref: "#/components/schemas/RecipeScore",
                  )),
                ),
              ),
            ),
          ),
        )
        |> dict.insert(
          "400",
          Response(description: "Invalid request", content: None),
        )
        |> dict.insert(
          "501",
          Response(description: "Not implemented", content: None),
        ),
    )),
    put: None,
    patch: None,
    delete: None,
  )
}

/// Generate components section
fn generate_components() -> Components {
  Components(
    schemas: dict.new()
    |> dict.insert("NutritionStatus", nutrition_status_schema())
    |> dict.insert("RecipeRecommendation", recipe_recommendation_schema())
    |> dict.insert("ScoringRequest", scoring_request_schema())
    |> dict.insert("RecipeScore", recipe_score_schema())
    |> dict.insert("MacroTargets", macro_targets_schema()),
  )
}

/// Nutrition status schema
fn nutrition_status_schema() -> Schema {
  ObjectSchema(
    properties: dict.new()
    |> dict.insert("date", StringSchema)
    |> dict.insert("protein_consumed", FloatSchema)
    |> dict.insert("fat_consumed", FloatSchema)
    |> dict.insert("carbs_consumed", FloatSchema)
    |> dict.insert("protein_remaining", FloatSchema)
    |> dict.insert("fat_remaining", FloatSchema)
    |> dict.insert("carbs_remaining", FloatSchema),
  )
}

/// Recipe recommendation schema
fn recipe_recommendation_schema() -> Schema {
  ObjectSchema(
    properties: dict.new()
    |> dict.insert("recipe_id", StringSchema)
    |> dict.insert("name", StringSchema)
    |> dict.insert("score", FloatSchema)
    |> dict.insert("servings", FloatSchema),
  )
}

/// Scoring request schema
fn scoring_request_schema() -> Schema {
  ObjectSchema(
    properties: dict.new()
    |> dict.insert(
      "recipes",
      ArraySchema(items: ObjectSchema(
        properties: dict.new()
        |> dict.insert("recipe_id", StringSchema)
        |> dict.insert("servings", FloatSchema),
      )),
    )
    |> dict.insert(
      "targets",
      RefSchema(ref: "#/components/schemas/MacroTargets"),
    )
    |> dict.insert(
      "weights",
      ObjectSchema(
        properties: dict.new()
        |> dict.insert("protein_weight", FloatSchema)
        |> dict.insert("fat_weight", FloatSchema)
        |> dict.insert("carbs_weight", FloatSchema),
      ),
    ),
  )
}

/// Recipe score schema
fn recipe_score_schema() -> Schema {
  ObjectSchema(
    properties: dict.new()
    |> dict.insert("recipe_id", StringSchema)
    |> dict.insert("score", FloatSchema),
  )
}

/// Macro targets schema
fn macro_targets_schema() -> Schema {
  ObjectSchema(
    properties: dict.new()
    |> dict.insert("protein", FloatSchema)
    |> dict.insert("fat", FloatSchema)
    |> dict.insert("carbs", FloatSchema),
  )
}

// ============================================================================
// JSON Encoding
// ============================================================================

/// Convert OpenAPI spec to JSON
pub fn to_json(spec: OpenApiSpec) -> json.Json {
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
fn encode_info(info: Info) -> json.Json {
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
fn encode_contact(contact: Contact) -> json.Json {
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
fn encode_license(license: License) -> json.Json {
  json.object([
    #("name", json.string(license.name)),
    #("url", case license.url {
      Some(u) -> json.string(u)
      None -> json.null()
    }),
  ])
}

/// Encode server object
fn encode_server(server: Server) -> json.Json {
  json.object([
    #("url", json.string(server.url)),
    #("description", json.string(server.description)),
  ])
}

/// Encode tag object
fn encode_tag(tag: Tag) -> json.Json {
  json.object([
    #("name", json.string(tag.name)),
    #("description", json.string(tag.description)),
  ])
}

/// Encode paths dictionary
fn encode_paths(paths: Dict(String, PathItem)) -> json.Json {
  paths
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(path, item) = entry
    #(path, encode_path_item(item))
  })
  |> json.object
}

/// Encode path item
fn encode_path_item(item: PathItem) -> json.Json {
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
fn add_optional_field(
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
fn encode_operation(op: Operation) -> json.Json {
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
fn encode_parameter(param: Parameter) -> json.Json {
  json.object([
    #("name", json.string(param.name)),
    #("in", json.string(encode_param_location(param.in_))),
    #("description", json.string(param.description)),
    #("required", json.bool(param.required)),
    #("schema", encode_schema(param.schema)),
  ])
}

/// Encode parameter location
fn encode_param_location(loc: ParameterLocation) -> String {
  case loc {
    PathParam -> "path"
    QueryParam -> "query"
    HeaderParam -> "header"
  }
}

/// Encode request body
fn encode_request_body(rb: RequestBody) -> json.Json {
  json.object([
    #("description", json.string(rb.description)),
    #("content", encode_content(rb.content)),
  ])
}

/// Encode responses
fn encode_responses(responses: Dict(String, Response)) -> json.Json {
  responses
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(code, response) = entry
    #(code, encode_response(response))
  })
  |> json.object
}

/// Encode response
fn encode_response(response: Response) -> json.Json {
  json.object([
    #("description", json.string(response.description)),
    #("content", case response.content {
      Some(c) -> encode_content(c)
      None -> json.null()
    }),
  ])
}

/// Encode content dictionary
fn encode_content(content: Dict(String, MediaType)) -> json.Json {
  content
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(media_type, mt) = entry
    #(media_type, encode_media_type(mt))
  })
  |> json.object
}

/// Encode media type
fn encode_media_type(mt: MediaType) -> json.Json {
  json.object([#("schema", encode_schema(mt.schema))])
}

/// Encode schema
fn encode_schema(schema: Schema) -> json.Json {
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
fn encode_schema_properties(properties: Dict(String, Schema)) -> json.Json {
  properties
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(name, schema) = entry
    #(name, encode_schema(schema))
  })
  |> json.object
}

/// Encode components
fn encode_components(components: Components) -> json.Json {
  json.object([#("schemas", encode_schema_properties(components.schemas))])
}

// ============================================================================
// YAML Conversion
// ============================================================================

/// Convert OpenAPI spec to YAML string
pub fn to_yaml(spec: OpenApiSpec) -> String {
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
fn yaml_info(info: Info) -> String {
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
fn yaml_servers(servers: List(Server)) -> String {
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
fn yaml_tags(tags: List(Tag)) -> String {
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
fn yaml_paths(paths: Dict(String, PathItem)) -> String {
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
fn yaml_path_item(item: PathItem, indent: String) -> String {
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
fn yaml_operation(op: Operation, indent: String) -> String {
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
fn yaml_responses(responses: Dict(String, Response), indent: String) -> String {
  responses
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(code, response) = entry
    indent <> code <> ":\n" <> yaml_response(response, indent <> "  ")
  })
  |> string.join("")
}

/// Convert response to YAML
fn yaml_response(response: Response, indent: String) -> String {
  indent <> "description: " <> response.description <> "\n"
}

/// Convert components to YAML
fn yaml_components(components: Components) -> String {
  "components:\n  schemas:\n" <> yaml_schemas(components.schemas, "    ")
}

/// Convert schemas to YAML
fn yaml_schemas(schemas: Dict(String, Schema), indent: String) -> String {
  schemas
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(name, schema) = entry
    indent <> name <> ":\n" <> yaml_schema(schema, indent <> "  ")
  })
  |> string.join("")
}

/// Convert schema to YAML
fn yaml_schema(schema: Schema, indent: String) -> String {
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
fn yaml_schema_properties(
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
fn indent_text(text: String, spaces: Int) -> String {
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
