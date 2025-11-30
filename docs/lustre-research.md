# Lustre Framework Research for Meal Planner Frontend

Research completed for bead `meal-planner-69j`.

## Summary

Lustre is Gleam's primary web framework for building HTML templates, SPAs, and real-time server components. It follows the Model-View-Update (MVU) architecture popularized by Elm.

| Feature | Support | Notes |
|---------|---------|-------|
| MVU Architecture | Full | Elm-inspired, unidirectional data flow |
| SPA Routing | Yes | Via `modem` package, path-based |
| Server Components | Yes | Real-time WebSocket/SSE sync |
| SSR | Yes | `element.to_document_string` |
| Hydration | Manual | JSON serialization pattern |
| Web Components | Yes | Custom elements with shadow DOM |
| Dev Tools | Yes | `lustre_dev_tools` with hot reload |

## MVU Architecture

All Lustre apps follow Model-View-Update:

```gleam
// Model: application state
pub type Model {
  Model(count: Int)
}

// Msg: all ways the world can communicate
pub type Msg {
  Increment
  Decrement
}

// init: create initial state
pub fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(Model(count: 0), effect.none())
}

// update: modify state in response to messages
pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Increment -> #(Model(..model, count: model.count + 1), effect.none())
    Decrement -> #(Model(..model, count: model.count - 1), effect.none())
  }
}

// view: render model to HTML
pub fn view(model: Model) -> element.Element(Msg) {
  html.div([], [
    html.button([event.on_click(Decrement)], [html.text("-")]),
    html.p([], [html.text(int.to_string(model.count))]),
    html.button([event.on_click(Increment)], [html.text("+")]),
  ])
}
```

### Key Principles

1. **Unidirectional data flow**: Model -> View -> Event -> Msg -> Update -> Model
2. **Immutable state**: Model is updated by returning new values, never mutated
3. **Pure view function**: Same model always produces same HTML
4. **Managed effects**: Side effects delegated to runtime via `effect.Effect(Msg)`

## Application Types

Lustre provides four constructors for different use cases:

| Constructor | Use Case | Has Effects |
|-------------|----------|-------------|
| `element()` | Static HTML rendering | No |
| `simple()` | Basic MVU without side effects | No |
| `application()` | Full MVU with effects | Yes |
| `component()` | Encapsulated, embeddable components | Yes |

```gleam
// Most apps use application()
pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}
```

## Routing

Lustre uses the `modem` package for client-side routing:

```gleam
import modem

pub type Route {
  Home
  Recipes
  Recipe(id: String)
  NotFound
}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] -> Home
    ["recipes"] -> Recipes
    ["recipes", id] -> Recipe(id)
    _ -> NotFound
  }
}

// In init, subscribe to route changes
pub fn init(_) {
  #(Model(route: Home), modem.init(on_route_change))
}
```

## Server Components (Real-time)

Server components run on the backend and sync DOM patches to clients via WebSocket:

```gleam
import lustre/server_component

// Server-side: start headless app
pub fn start_counter() {
  let app = lustre.application(init, update, view)
  lustre.start_server_component(app, Nil)
}

// Client-side: render custom element
pub fn render_server_component() {
  server_component.element([
    server_component.route("/ws/counter"),
    server_component.method(server_component.WebSocket),
    server_component.script(),  // Inlines 10KB client runtime
  ], [])
}
```

### Transport Methods

| Method | Direction | Use Case |
|--------|-----------|----------|
| WebSocket | Bidirectional | Interactive apps |
| SSE | Server -> Client | Real-time updates |
| Polling | Server -> Client | Fallback/simple |

## Server-Side Rendering

Render any Lustre element to HTML string:

```gleam
import lustre/element

// Render to HTML string
pub fn render_page(model: Model) -> String {
  view(model)
  |> element.to_document_string  // Adds <!DOCTYPE html>
}

// In Wisp handler
pub fn handle_request(req: Request) -> Response {
  let html = render_page(initial_model())
  response.new(200)
  |> response.set_body(mist.Bytes(bytes_tree.from_string(html)))
}
```

