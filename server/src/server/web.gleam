//// Wisp web server for the meal planner application

import gleam/dynamic/decode
import gleam/erlang/process
import gleam/float
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element
import lustre/element/html
import mist
import wisp
import wisp/wisp_mist

import server/storage
import server/usda_api
import server/web_helpers
import shared/types

// ============================================================================
// Main Server Entry
// ============================================================================

pub fn main() {
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)

  // Start the server
  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(3000)
    |> mist.start

  // Keep the process alive
  process.sleep_forever()
}

// ============================================================================
// Request Handler
// ============================================================================

fn handle_request(req: wisp.Request) -> wisp.Response {
  use req <- middleware(req)

  case wisp.path_segments(req) {
    // Home page
    [] -> home_page()

    // Static assets
    ["static", ..rest] -> serve_static(req, rest)

    // API routes (keep for potential future use)
    ["api", ..rest] -> handle_api(req, rest)

    // SSR pages
    ["recipes"] -> recipes_page()
    ["recipes", "new"] -> new_recipe_page()
    ["recipes", id, "edit"] -> edit_recipe_page(id)
    ["recipes", id] -> recipe_detail_page(id)
    ["dashboard"] -> dashboard_page(req)
    ["profile"] -> profile_page()
    ["log"] -> log_meal_page()
    ["log", recipe_id] -> log_meal_form(recipe_id)

    // 404
    _ -> not_found_page()
  }
}

fn middleware(
  req: wisp.Request,
  handler: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handler(req)
}

// ============================================================================
// Pages
// ============================================================================

fn home_page() -> wisp.Response {
  let content = [
    html.div([attribute.class("hero")], [
      html.h1([], [element.text("Meal Planner")]),
      html.p([attribute.class("tagline")], [
        element.text("Track your nutrition. Reach your goals."),
      ]),
    ]),
    html.nav([attribute.class("home-nav")], [
      html.a([attribute.href("/dashboard"), attribute.class("nav-card")], [
        html.span([attribute.class("nav-icon")], [element.text("📊")]),
        html.span([], [element.text("Dashboard")]),
      ]),
      html.a([attribute.href("/recipes"), attribute.class("nav-card")], [
        html.span([attribute.class("nav-icon")], [element.text("🍽")]),
        html.span([], [element.text("Recipes")]),
      ]),
      html.a([attribute.href("/profile"), attribute.class("nav-card")], [
        html.span([attribute.class("nav-icon")], [element.text("👤")]),
        html.span([], [element.text("Profile")]),
      ]),
    ]),
  ]

  wisp.html_response(render_page("Meal Planner", content), 200)
}

fn not_found_page() -> wisp.Response {
  let content = [
    html.div([attribute.class("not-found")], [
      html.h1([], [element.text("404")]),
      html.p([], [element.text("Page not found")]),
      html.a([attribute.href("/"), attribute.class("btn")], [
        element.text("Go Home"),
      ]),
    ]),
  ]

  wisp.html_response(render_page("Not Found - Meal Planner", content), 404)
}

fn recipes_page() -> wisp.Response {
  // TODO: Load recipes from storage
  let recipes = sample_recipes()

  let content = [
    html.div([attribute.class("page-header")], [
      html.h1([], [element.text("Recipes")]),
      html.p([attribute.class("subtitle")], [
        element.text("Browse our collection of healthy meals"),
      ]),
      html.a([attribute.href("/recipes/new"), attribute.class("btn btn-primary")], [
        element.text("+ New Recipe"),
      ]),
    ]),
    html.div([attribute.class("recipe-grid")], list.map(recipes, recipe_card)),
  ]

  let html_str = render_page("Recipes - Meal Planner", content)
  wisp.html_response(html_str, 200)
}

fn recipe_card(recipe: types.Recipe) -> element.Element(msg) {
  let calories = types.macros_calories(recipe.macros)
  html.a(
    [
      attribute.class("recipe-card"),
      attribute.href("/recipes/" <> recipe.id),
    ],
    [
      html.div([attribute.class("recipe-card-content")], [
        html.h3([attribute.class("recipe-title")], [element.text(recipe.name)]),
        html.span([attribute.class("recipe-category")], [
          element.text(recipe.category),
        ]),
        html.div([attribute.class("recipe-macros")], [
          macro_badge("P", recipe.macros.protein),
          macro_badge("F", recipe.macros.fat),
          macro_badge("C", recipe.macros.carbs),
        ]),
        html.div([attribute.class("recipe-calories")], [
          element.text(float_to_string(calories) <> " cal"),
        ]),
      ]),
    ],
  )
}

fn macro_badge(label: String, value: Float) -> element.Element(msg) {
  html.span([attribute.class("macro-badge")], [
    element.text(label <> ": " <> float_to_string(value) <> "g"),
  ])
}

