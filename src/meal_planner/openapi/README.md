# OpenAPI Generator

Auto-generates OpenAPI 3.1.0 specification from handler definitions, keeping documentation in sync with the codebase.

## Features

- **Type-Safe Generation**: All OpenAPI components are modeled as Gleam types
- **JSON Output**: Export specs as JSON for API clients and tools
- **YAML Output**: Export specs as human-readable YAML
- **Extensible**: Easy to add new endpoints and schemas
- **No Manual Sync**: Documentation stays in sync with code

## Usage

### Basic Generation

```gleam
import meal_planner/openapi/generator

pub fn main() {
  let spec = generator.generate()
  let yaml = generator.to_yaml(spec)
  // Use the YAML output
}
```

### CLI Tool

Generate and output the specification:

```sh
# Output as YAML (default)
gleam run -m meal_planner/openapi/cli

# Output as JSON
gleam run -m meal_planner/openapi/cli json

# Output as YAML explicitly
gleam run -m meal_planner/openapi/cli yaml
```

### Example

See `example.gleam` for a complete demonstration:

```sh
gleam run -m meal_planner/openapi/example
```

## Architecture

### Core Types

- **OpenApiSpec**: Root specification object
- **Info**: API metadata (title, version, description)
- **Server**: Server configurations
- **Tag**: Endpoint groupings
- **PathItem**: Endpoint definitions with operations
- **Operation**: HTTP method handlers
- **Parameter**: Request parameters
- **RequestBody**: Request body schemas
- **Response**: Response definitions
- **Schema**: JSON Schema types
- **Components**: Reusable schemas

### Generator Flow

```
Route Definitions
    ↓
generate_paths()
    ↓
PathItem with Operations
    ↓
to_json() / to_yaml()
    ↓
OpenAPI Spec Output
```

## Adding New Endpoints

1. Define the path in `generate_paths()`:
   ```gleam
   fn generate_paths() -> Dict(String, PathItem) {
     dict.new()
     |> dict.insert("/api/new-endpoint", new_endpoint_path())
   }
   ```

2. Create the PathItem function:
   ```gleam
   fn new_endpoint_path() -> PathItem {
     PathItem(
       get: Some(Operation(
         operation_id: "getNewEndpoint",
         tags: ["MyTag"],
         summary: "Get new endpoint",
         description: "Detailed description",
         parameters: [],
         request_body: None,
         responses: dict.new()
           |> dict.insert("200", Response(
             description: "Success",
             content: Some(dict.new()
               |> dict.insert("application/json", MediaType(
                 schema: RefSchema(ref: "#/components/schemas/MySchema")
               ))),
           )),
       )),
       post: None,
       put: None,
       patch: None,
       delete: None,
     )
   }
   ```

3. Add schema to components:
   ```gleam
   fn generate_components() -> Components {
     Components(
       schemas: dict.new()
         |> dict.insert("MySchema", my_schema())
     )
   }

   fn my_schema() -> Schema {
     ObjectSchema(
       properties: dict.new()
         |> dict.insert("id", StringSchema)
         |> dict.insert("name", StringSchema)
     )
   }
   ```

## Current Endpoints

The generator currently includes:

- `GET /` - Root health check
- `GET /health` - Health check endpoint
- `GET /api/nutrition/daily-status` - Daily nutrition status
- `GET /api/nutrition/recommend-dinner` - Dinner recommendations
- `POST /api/ai/score-recipe` - Recipe scoring

## Extending the Generator

### Adding Tags

```gleam
fn generate_tags() -> List(Tag) {
  [
    Tag(name: "My Tag", description: "Description"),
    // ... existing tags
  ]
}
```

### Adding Servers

```gleam
fn generate_servers() -> List(Server) {
  [
    Server(url: "https://api.example.com", description: "Production"),
    // ... existing servers
  ]
}
```

## JSON Schema Types

Supported schema types:

- `StringSchema` - String values
- `IntSchema` - Integer values
- `FloatSchema` - Floating-point numbers
- `BoolSchema` - Boolean values
- `ArraySchema(items)` - Arrays with typed items
- `ObjectSchema(properties)` - Objects with properties
- `RefSchema(ref)` - References to components

## Output Formats

### JSON

Fully compliant OpenAPI 3.1.0 JSON that can be used with:
- Swagger UI
- Redoc
- API client generators
- Validation tools

### YAML

Human-readable YAML format suitable for:
- Documentation
- Version control
- Manual review
- Configuration

## Future Enhancements

Potential improvements:

1. **Auto-Discovery**: Scan route modules to auto-generate specs
2. **Validation**: Validate handler signatures match specs
3. **Examples**: Add request/response examples
4. **Security Schemes**: OAuth, API keys, etc.
5. **Webhooks**: OpenAPI 3.1 webhook support
6. **External Docs**: Link to external documentation

## Testing

Tests are located in `test/openapi/generator_test.gleam`:

```sh
gleam test
```

## Dependencies

- `gleam/dict` - Dictionary operations
- `gleam/json` - JSON encoding
- `gleam/list` - List operations
- `gleam/option` - Optional values
- `gleam/string` - String operations

## License

Same as the main meal-planner project (MIT).
