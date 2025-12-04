/// Recipe Sources Management Page Component
///
/// This page component displays a management interface for recipe sources:
/// - List of available recipe sources (Spoonacular, Manual, etc.)
/// - Configuration forms for API keys
/// - Import recipe functionality
/// - Status indicators for each source
///
/// All interactivity is handled via HTMX (no JavaScript required).
///
/// See: CLAUDE.md (JavaScript Prohibition - CRITICAL RULE)
import gleam/list
import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/ui/components/card
import meal_planner/ui/components/layout
import meal_planner/ui/types/ui_types

/// Recipe source data structure
pub type RecipeSource {
  RecipeSource(
    id: String,
    name: String,
    description: String,
    requires_api_key: Bool,
    is_configured: Bool,
    status: SourceStatus,
    icon: String,
  )
}

/// Source status indicator
pub type SourceStatus {
  Active
  Inactive
  ConfigurationRequired
  Error
}

/// Recipe sources page state
pub type RecipeSourcesData {
  RecipeSourcesData(
    sources: List(RecipeSource),
    selected_source: option.Option(String),
  )
}

/// Render the complete recipe sources management page
///
/// Returns Lustre element for the full page including:
/// - Page header
/// - List of available recipe sources
/// - Configuration forms for each source
/// - Import recipe functionality
/// - Status indicators
///
/// All interactions use HTMX attributes for server-side updates
pub fn render_recipe_sources_page(
  data: RecipeSourcesData,
) -> element.Element(msg) {
  let RecipeSourcesData(sources: sources, selected_source: selected_source) =
    data

  html.div([attribute.class("recipe-sources-page")], [
    render_page_header(),
    html.main([attribute.class("page-content")], [
      layout.container(1200, [
        layout.section([
          html.h2([attribute.class("section-header")], [
            element.text("Available Recipe Sources"),
          ]),
          render_sources_grid(sources, selected_source),
        ]),
        case selected_source {
          option.Some(source_id) ->
            layout.section([
              render_source_configuration(sources, source_id),
            ])
          option.None -> html.div([], [])
        },
      ]),
    ]),
  ])
}

/// Render page header with title and description
fn render_page_header() -> element.Element(msg) {
  html.header([attribute.class("page-header")], [
    html.h1([], [element.text("Recipe Sources")]),
    html.p([attribute.class("subtitle")], [
      element.text(
        "Manage external recipe sources and import recipes into your library",
      ),
    ]),
  ])
}

/// Render grid of recipe sources as cards
fn render_sources_grid(
  sources: List(RecipeSource),
  selected_source: option.Option(String),
) -> element.Element(msg) {
  let source_cards =
    sources
    |> list.map(fn(source) { render_source_card(source, selected_source) })

  layout.grid(ui_types.Responsive, 4, source_cards)
}

/// Render individual recipe source card
fn render_source_card(
  source: RecipeSource,
  selected_source: option.Option(String),
) -> element.Element(msg) {
  let RecipeSource(
    id: id,
    name: name,
    description: description,
    requires_api_key: requires_api_key,
    is_configured: is_configured,
    status: status,
    icon: icon,
  ) = source

  let is_selected = case selected_source {
    option.Some(selected_id) if selected_id == id -> True
    _ -> False
  }

  let card_class = case is_selected {
    True -> "recipe-source-card selected"
    False -> "recipe-source-card"
  }

  html.div(
    [
      attribute.class(card_class),
      attribute.attribute("hx-get", "/api/recipe-sources/" <> id),
      attribute.attribute("hx-target", "#source-config"),
      attribute.attribute("hx-swap", "innerHTML"),
      attribute.attribute("role", "button"),
      attribute.attribute("tabindex", "0"),
    ],
    [
      html.div([attribute.class("source-icon")], [element.text(icon)]),
      html.h3([attribute.class("source-name")], [element.text(name)]),
      html.p([attribute.class("source-description")], [
        element.text(description),
      ]),
      render_status_badge(status, requires_api_key, is_configured),
    ],
  )
}

/// Render status badge for a source
fn render_status_badge(
  status: SourceStatus,
  requires_api_key: Bool,
  is_configured: Bool,
) -> element.Element(msg) {
  let #(badge_class, badge_text) = case
    status,
    requires_api_key,
    is_configured
  {
    Active, _, True -> #("status-badge status-active", "Active")
    Inactive, _, True -> #("status-badge status-inactive", "Inactive")
    ConfigurationRequired, True, False -> #(
      "status-badge status-config-required",
      "API Key Required",
    )
    Error, _, _ -> #("status-badge status-error", "Error")
    _, _, _ -> #("status-badge status-inactive", "Not Configured")
  }

  html.span([attribute.class(badge_class)], [element.text(badge_text)])
}

/// Render source configuration panel
fn render_source_configuration(
  sources: List(RecipeSource),
  source_id: String,
) -> element.Element(msg) {
  // Find the selected source
  let source_opt =
    sources
    |> list.find(fn(s) {
      let RecipeSource(id: id, ..) = s
      id == source_id
    })

  case source_opt {
    Ok(source) -> {
      let RecipeSource(
        id: id,
        name: name,
        requires_api_key: requires_api_key,
        is_configured: is_configured,
        ..,
      ) = source

      html.div(
        [attribute.id("source-config"), attribute.class("source-config")],
        [
          html.h2([attribute.class("config-header")], [
            element.text("Configure " <> name),
          ]),
          case requires_api_key {
            True -> render_api_key_form(id, is_configured)
            False -> render_manual_source_info()
          },
          case is_configured {
            True -> render_import_section(id, name)
            False -> html.div([], [])
          },
        ],
      )
    }
    Error(_) ->
      html.div([attribute.id("source-config")], [
        html.p([], [element.text("Source not found")]),
      ])
  }
}