fn recipe_detail_page(id: String) -> wisp.Response {
  let recipes = sample_recipes()

  case list.find(recipes, fn(r) { r.id == id }) {
    Ok(recipe) -> {
      let content = [
        html.a([attribute.href("/recipes"), attribute.class("back-link")], [
          element.text("← Back to recipes"),
        ]),
        html.div([attribute.class("recipe-detail")], [
          html.div([attribute.class("recipe-detail-header")], [
            html.h1([], [element.text(recipe.name)]),
            html.div([attribute.class("recipe-actions")], [
              html.a([attribute.href("/recipes/" <> id <> "/edit"), attribute.class("btn btn-secondary")], [
                element.text("Edit"),
              ]),
              html.form([
                attribute.method("POST"),
                attribute.action("/api/recipes/" <> id),
                attribute.attribute("onsubmit", "return confirm('Delete this recipe?')"),
                attribute.style("display", "inline"),
              ], [
                html.input([attribute.type_("hidden"), attribute.name("_method"), attribute.value("DELETE")]),
                html.button([attribute.type_("submit"), attribute.class("btn btn-danger")], [
                  element.text("Delete"),
                ]),
              ]),
            ]),
          ]),
          html.p([attribute.class("meta")], [
            element.text("Category: " <> recipe.category),
          ]),
          // Macro summary card
          html.div([attribute.class("macro-card")], [
            html.h2([], [element.text("Nutrition per serving")]),
            html.div([attribute.class("macro-grid")], [
              macro_stat_block(
                "Protein",
                float_to_string(recipe.macros.protein) <> "g",
              ),
              macro_stat_block("Fat", float_to_string(recipe.macros.fat) <> "g"),
              macro_stat_block(
                "Carbs",
                float_to_string(recipe.macros.carbs) <> "g",
              ),
              macro_stat_block(
                "Calories",
                float_to_string(types.macros_calories(recipe.macros)),
              ),
            ]),
          ]),
          // Ingredients
          html.div([attribute.class("ingredients")], [
            html.h2([], [element.text("Ingredients")]),
            html.ul(
              [],
              list.map(recipe.ingredients, fn(ing) {
                html.li([], [element.text(ing.quantity <> " " <> ing.name)])
              }),
            ),
          ]),
          // Instructions
          html.div([attribute.class("instructions")], [
            html.h2([], [element.text("Instructions")]),
            html.ol(
              [],
              list.index_map(recipe.instructions, fn(step, _i) {
                html.li([], [element.text(step)])
              }),
            ),
          ]),
        ]),
      ]

      let html_str = render_page(recipe.name <> " - Meal Planner", content)
      wisp.html_response(html_str, 200)
    }
    Error(_) -> wisp.not_found()
  }
}

fn macro_stat_block(label: String, value: String) -> element.Element(msg) {
  html.div([attribute.class("macro-stat")], [
    html.span([attribute.class("macro-value")], [element.text(value)]),
    html.span([attribute.class("macro-name")], [element.text(label)]),
  ])
}