## Hydration Pattern

Lustre doesn't have built-in hydration but provides a clean pattern:

```gleam
// Server: embed state as JSON
pub fn render_with_state(model: Model) -> element.Element(Msg) {
  html.html([], [
    html.head([], []),
    html.body([], [
      html.div([attribute.id("app")], [view(model)]),
      html.script([], "window.__INITIAL_STATE__ = " <> model_to_json(model)),
    ]),
  ])
}

// Client: read state from window
pub fn init(_flags) {
  case read_initial_state() {
    Ok(model) -> #(model, effect.none())
    Error(_) -> #(default_model(), effect.none())
  }
}
```

## Project Architecture (Full-Stack)

Lustre recommends a monorepo with three Gleam projects:

```
meal-planner/
├── client/           # JavaScript SPA target
│   ├── gleam.toml
│   └── src/
├── server/           # Erlang backend target
│   ├── gleam.toml
│   └── src/
└── shared/           # Common types/utils
    ├── gleam.toml
    └── src/
```

This enables:
- Type-safe API contracts via shared types
- Distinct compilation targets (JS vs Erlang)
- Code reuse without runtime conflicts

## Dev Tools

```bash
gleam add --dev lustre_dev_tools
```

Features:
- File watching with auto-rebuild
- Browser hot reload
- Bundle minification (`--minify`)
- Project scaffolding

## Integration with Existing Codebase

For meal-planner, recommended approach:

1. **Keep existing Gleam backend** (Wisp + Mist)
2. **Add Lustre for frontend** in separate `client/` project
3. **Share types** via `shared/` project (Recipe, Macros, etc.)
4. **Start with SSR** using existing view functions
5. **Add interactivity** with hydration where needed
6. **Consider server components** for real-time nutrition dashboard

## Examples Reference

The [Lustre examples](https://github.com/lustre-labs/lustre/tree/main/examples) cover:

| Category | Examples |
|----------|----------|
| Basics | hello-world, attributes, fragments, flags |
| Inputs | controlled-inputs, forms, debouncing |
| Effects | http-requests, timers, local-storage |
| SPAs | routing, hydration |
| Components | attributes-and-events, slots |
| Server | multi-client, pub-sub |

## Decision Matrix for Meal Planner

| Approach | Pros | Cons | Recommended For |
|----------|------|------|-----------------|
| SSR Only | Simple, SEO-friendly | No interactivity | Static recipe pages |
| SPA | Full interactivity | Initial load, no SSR | Nutrition dashboard |
| Server Components | Real-time, low JS | WebSocket overhead | Live calorie tracking |
| Hybrid (SSR + Hydration) | Best of both | More complex | Recipe browsing + editing |

## Recommendation

For the Cronometer-like nutrition tracker:

1. **Phase 1**: SSR recipe pages (reuse existing view code)
2. **Phase 2**: SPA nutrition dashboard with Lustre MVU
3. **Phase 3**: Server components for real-time macro tracking

This matches Lustre's strengths and integrates well with existing Gleam modules.

## Sources

- [Lustre GitHub](https://github.com/lustre-labs/lustre)
- [Lustre API Docs v5.4.0](https://hexdocs.pm/lustre/lustre.html)
- [Lustre Examples](https://hexdocs.pm/lustre/reference/examples.html)
- [Server Components Guide](https://hexdocs.pm/lustre/lustre/server_component.html)
- [SSR Guide](https://hexdocs.pm/lustre/guide/05-server-side-rendering.html)
- [Full-Stack Guide](https://hexdocs.pm/lustre/guide/06-full-stack-applications.html)
- [Wisp + Lustre Tutorial](https://gleaming.dev/articles/building-your-first-gleam-web-app/)