/// Render API key configuration form with HTMX
fn render_api_key_form(
  source_id: String,
  is_configured: Bool,
) -> element.Element(msg) {
  let form_action = "/api/recipe-sources/" <> source_id <> "/configure"

  html.div([attribute.class("api-key-form-container")], [
    html.div([attribute.class("security-warning")], [
      html.div([attribute.class("warning-icon")], [element.text("⚠️")]),
      html.div([attribute.class("warning-content")], [
        html.strong([], [element.text("Security Notice:")]),
        html.p([], [
          element.text(
            "Your API key will be stored securely and encrypted. Never share your API key publicly.",
          ),
        ]),
      ]),
    ]),
    html.form(
      [
        attribute.class("api-key-form"),
        attribute.attribute("hx-post", form_action),
        attribute.attribute("hx-target", "#config-status"),
        attribute.attribute("hx-swap", "innerHTML"),
        attribute.attribute("hx-indicator", "#save-loading"),
      ],
      [
        html.div([attribute.class("form-group")], [
          html.label([attribute.for("api_key")], [element.text("API Key")]),
          html.input([
            attribute.type_("password"),
            attribute.class("input"),
            attribute.id("api_key"),
            attribute.name("api_key"),
            attribute.placeholder("Enter your API key"),
            attribute.required(True),
          ]),
          html.small([attribute.class("form-hint")], [
            element.text("Get your API key from the source provider's website"),
          ]),
        ]),
        html.div([attribute.class("form-actions")], [
          html.button(
            [attribute.type_("submit"), attribute.class("btn btn-primary")],
            [
              element.text(case is_configured {
                True -> "Update API Key"
                False -> "Save API Key"
              }),
            ],
          ),
          html.span(
            [
              attribute.id("save-loading"),
              attribute.class("htmx-indicator"),
            ],
            [element.text("Saving...")],
          ),
        ]),
        html.div([attribute.id("config-status")], []),
      ],
    ),
  ])
}

/// Render information for manual entry source
fn render_manual_source_info() -> element.Element(msg) {
  html.div([attribute.class("manual-source-info")], [
    html.p([], [
      element.text(
        "This source allows you to manually enter recipes without requiring an API key.",
      ),
    ]),
    html.ul([attribute.class("feature-list")], [
      html.li([], [element.text("Create custom recipes with full control")]),
      html.li([], [element.text("Add ingredients manually")]),
      html.li([], [
        element.text("Calculate nutritional information automatically"),
      ]),
    ]),
  ])
}

/// Render import recipe section with HTMX
fn render_import_section(
  source_id: String,
  source_name: String,
) -> element.Element(msg) {
  html.div([attribute.class("import-section")], [
    html.h3([attribute.class("import-header")], [
      element.text("Import Recipe"),
    ]),
    html.form(
      [
        attribute.class("import-form"),
        attribute.attribute(
          "hx-post",
          "/api/recipe-sources/" <> source_id <> "/import",
        ),
        attribute.attribute("hx-target", "#import-status"),
        attribute.attribute("hx-swap", "innerHTML"),
        attribute.attribute("hx-indicator", "#import-loading"),
      ],
      [
        html.div([attribute.class("form-group")], [
          html.label([attribute.for("recipe_query")], [
            element.text("Recipe Name or URL"),
          ]),
          html.input([
            attribute.type_("text"),
            attribute.class("input"),
            attribute.id("recipe_query"),
            attribute.name("recipe_query"),
            attribute.placeholder("Enter recipe name or URL"),
            attribute.required(True),
          ]),
          html.small([attribute.class("form-hint")], [
            element.text("Search for a recipe from " <> source_name),
          ]),
        ]),
        html.div([attribute.class("form-actions")], [
          html.button(
            [attribute.type_("submit"), attribute.class("btn btn-primary")],
            [element.text("Import Recipe")],
          ),
          html.span(
            [
              attribute.id("import-loading"),
              attribute.class("htmx-indicator"),
            ],
            [element.text("Importing...")],
          ),
        ]),
        html.div([attribute.id("import-status")], []),
      ],
    ),
  ])
}

/// Create default recipe sources list
pub fn default_recipe_sources() -> List(RecipeSource) {
  [
    RecipeSource(
      id: "spoonacular",
      name: "Spoonacular",
      description: "Access thousands of recipes from the Spoonacular API",
      requires_api_key: True,
      is_configured: False,
      status: ConfigurationRequired,
      icon: "🍽️",
    ),
    RecipeSource(
      id: "manual",
      name: "Manual Entry",
      description: "Create and add your own custom recipes",
      requires_api_key: False,
      is_configured: True,
      status: Active,
      icon: "✏️",
    ),
    RecipeSource(
      id: "edamam",
      name: "Edamam",
      description: "Recipe and nutrition data from Edamam API",
      requires_api_key: True,
      is_configured: False,
      status: ConfigurationRequired,
      icon: "🥗",
    ),
    RecipeSource(
      id: "usda",
      name: "USDA Recipes",
      description: "Public domain recipes from USDA database",
      requires_api_key: False,
      is_configured: True,
      status: Active,
      icon: "🏛️",
    ),
  ]
}