fn dashboard_page(req: wisp.Request) -> wisp.Response {
  use conn <- storage.with_connection(storage.db_path)

  let today = web_helpers.get_today_date()
  let profile = storage.get_user_profile_or_default(conn)
  let log = case storage.get_daily_log(conn, today) {
    Ok(l) -> l
    Error(_) ->
      types.DailyLog(
        date: today,
        entries: [],
        total_macros: types.macros_zero(),
        total_micronutrients: types.micronutrients_zero(),
      )
  }
  let entries = log.entries

  // Get filter from query params
  let filter = case wisp.get_query(req) {
    [#("filter", f), ..] -> f
    _ -> "all"
  }

  // Filter entries by meal type
  let filtered_entries = case filter {
    "breakfast" ->
      list.filter(entries, fn(e: types.FoodLogEntry) {
        e.meal_type == types.Breakfast
      })
    "lunch" ->
      list.filter(entries, fn(e: types.FoodLogEntry) {
        e.meal_type == types.Lunch
      })
    "dinner" ->
      list.filter(entries, fn(e: types.FoodLogEntry) {
        e.meal_type == types.Dinner
      })
    "snack" ->
      list.filter(entries, fn(e: types.FoodLogEntry) {
        e.meal_type == types.Snack
      })
    _ -> entries
  }

  let targets = types.daily_macro_targets(profile)
  let current = sum_macros(filtered_entries)

  let content = [
    page_header("Dashboard", "/"),
    html.div([attribute.class("dashboard")], [
      // Date
      html.p([attribute.class("date")], [element.text(today)]),
      // Filter buttons
      html.div([attribute.class("filter-buttons")], [
        filter_btn("All", "all", filter),
        filter_btn("Breakfast", "breakfast", filter),
        filter_btn("Lunch", "lunch", filter),
        filter_btn("Dinner", "dinner", filter),
        filter_btn("Snack", "snack", filter),
      ]),
      // Calorie summary
      html.div([attribute.class("calorie-summary")], [
        html.div([attribute.class("calorie-current")], [
          html.span([attribute.class("big-number")], [
            element.text(float_to_string(types.macros_calories(current))),
          ]),
          html.span([], [element.text(" / ")]),
          html.span([], [
            element.text(float_to_string(types.macros_calories(targets))),
          ]),
          html.span([attribute.class("unit")], [element.text(" cal")]),
        ]),
      ]),
      // Macro bars
      html.div([attribute.class("macro-bars")], [
        macro_bar("Protein", current.protein, targets.protein, "#28a745"),
        macro_bar("Fat", current.fat, targets.fat, "#ffc107"),
        macro_bar("Carbs", current.carbs, targets.carbs, "#17a2b8"),
      ]),
      // Logged meals
      html.div([attribute.class("logged-meals")], [
        html.h3([], [element.text("Today's Meals")]),
        case filtered_entries {
          [] ->
            html.p([attribute.class("empty")], [
              element.text("No meals logged yet"),
            ])
          _ ->
            html.ul(
              [attribute.class("meal-list")],
              list.map(filtered_entries, meal_entry_item),
            )
        },
      ]),
      // Quick actions
      html.div([attribute.class("quick-actions")], [
        html.a([attribute.href("/log"), attribute.class("btn")], [
          element.text("Add Meal"),
        ]),
      ]),
    ]),
  ]

  wisp.html_response(render_page("Dashboard - Meal Planner", content), 200)
}

fn filter_btn(
  label: String,
  value: String,
  current: String,
) -> element.Element(msg) {
  let class = case value == current {
    True -> "filter-btn active"
    False -> "filter-btn"
  }
  html.a(
    [attribute.href("/dashboard?filter=" <> value), attribute.class(class)],
    [
      element.text(label),
    ],
  )
}

fn meal_entry_item(entry: types.FoodLogEntry) -> element.Element(msg) {
  html.li([attribute.class("meal-entry")], [
    html.div([attribute.class("meal-info")], [
      html.span([attribute.class("meal-name")], [
        element.text(entry.recipe_name),
      ]),
      html.span([attribute.class("meal-servings")], [
        element.text(" (" <> float_to_string(entry.servings) <> " serving)"),
      ]),
      html.span([attribute.class("meal-type-badge")], [
        element.text(types.meal_type_to_string(entry.meal_type)),
      ]),
    ]),
    html.div([attribute.class("meal-macros")], [
      element.text(
        float_to_string(entry.macros.protein)
        <> "P / "
        <> float_to_string(entry.macros.fat)
        <> "F / "
        <> float_to_string(entry.macros.carbs)
        <> "C",
      ),
    ]),
    html.a(
      [
        attribute.href("/api/logs/entry/" <> entry.id <> "?action=delete"),
        attribute.class("delete-btn"),
      ],
      [
        element.text("×"),
      ],
    ),
  ])
}

fn sum_macros(entries: List(types.FoodLogEntry)) -> types.Macros {
  list.fold(entries, types.macros_zero(), fn(acc, entry) {
    types.Macros(
      protein: acc.protein +. entry.macros.protein,
      fat: acc.fat +. entry.macros.fat,
      carbs: acc.carbs +. entry.macros.carbs,
    )
  })
}

fn macro_bar(
  label: String,
  current: Float,
  target: Float,
  color: String,
) -> element.Element(msg) {
  let pct = case target >. 0.0 {
    True -> current /. target *. 100.0
    False -> 0.0
  }
  let pct_capped = case pct >. 100.0 {
    True -> 100.0
    False -> pct
  }

  html.div([attribute.class("macro-bar")], [
    html.div([attribute.class("macro-bar-header")], [
      html.span([], [element.text(label)]),
      html.span([], [
        element.text(
          float_to_string(current) <> "g / " <> float_to_string(target) <> "g",
        ),
      ]),
    ]),
    html.div([attribute.class("progress-bar")], [
      html.div(
        [
          attribute.class("progress-fill"),
          attribute.style(
            "width",
            float_to_string(pct_capped) <> "%; background:" <> color,
          ),
        ],
        [],
      ),
    ]),
  ])
}

fn profile_page() -> wisp.Response {
  let profile = sample_profile()
  let targets = types.daily_macro_targets(profile)

  let content = [
    page_header("Profile", "/"),
    html.div([attribute.class("profile")], [
      html.div([attribute.class("profile-section")], [
        html.h2([], [element.text("Stats")]),
        html.dl([], [
          html.dt([], [element.text("Bodyweight")]),
          html.dd([], [
            element.text(float_to_string(profile.bodyweight) <> " lbs"),
          ]),
          html.dt([], [element.text("Activity Level")]),
          html.dd([], [
            element.text(types.activity_level_to_string(profile.activity_level)),
          ]),
          html.dt([], [element.text("Goal")]),
          html.dd([], [element.text(types.goal_to_string(profile.goal))]),
          html.dt([], [element.text("Meals per Day")]),
          html.dd([], [element.text(int_to_string(profile.meals_per_day))]),
        ]),
      ]),
      html.div([attribute.class("profile-section")], [
        html.h2([], [element.text("Daily Targets")]),
        html.dl([], [
          html.dt([], [element.text("Calories")]),
          html.dd([], [
            element.text(float_to_string(types.macros_calories(targets))),
          ]),
          html.dt([], [element.text("Protein")]),
          html.dd([], [element.text(float_to_string(targets.protein) <> "g")]),
          html.dt([], [element.text("Fat")]),
          html.dd([], [element.text(float_to_string(targets.fat) <> "g")]),
          html.dt([], [element.text("Carbs")]),
          html.dd([], [element.text(float_to_string(targets.carbs) <> "g")]),
        ]),
      ]),
    ]),
  ]

  wisp.html_response(render_page("Profile - Meal Planner", content), 200)
}

fn log_meal_page() -> wisp.Response {
  let recipes = sample_recipes()

  let content = [
    page_header("Log Meal", "/dashboard"),
    html.div([attribute.class("page-description")], [
      html.p([], [element.text("Select a recipe to log:")]),
    ]),
    html.div([attribute.class("recipe-grid")],
      list.map(recipes, fn(recipe) {
        html.a(
          [
            attribute.class("recipe-card"),
            attribute.href("/log/" <> recipe.id),
          ],
          [
            html.div([attribute.class("recipe-card-content")], [
              html.h3([attribute.class("recipe-title")], [element.text(recipe.name)]),
              html.span([attribute.class("recipe-category")], [
                element.text(recipe.category),
              ]),
              html.div([attribute.class("recipe-macros")], [
                macro_badge("P", recipe.macros.protein),
                macro_badge("F", recipe.macros.fat),
                macro_badge("C", recipe.macros.carbs),
              ]),
              html.div([attribute.class("recipe-calories")], [
                element.text(float_to_string(types.macros_calories(recipe.macros)) <> " cal"),
              ]),
            ]),
          ],
        )
      })
    ),
  ]

  wisp.html_response(render_page("Log Meal - Meal Planner", content), 200)
}

fn log_meal_form(recipe_id: String) -> wisp.Response {
  let recipes = sample_recipes()

  case list.find(recipes, fn(r) { r.id == recipe_id }) {
    Ok(recipe) -> {
      let content = [
        html.a([attribute.href("/log"), attribute.class("back-link")], [
          element.text("← Back to recipe selection"),
        ]),
        html.div([attribute.class("log-form-container")], [
          html.h1([], [element.text("Log: " <> recipe.name)]),
          html.div([attribute.class("recipe-summary")], [
            html.p([attribute.class("meta")], [
              element.text("Per serving: " <> float_to_string(types.macros_calories(recipe.macros)) <> " cal"),
            ]),
            html.div([attribute.class("macro-badges")], [
              macro_badge("P", recipe.macros.protein),
              macro_badge("F", recipe.macros.fat),
              macro_badge("C", recipe.macros.carbs),
            ]),
          ]),
          html.form(
            [
              attribute.method("POST"),
              attribute.action("/api/logs?recipe_id=" <> recipe_id),
              attribute.class("log-form"),
            ],
            [
              html.div([attribute.class("form-group")], [
                html.label([attribute.attribute("for", "servings")], [
                  element.text("Servings"),
                ]),
                html.input([
                  attribute.type_("number"),
                  attribute.id("servings"),
                  attribute.name("servings"),
                  attribute.attribute("min", "0.1"),
                  attribute.attribute("step", "0.1"),
                  attribute.value("1.0"),
                  attribute.required(True),
                ]),
              ]),
              html.div([attribute.class("form-group")], [
                html.label([attribute.attribute("for", "meal_type")], [
                  element.text("Meal Type"),
                ]),
                html.select(
                  [
                    attribute.id("meal_type"),
                    attribute.name("meal_type"),
                    attribute.required(True),
                  ],
                  [
                    html.option([attribute.value("breakfast")], "Breakfast"),
                    html.option([attribute.value("lunch")], "Lunch"),
                    html.option([attribute.value("dinner")], "Dinner"),
                    html.option([attribute.value("snack")], "Snack"),
                  ],
                ),
              ]),
              html.div([attribute.class("form-actions")], [
                html.button([attribute.type_("submit"), attribute.class("btn btn-primary")], [
                  element.text("Log Meal"),
                ]),
                html.a([attribute.href("/log"), attribute.class("btn btn-secondary")], [
                  element.text("Cancel"),
                ]),
              ]),
            ],
          ),
        ]),
      ]

      wisp.html_response(render_page("Log " <> recipe.name <> " - Meal Planner", content), 200)
    }
    Error(_) -> not_found_page()
  }
}

fn new_recipe_page() -> wisp.Response {
  let content = [
    html.a([attribute.href("/recipes"), attribute.class("back-link")], [
      element.text("← Back to recipes"),
    ]),
    html.div([attribute.class("recipe-form-container")], [
      html.h1([], [element.text("Create New Recipe")]),
      recipe_form(None),
    ]),
  ]

  wisp.html_response(render_page("New Recipe - Meal Planner", content), 200)
}

fn edit_recipe_page(id: String) -> wisp.Response {
  let recipes = sample_recipes()

  case list.find(recipes, fn(r) { r.id == id }) {
    Ok(recipe) -> {
      let content = [
        html.a([attribute.href("/recipes/" <> id), attribute.class("back-link")], [
          element.text("← Back to recipe"),
        ]),
        html.div([attribute.class("recipe-form-container")], [
          html.h1([], [element.text("Edit Recipe: " <> recipe.name)]),
          recipe_form(Some(recipe)),
        ]),
      ]

      wisp.html_response(render_page("Edit " <> recipe.name <> " - Meal Planner", content), 200)
    }
    Error(_) -> not_found_page()
  }
}

fn recipe_form(recipe: Option(types.Recipe)) -> element.Element(msg) {
  let #(name_value, category_value, protein_value, fat_value, carbs_value, servings_value, action, method) = case recipe {
    Some(r) -> #(
      r.name,
      r.category,
      float_to_string(r.macros.protein),
      float_to_string(r.macros.fat),
      float_to_string(r.macros.carbs),
      int_to_string(r.servings),
      "/api/recipes/" <> r.id,
      "PUT"
    )
    None -> #("", "main", "0", "0", "0", "1", "/api/recipes", "POST")
  }

  html.form(
    [
      attribute.method(method),
      attribute.action(action),
      attribute.class("recipe-form"),
    ],
    [
      html.div([attribute.class("form-group")], [
        html.label([attribute.attribute("for", "name")], [
          element.text("Recipe Name"),
        ]),
        html.input([
          attribute.type_("text"),
          attribute.id("name"),
          attribute.name("name"),
          attribute.value(name_value),
          attribute.required(True),
          attribute.placeholder("e.g., Chicken and Rice"),
        ]),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([attribute.attribute("for", "category")], [
          element.text("Category"),
        ]),
        html.select(
          [
            attribute.id("category"),
            attribute.name("category"),
            attribute.required(True),
          ],
          [
            html.option([attribute.value("main"), category_selected("main", category_value)], "Main Dish"),
            html.option([attribute.value("side"), category_selected("side", category_value)], "Side Dish"),
            html.option([attribute.value("dessert"), category_selected("dessert", category_value)], "Dessert"),
            html.option([attribute.value("drink"), category_selected("drink", category_value)], "Drink"),
          ],
        ),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([attribute.attribute("for", "protein")], [
          element.text("Protein (g)"),
        ]),
        html.input([
          attribute.type_("number"),
          attribute.id("protein"),
          attribute.name("protein"),
          attribute.attribute("min", "0"),
          attribute.attribute("step", "0.1"),
          attribute.value(protein_value),
          attribute.required(True),
        ]),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([attribute.attribute("for", "fat")], [
          element.text("Fat (g)"),
        ]),
        html.input([
          attribute.type_("number"),
          attribute.id("fat"),
          attribute.name("fat"),
          attribute.attribute("min", "0"),
          attribute.attribute("step", "0.1"),
          attribute.value(fat_value),
          attribute.required(True),
        ]),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([attribute.attribute("for", "carbs")], [
          element.text("Carbs (g)"),
        ]),
        html.input([
          attribute.type_("number"),
          attribute.id("carbs"),
          attribute.name("carbs"),
          attribute.attribute("min", "0"),
          attribute.attribute("step", "0.1"),
          attribute.value(carbs_value),
          attribute.required(True),
        ]),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([attribute.attribute("for", "servings")], [
          element.text("Servings"),
        ]),
        html.input([
          attribute.type_("number"),
          attribute.id("servings"),
          attribute.name("servings"),
          attribute.attribute("min", "1"),
          attribute.attribute("step", "1"),
          attribute.value(servings_value),
          attribute.required(True),
        ]),
      ]),
      html.div([attribute.class("form-actions")], [
        html.button([attribute.type_("submit"), attribute.class("btn btn-primary")], [
          element.text(case recipe {
            Some(_) -> "Update Recipe"
            None -> "Create Recipe"
          }),
        ]),
        html.a([attribute.href(case recipe {
          Some(r) -> "/recipes/" <> r.id
          None -> "/recipes"
        }), attribute.class("btn btn-secondary")], [
          element.text("Cancel"),
        ]),
      ]),
    ],
  )
}

