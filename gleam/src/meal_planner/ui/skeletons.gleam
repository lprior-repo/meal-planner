/// Skeleton Loading States Module
///
/// Beautiful skeleton loaders with shimmer animations for all major components.
/// All functions return Lustre SSR elements for server-side rendering.
///
/// Usage:
/// ```gleam
/// case loading_state {
///   Loading -> skeletons.food_card_skeleton()
///   Loaded(data) -> food_card(data)
///   Error(e) -> error_display(e)
/// }
/// ```
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html

// Helper function to create inline style attribute from CSS property list
fn inline_style(properties: List(#(String, String))) -> attribute.Attribute(msg) {
  let css_string =
    properties
    |> list.map(fn(prop) {
      let #(key, value) = prop
      key <> ": " <> value
    })
    |> string.join("; ")

  attribute.attribute("style", css_string)
}

/// Food card skeleton - placeholder for food search results
/// Shows skeleton for food name, type, and macro badges
pub fn food_card_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("food-item skeleton-list-item"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading food item"),
    ],
    [
      html.div([attribute.class("food-info")], [
        html.div(
          [attribute.class("skeleton skeleton-text skeleton-text-3/4")],
          [],
        ),
        html.div(
          [attribute.class("skeleton skeleton-text skeleton-text-1/2")],
          [],
        ),
      ]),
      html.div([attribute.class("skeleton-badges")], [
        html.div([attribute.class("skeleton-badge")], []),
        html.div([attribute.class("skeleton-badge")], []),
        html.div([attribute.class("skeleton-badge")], []),
      ]),
    ],
  )
}

/// Recipe card skeleton - placeholder for recipe cards
/// Shows skeleton for recipe title, category, time, and nutrition info
pub fn recipe_card_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("recipe-card skeleton-card"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading recipe"),
    ],
    [
      html.div([attribute.class("skeleton-content")], [
        html.div(
          [attribute.class("skeleton skeleton-text skeleton-text-full")],
          [],
        ),
        html.div(
          [attribute.class("skeleton skeleton-text skeleton-text-1/2")],
          [],
        ),
        html.div(
          [
            attribute.class("skeleton skeleton-text skeleton-text-1/4"),
            inline_style([#("margin-top", "var(--space-3)")]),
          ],
          [],
        ),
      ]),
      html.div([attribute.class("skeleton-badges")], [
        html.div([attribute.class("skeleton-badge")], []),
        html.div([attribute.class("skeleton-badge")], []),
        html.div([attribute.class("skeleton-badge")], []),
        html.div([attribute.class("skeleton-badge")], []),
      ]),
    ],
  )
}