fn category_selected(value: String, current: String) -> attribute.Attribute(msg) {
  case value == current {
    True -> attribute.selected(True)
    False -> attribute.class("")
  }
}

fn page_header(title: String, back_href: String) -> element.Element(msg) {
  html.header([attribute.class("page-header")], [
    html.a([attribute.href(back_href), attribute.class("back-link")], [
      element.text("←"),
    ]),
    html.h1([], [element.text(title)]),
  ])
}

fn render_page(title: String, content: List(element.Element(msg))) -> String {
  let body =
    html.html([attribute.attribute("lang", "en")], [
      html.head([], [
        html.meta([attribute.attribute("charset", "UTF-8")]),
        html.meta([
          attribute.name("viewport"),
          attribute.attribute(
            "content",
            "width=device-width, initial-scale=1.0",
          ),
        ]),
        html.title([], title),
        html.link([
          attribute.rel("stylesheet"),
          attribute.href("/static/styles.css"),
        ]),
      ]),
      html.body([], [
        html.div([attribute.class("container")], content),
      ]),
    ])

  "<!DOCTYPE html>" <> element.to_string(body)
}

// ============================================================================
// API Routes
// ============================================================================

fn handle_api(req: wisp.Request, path: List(String)) -> wisp.Response {
  case path {
    ["recipes"] -> api_recipes_handler(req)
    ["recipes", id] -> api_recipe_handler(req, id)
    ["profile"] -> api_profile(req)
    ["logs"] -> api_logs_create(req)
    ["logs", "recent"] -> api_logs_recent(req)
    ["logs", "entry", id] -> api_log_entry(req, id)
    ["logs", date] -> api_logs(req, date)
    ["foods", "search"] -> api_foods_search(req)
    _ -> wisp.not_found()
  }
}