/// Meal log entry skeleton - placeholder for daily meal log entries
/// Shows skeleton for time, food name, portion, macros, and calories
pub fn meal_log_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("meal-entry-item"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading meal entry"),
    ],
    [
      html.div([attribute.class("entry-time")], [
        html.div(
          [
            attribute.class("skeleton skeleton-text"),
            inline_style([#("height", "14px"), #("width", "50px")]),
          ],
          [],
        ),
      ]),
      html.div([attribute.class("entry-details")], [
        html.div(
          [attribute.class("skeleton skeleton-text skeleton-text-3/4")],
          [],
        ),
        html.div(
          [
            attribute.class("skeleton skeleton-text skeleton-text-1/2"),
            inline_style([#("margin-top", "var(--space-1)")]),
          ],
          [],
        ),
      ]),
      html.div([attribute.class("entry-macros")], [
        html.div([attribute.class("skeleton-badge")], []),
        html.div([attribute.class("skeleton-badge")], []),
        html.div([attribute.class("skeleton-badge")], []),
      ]),
      html.div([attribute.class("entry-calories")], [
        html.div(
          [
            attribute.class("skeleton skeleton-text"),
            inline_style([#("height", "16px"), #("width", "60px")]),
          ],
          [],
        ),
      ]),
      html.div(
        [attribute.class("entry-actions"), inline_style([#("opacity", "0")])],
        [
          html.div(
            [
              attribute.class("skeleton"),
              inline_style([
                #("width", "32px"),
                #("height", "32px"),
                #("border-radius", "var(--radius-md)"),
              ]),
            ],
            [],
          ),
          html.div(
            [
              attribute.class("skeleton"),
              inline_style([
                #("width", "32px"),
                #("height", "32px"),
                #("border-radius", "var(--radius-md)"),
              ]),
            ],
            [],
          ),
        ],
      ),
    ],
  )
}

/// Macro progress bar skeleton - placeholder for macro tracking charts
/// Shows skeleton for protein, fat, and carbs progress bars
pub fn macro_chart_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("macro-bars"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading macro progress"),
    ],
    [
      macro_bar_skeleton(),
      macro_bar_skeleton(),
      macro_bar_skeleton(),
    ],
  )
}

fn macro_bar_skeleton() -> element.Element(msg) {
  html.div([attribute.class("macro-bar skeleton-progress-bar")], [
    html.div([attribute.class("macro-bar-header")], [
      html.div(
        [
          attribute.class("skeleton skeleton-text"),
          inline_style([#("height", "14px"), #("width", "80px")]),
        ],
        [],
      ),
      html.div(
        [
          attribute.class("skeleton skeleton-text"),
          inline_style([#("height", "14px"), #("width", "60px")]),
        ],
        [],
      ),
    ]),
    html.div([attribute.class("progress-bar")], [
      html.div([attribute.class("skeleton-bar")], []),
    ]),
  ])
}

/// Micronutrient panel skeleton - placeholder for micronutrient visualization
/// Shows skeleton for vitamin and mineral progress bars
pub fn micronutrient_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("micronutrient-panel"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading micronutrients"),
    ],
    [
      html.div([attribute.class("micro-section")], [
        html.div(
          [
            attribute.class("skeleton skeleton-text skeleton-text-1/4"),
            inline_style([
              #("height", "20px"),
              #("margin-bottom", "var(--space-3)"),
            ]),
          ],
          [],
        ),
        html.div([attribute.class("micro-list")], [
          micronutrient_bar_skeleton(),
          micronutrient_bar_skeleton(),
          micronutrient_bar_skeleton(),
        ]),
      ]),
      html.div([attribute.class("micro-section")], [
        html.div(
          [
            attribute.class("skeleton skeleton-text skeleton-text-1/4"),
            inline_style([
              #("height", "20px"),
              #("margin-bottom", "var(--space-3)"),
            ]),
          ],
          [],
        ),
        html.div([attribute.class("micro-list")], [
          micronutrient_bar_skeleton(),
          micronutrient_bar_skeleton(),
          micronutrient_bar_skeleton(),
        ]),
      ]),
    ],
  )
}

fn micronutrient_bar_skeleton() -> element.Element(msg) {
  html.div([attribute.class("micronutrient-bar")], [
    html.div([attribute.class("micro-header")], [
      html.div(
        [
          attribute.class("skeleton skeleton-text"),
          inline_style([#("height", "14px"), #("width", "100px")]),
        ],
        [],
      ),
      html.div(
        [
          attribute.class("skeleton skeleton-text"),
          inline_style([#("height", "12px"), #("width", "60px")]),
        ],
        [],
      ),
    ]),
    html.div([attribute.class("micro-progress")], [
      html.div([attribute.class("skeleton-bar")], []),
    ]),
    html.div(
      [
        attribute.class("skeleton skeleton-text"),
        inline_style([
          #("height", "12px"),
          #("width", "40px"),
          #("margin-top", "var(--space-1)"),
        ]),
      ],
      [],
    ),
  ])
}

/// Table row skeleton - placeholder for data table rows
/// Accepts count parameter for number of rows to display
pub fn table_row_skeleton(count: Int) -> element.Element(msg) {
  let rows =
    list.range(1, count)
    |> list.map(fn(_) { single_table_row_skeleton() })

  html.tbody([], rows)
}

fn single_table_row_skeleton() -> element.Element(msg) {
  html.tr(
    [
      attribute.class("skeleton-table-row"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading table row"),
    ],
    [
      html.td([], [
        html.div(
          [attribute.class("skeleton skeleton-text skeleton-text-3/4")],
          [],
        ),
      ]),
      html.td([], [
        html.div(
          [attribute.class("skeleton skeleton-text skeleton-text-1/2")],
          [],
        ),
      ]),
      html.td([], [
        html.div(
          [attribute.class("skeleton skeleton-text skeleton-text-1/4")],
          [],
        ),
      ]),
      html.td([], [
        html.div(
          [attribute.class("skeleton skeleton-text skeleton-text-1/2")],
          [],
        ),
      ]),
    ],
  )
}

/// Form skeleton - placeholder for form loading states
/// Shows skeleton for form fields and submit button
pub fn form_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("card skeleton-card"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading form"),
    ],
    [
      html.div([attribute.class("card-header")], [
        html.div(
          [
            attribute.class("skeleton skeleton-text skeleton-text-1/2"),
            inline_style([#("height", "32px")]),
          ],
          [],
        ),
        html.div(
          [
            attribute.class("skeleton skeleton-text skeleton-text-full"),
            inline_style([
              #("height", "16px"),
              #("margin-top", "var(--space-2)"),
            ]),
          ],
          [],
        ),
      ]),
      html.div([attribute.class("card-body")], [
        form_field_skeleton(),
        form_field_skeleton(),
        html.div([attribute.class("grid grid-cols-2 gap-4")], [
          form_field_skeleton(),
          form_field_skeleton(),
        ]),
        form_field_skeleton(),
      ]),
      html.div([attribute.class("card-footer")], [
        html.div(
          [
            attribute.class("skeleton"),
            inline_style([
              #("width", "140px"),
              #("height", "42px"),
              #("border-radius", "var(--radius-md)"),
            ]),
          ],
          [],
        ),
        html.div(
          [
            attribute.class("skeleton"),
            inline_style([
              #("width", "100px"),
              #("height", "42px"),
              #("border-radius", "var(--radius-md)"),
            ]),
          ],
          [],
        ),
      ]),
    ],
  )
}

fn form_field_skeleton() -> element.Element(msg) {
  html.div([attribute.class("form-group")], [
    html.div(
      [
        attribute.class("skeleton skeleton-text"),
        inline_style([
          #("height", "16px"),
          #("width", "120px"),
          #("margin-bottom", "var(--space-2)"),
        ]),
      ],
      [],
    ),
    html.div(
      [
        attribute.class("skeleton"),
        inline_style([
          #("height", "42px"),
          #("width", "100%"),
          #("border-radius", "var(--radius-md)"),
        ]),
      ],
      [],
    ),
  ])
}

/// Search box skeleton - placeholder for search input
pub fn search_box_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("search-box"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading search"),
    ],
    [
      html.div(
        [
          attribute.class("skeleton"),
          inline_style([
            #("flex", "1"),
            #("height", "42px"),
            #("border-radius", "var(--radius-md)"),
          ]),
        ],
        [],
      ),
      html.div(
        [
          attribute.class("skeleton"),
          inline_style([
            #("width", "100px"),
            #("height", "42px"),
            #("border-radius", "var(--radius-md)"),
          ]),
        ],
        [],
      ),
    ],
  )
}

/// Card stat skeleton - placeholder for statistics cards
pub fn card_stat_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("card card-stat skeleton-card"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading statistic"),
    ],
    [
      html.div(
        [
          attribute.class("skeleton"),
          inline_style([
            #("width", "100px"),
            #("height", "64px"),
            #("margin-bottom", "var(--space-2)"),
          ]),
        ],
        [],
      ),
      html.div(
        [
          attribute.class("skeleton skeleton-text"),
          inline_style([
            #("height", "12px"),
            #("width", "60px"),
            #("margin-top", "var(--space-1)"),
          ]),
        ],
        [],
      ),
      html.div(
        [
          attribute.class("skeleton skeleton-text"),
          inline_style([
            #("height", "16px"),
            #("width", "80px"),
            #("margin-top", "var(--space-2)"),
          ]),
        ],
        [],
      ),
    ],
  )
}

/// List skeleton - placeholder for generic lists
/// Accepts count parameter for number of list items
pub fn list_skeleton(count: Int) -> element.Element(msg) {
  let items =
    list.range(1, count)
    |> list.map(fn(_) {
      html.div([attribute.class("skeleton-list-item")], [
        html.div(
          [attribute.class("skeleton skeleton-text skeleton-text-full")],
          [],
        ),
        html.div(
          [attribute.class("skeleton skeleton-text skeleton-text-3/4")],
          [],
        ),
        html.div([attribute.class("skeleton-badges")], [
          html.div([attribute.class("skeleton-badge")], []),
          html.div([attribute.class("skeleton-badge")], []),
        ]),
      ])
    })

  html.div(
    [
      attribute.class("food-list"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading list"),
    ],
    items,
  )
}

/// Page skeleton - full page loading state
/// Shows skeleton for header, content area, and optional sidebar
pub fn page_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("loading-page"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading page"),
    ],
    [
      html.div([attribute.class("loading-page-content")], [
        html.div([attribute.class("spinner-large")], []),
        html.div([attribute.class("loading-title")], [
          element.text("Loading..."),
        ]),
        html.div([attribute.class("loading-subtitle")], [
          element.text("Please wait while we prepare your content"),
        ]),
      ]),
    ],
  )
}

/// Loading overlay skeleton - for in-place content loading
pub fn loading_overlay(message: String) -> element.Element(msg) {
  html.div(
    [
      attribute.class("loading-overlay"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading"),
    ],
    [
      html.div([attribute.class("loading-overlay-content")], [
        html.div([attribute.class("spinner-standard")], []),
        html.p([attribute.class("loading-message")], [element.text(message)]),
      ]),
    ],
  )
}

/// Inline spinner - for buttons and inline content
pub fn inline_spinner() -> element.Element(msg) {
  html.span(
    [
      attribute.class("spinner-inline"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading"),
    ],
    [
      html.span([attribute.class("spinner-dot")], []),
      html.span([attribute.class("spinner-dot")], []),
      html.span([attribute.class("spinner-dot")], []),
    ],
  )
}

/// Meal section skeleton - collapsible meal section with entries
pub fn meal_section_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("meal-section"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading meal section"),
    ],
    [
      html.div([attribute.class("meal-section-header")], [
        html.div(
          [
            attribute.class("skeleton skeleton-text"),
            inline_style([#("height", "24px"), #("width", "120px")]),
          ],
          [],
        ),
        html.div(
          [
            attribute.class("skeleton skeleton-text"),
            inline_style([#("height", "16px"), #("width", "60px")]),
          ],
          [],
        ),
        html.div(
          [
            attribute.class("skeleton skeleton-text"),
            inline_style([#("height", "16px"), #("width", "80px")]),
          ],
          [],
        ),
        html.div(
          [
            attribute.class("skeleton"),
            inline_style([
              #("width", "32px"),
              #("height", "32px"),
              #("border-radius", "var(--radius-md)"),
            ]),
          ],
          [],
        ),
      ]),
      html.div([attribute.class("meal-section-body")], [
        meal_log_skeleton(),
        meal_log_skeleton(),
        meal_log_skeleton(),
      ]),
    ],
  )
}

/// Daily log timeline skeleton - full day view with multiple meal sections
pub fn daily_log_timeline_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("daily-log-timeline"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading daily log"),
    ],
    [
      meal_section_skeleton(),
      meal_section_skeleton(),
      meal_section_skeleton(),
      meal_section_skeleton(),
    ],
  )
}

/// Recipe grid skeleton - grid of recipe cards
pub fn recipe_grid_skeleton(count: Int) -> element.Element(msg) {
  let cards =
    list.range(1, count)
    |> list.map(fn(_) { recipe_card_skeleton() })

  html.div(
    [
      attribute.class("grid grid-cols-3 gap-4"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading recipes"),
    ],
    cards,
  )
}

/// Food search results skeleton - list of food items
pub fn food_search_results_skeleton(count: Int) -> element.Element(msg) {
  let items =
    list.range(1, count)
    |> list.map(fn(_) { food_card_skeleton() })

  html.div(
    [
      attribute.class("food-list"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading search results"),
    ],
    items,
  )
}

/// Dashboard skeleton - full dashboard with stats and charts
pub fn dashboard_skeleton() -> element.Element(msg) {
  html.div(
    [
      attribute.class("container"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-label", "Loading dashboard"),
    ],
    [
      html.div([attribute.class("page-header")], [
        html.div(
          [
            attribute.class("skeleton skeleton-text skeleton-text-1/2"),
            inline_style([#("height", "40px")]),
          ],
          [],
        ),
        html.div(
          [
            attribute.class("skeleton skeleton-text skeleton-text-full"),
            inline_style([
              #("height", "20px"),
              #("margin-top", "var(--space-2)"),
            ]),
          ],
          [],
        ),
      ]),
      html.div(
        [
          attribute.class("grid grid-cols-4 gap-4"),
          inline_style([#("margin-bottom", "var(--space-6)")]),
        ],
        [
          card_stat_skeleton(),
          card_stat_skeleton(),
          card_stat_skeleton(),
          card_stat_skeleton(),
        ],
      ),
      html.div([attribute.class("grid grid-cols-2 gap-6")], [
        html.div([attribute.class("card skeleton-card")], [
          html.div([attribute.class("card-header")], [
            html.div(
              [
                attribute.class("skeleton skeleton-text skeleton-text-1/3"),
                inline_style([#("height", "24px")]),
              ],
              [],
            ),
          ]),
          html.div([attribute.class("card-body")], [macro_chart_skeleton()]),
        ]),
        html.div([attribute.class("card skeleton-card")], [
          html.div([attribute.class("card-header")], [
            html.div(
              [
                attribute.class("skeleton skeleton-text skeleton-text-1/3"),
                inline_style([#("height", "24px")]),
              ],
              [],
            ),
          ]),
          html.div([attribute.class("card-body")], [micronutrient_skeleton()]),
        ]),
      ]),
    ],
  )
}