/// GET /api/recipes - List all recipes
/// POST /api/recipes - Create new recipe
fn api_recipes_handler(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> api_recipes_list(req)
    http.Post -> api_recipes_create(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// GET /api/recipes/:id - Get single recipe
/// PUT /api/recipes/:id - Update recipe
/// DELETE /api/recipes/:id - Delete recipe
fn api_recipe_handler(req: wisp.Request, id: String) -> wisp.Response {
  case req.method {
    http.Get -> api_recipe_get(req, id)
    http.Put -> api_recipe_update(req, id)
    http.Delete -> api_recipe_delete(req, id)
    _ -> wisp.method_not_allowed([http.Get, http.Put, http.Delete])
  }
}

/// GET /api/recipes - List all recipes from database
fn api_recipes_list(_req: wisp.Request) -> wisp.Response {
  use conn <- storage.with_connection(storage.db_path)

  case storage.get_all_recipes(conn) {
    Ok(recipes) -> {
      let json_data = json.array(recipes, types.recipe_to_json)
      wisp.json_response(json.to_string(json_data), 200)
    }
    Error(storage.DatabaseError(msg)) -> {
      let err = json.object([#("error", json.string(msg))])
      wisp.json_response(json.to_string(err), 500)
    }
    Error(storage.NotFound) -> {
      let empty = json.array([], fn(x) { x })
      wisp.json_response(json.to_string(empty), 200)
    }
  }
}

/// POST /api/recipes - Create new recipe
fn api_recipes_create(req: wisp.Request) -> wisp.Response {
  use conn <- storage.with_connection(storage.db_path)
  use json_body <- wisp.require_json(req)

  case decode.run(json_body, types.recipe_decoder()) {
    Ok(recipe) -> {
      case storage.save_recipe(conn, recipe) {
        Ok(_) -> {
          let json_data = types.recipe_to_json(recipe)
          wisp.json_response(json.to_string(json_data), 201)
        }
        Error(storage.DatabaseError(msg)) -> {
          let err = json.object([#("error", json.string(msg))])
          wisp.json_response(json.to_string(err), 500)
        }
        Error(storage.NotFound) -> {
          let err = json.object([#("error", json.string("Not found"))])
          wisp.json_response(json.to_string(err), 404)
        }
      }
    }
    Error(_) -> {
      let err = json.object([#("error", json.string("Invalid recipe data"))])
      wisp.json_response(json.to_string(err), 400)
    }
  }
}

/// GET /api/recipes/:id - Get single recipe
fn api_recipe_get(_req: wisp.Request, id: String) -> wisp.Response {
  use conn <- storage.with_connection(storage.db_path)

  case storage.get_recipe_by_id(conn, id) {
    Ok(recipe) -> {
      let json_data = types.recipe_to_json(recipe)
      wisp.json_response(json.to_string(json_data), 200)
    }
    Error(storage.NotFound) -> {
      let err = json.object([#("error", json.string("Recipe not found"))])
      wisp.json_response(json.to_string(err), 404)
    }
    Error(storage.DatabaseError(msg)) -> {
      let err = json.object([#("error", json.string(msg))])
      wisp.json_response(json.to_string(err), 500)
    }
  }
}

/// PUT /api/recipes/:id - Update recipe
fn api_recipe_update(req: wisp.Request, id: String) -> wisp.Response {
  use conn <- storage.with_connection(storage.db_path)
  use json_body <- wisp.require_json(req)

  // First check if recipe exists
  case storage.get_recipe_by_id(conn, id) {
    Error(storage.NotFound) -> {
      let err = json.object([#("error", json.string("Recipe not found"))])
      wisp.json_response(json.to_string(err), 404)
    }
    Error(storage.DatabaseError(msg)) -> {
      let err = json.object([#("error", json.string(msg))])
      wisp.json_response(json.to_string(err), 500)
    }
    Ok(_existing_recipe) -> {
      // Decode the updated recipe
      case decode.run(json_body, types.recipe_decoder()) {
        Ok(updated_recipe) -> {
          // Ensure the ID matches the URL parameter
          let recipe_to_save =
            types.Recipe(..updated_recipe, id: id)

          case storage.save_recipe(conn, recipe_to_save) {
            Ok(_) -> {
              let json_data = types.recipe_to_json(recipe_to_save)
              wisp.json_response(json.to_string(json_data), 200)
            }
            Error(storage.DatabaseError(msg)) -> {
              let err = json.object([#("error", json.string(msg))])
              wisp.json_response(json.to_string(err), 500)
            }
            Error(storage.NotFound) -> {
              let err = json.object([#("error", json.string("Not found"))])
              wisp.json_response(json.to_string(err), 404)
            }
          }
        }
        Error(_) -> {
          let err =
            json.object([#("error", json.string("Invalid recipe data"))])
          wisp.json_response(json.to_string(err), 400)
        }
      }
    }
  }
}

/// DELETE /api/recipes/:id - Delete recipe
fn api_recipe_delete(_req: wisp.Request, id: String) -> wisp.Response {
  use conn <- storage.with_connection(storage.db_path)

  // First check if recipe exists
  case storage.get_recipe_by_id(conn, id) {
    Error(storage.NotFound) -> {
      let err = json.object([#("error", json.string("Recipe not found"))])
      wisp.json_response(json.to_string(err), 404)
    }
    Error(storage.DatabaseError(msg)) -> {
      let err = json.object([#("error", json.string(msg))])
      wisp.json_response(json.to_string(err), 500)
    }
    Ok(_recipe) -> {
      case storage.delete_recipe(conn, id) {
        Ok(_) -> {
          let success =
            json.object([#("message", json.string("Recipe deleted successfully"))])
          wisp.json_response(json.to_string(success), 200)
        }
        Error(storage.DatabaseError(msg)) -> {
          let err = json.object([#("error", json.string(msg))])
          wisp.json_response(json.to_string(err), 500)
        }
        Error(storage.NotFound) -> {
          let err = json.object([#("error", json.string("Recipe not found"))])
          wisp.json_response(json.to_string(err), 404)
        }
      }
    }
  }
}

fn api_profile(_req: wisp.Request) -> wisp.Response {
  let profile =
    types.UserProfile(
      id: "user-1",
      bodyweight: 180.0,
      activity_level: types.Moderate,
      goal: types.Maintain,
      meals_per_day: 3,
    )

  let json_data = types.user_profile_to_json(profile)
  wisp.json_response(json.to_string(json_data), 200)
}

fn api_logs(_req: wisp.Request, date: String) -> wisp.Response {
  use conn <- storage.with_connection(storage.db_path)

  let log = case storage.get_daily_log(conn, date) {
    Ok(l) -> l
    Error(_) ->
      types.DailyLog(
        date: date,
        entries: [],
        total_macros: types.macros_zero(),
        total_micronutrients: types.micronutrients_zero(),
      )
  }

  let json_data = types.daily_log_to_json(log)
  wisp.json_response(json.to_string(json_data), 200)
}

/// POST /api/logs - Create a new food log entry
fn api_logs_create(req: wisp.Request) -> wisp.Response {
  use conn <- storage.with_connection(storage.db_path)

  // Get query params for form submission
  case wisp.get_query(req) {
    [
      #("recipe_id", recipe_id),
      #("servings", servings_str),
      #("meal_type", meal_type_str),
      ..
    ] -> {
      let servings = case float.parse(servings_str) {
        Ok(s) -> s
        Error(_) -> 1.0
      }
      let meal_type = string_to_meal_type(meal_type_str)
      let today = today_date_string()

      // Get recipe to calculate macros
      case storage.get_recipe_by_id(conn, recipe_id) {
        Error(_) -> wisp.not_found()
        Ok(recipe) -> {
          let scaled_macros = types.macros_scale(recipe.macros, servings)
          let entry =
            types.FoodLogEntry(
              id: generate_entry_id(),
              recipe_id: recipe.id,
              recipe_name: recipe.name,
              servings: servings,
              macros: scaled_macros,
              micronutrients: None,
              meal_type: meal_type,
              logged_at: current_timestamp(),
            )

          case storage.save_food_log_entry(conn, today, entry) {
            Ok(_) -> wisp.redirect("/dashboard")
            Error(_) -> {
              let err =
                json.object([#("error", json.string("Failed to save entry"))])
              wisp.json_response(json.to_string(err), 500)
            }
          }
        }
      }
    }
    _ -> {
      let err =
        json.object([#("error", json.string("Missing required parameters"))])
      wisp.json_response(json.to_string(err), 400)
    }
  }
}

/// GET /api/logs/recent - Get recently logged meals
fn api_logs_recent(_req: wisp.Request) -> wisp.Response {
  use conn <- storage.with_connection(storage.db_path)

  case storage.get_recent_meals(conn, 5) {
    Ok(entries) -> {
      let json_data = json.array(entries, types.food_log_entry_to_json)
      wisp.json_response(json.to_string(json_data), 200)
    }
    Error(_) -> {
      let empty = json.array([], fn(x) { x })
      wisp.json_response(json.to_string(empty), 200)
    }
  }
}

/// GET/DELETE /api/logs/entry/:id - Manage a log entry
fn api_log_entry(req: wisp.Request, entry_id: String) -> wisp.Response {
  use conn <- storage.with_connection(storage.db_path)

  // Check for delete action in query params
  case wisp.get_query(req) {
    [#("action", "delete"), ..] -> {
      case storage.delete_food_log_entry(conn, entry_id) {
        Ok(_) -> wisp.redirect("/dashboard")
        Error(_) -> wisp.not_found()
      }
    }
    _ -> wisp.not_found()
  }
}

/// GET /api/foods/search?q=query - Search USDA foods
fn api_foods_search(req: wisp.Request) -> wisp.Response {
  // Delegate to USDA API module
  usda_api.handle_search(req)
}

// ============================================================================
// Static Files
// ============================================================================

fn serve_static(req: wisp.Request, _path: List(String)) -> wisp.Response {
  let static_dir = case wisp.priv_directory("server") {
    Ok(dir) -> dir <> "/static"
    Error(_) -> "./priv/static"
  }

  wisp.serve_static(req, under: "/static", from: static_dir, next: fn() {
    wisp.not_found()
  })
}

// ============================================================================
// Sample Data
// ============================================================================

fn sample_recipes() -> List(types.Recipe) {
  [
    types.Recipe(
      id: "chicken-rice",
      name: "Chicken and Rice",
      ingredients: [
        types.Ingredient(name: "Chicken breast", quantity: "8 oz"),
        types.Ingredient(name: "White rice", quantity: "1 cup"),
        types.Ingredient(name: "Olive oil", quantity: "1 tbsp"),
      ],
      instructions: ["Cook rice", "Grill chicken", "Serve together"],
      macros: types.Macros(protein: 45.0, fat: 8.0, carbs: 45.0),
      servings: 1,
      category: "chicken",
      fodmap_level: types.Low,
      vertical_compliant: True,
    ),
    types.Recipe(
      id: "beef-potatoes",
      name: "Beef and Potatoes",
      ingredients: [
        types.Ingredient(name: "Ground beef", quantity: "6 oz"),
        types.Ingredient(name: "Potatoes", quantity: "200g"),
        types.Ingredient(name: "Butter", quantity: "1 tbsp"),
      ],
      instructions: ["Boil potatoes", "Cook beef", "Combine and serve"],
      macros: types.Macros(protein: 40.0, fat: 20.0, carbs: 35.0),
      servings: 1,
      category: "beef",
      fodmap_level: types.Low,
      vertical_compliant: True,
    ),
    types.Recipe(
      id: "salmon-veggies",
      name: "Salmon with Vegetables",
      ingredients: [
        types.Ingredient(name: "Salmon fillet", quantity: "6 oz"),
        types.Ingredient(name: "Broccoli", quantity: "1 cup"),
        types.Ingredient(name: "Olive oil", quantity: "1 tbsp"),
      ],
      instructions: ["Roast salmon", "Steam broccoli", "Serve together"],
      macros: types.Macros(protein: 35.0, fat: 18.0, carbs: 8.0),
      servings: 1,
      category: "seafood",
      fodmap_level: types.Low,
      vertical_compliant: True,
    ),
  ]
}

fn sample_profile() -> types.UserProfile {
  types.UserProfile(
    id: "user-1",
    bodyweight: 180.0,
    activity_level: types.Moderate,
    goal: types.Maintain,
    meals_per_day: 3,
  )
}

// ============================================================================
// Helpers
// ============================================================================

fn float_to_string(f: Float) -> String {
  // Round to whole number for clean display
  let rounded = float.round(f)
  int.to_string(rounded)
}

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(i: Int) -> String

/// Get today's date as a string in YYYY-MM-DD format
fn today_date_string() -> String {
  // Use Erlang calendar for date
  let #(#(year, month, day), _time) = erlang_localtime()
  int.to_string(year) <> "-" <> pad_two(month) <> "-" <> pad_two(day)
}

fn pad_two(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}

@external(erlang, "calendar", "local_time")
fn erlang_localtime() -> #(#(Int, Int, Int), #(Int, Int, Int))

/// Generate a unique entry ID
fn generate_entry_id() -> String {
  "entry-" <> wisp.random_string(12)
}

/// Get current timestamp as ISO8601 string
fn current_timestamp() -> String {
  let #(#(year, month, day), #(hour, min, sec)) = erlang_localtime()
  int.to_string(year)
  <> "-"
  <> pad_two(month)
  <> "-"
  <> pad_two(day)
  <> "T"
  <> pad_two(hour)
  <> ":"
  <> pad_two(min)
  <> ":"
  <> pad_two(sec)
  <> "Z"
}

/// Convert string to meal type
fn string_to_meal_type(s: String) -> types.MealType {
  case s {
    "breakfast" -> types.Breakfast
    "lunch" -> types.Lunch
    "dinner" -> types.Dinner
    "snack" -> types.Snack
    _ -> types.Lunch
  }
}
