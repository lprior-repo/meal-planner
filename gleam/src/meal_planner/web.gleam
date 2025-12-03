//// Wisp web server for the meal planner application
//// Server-side rendered pages with Lustre

import gleam/dynamic/decode
import gleam/erlang/process
import gleam/float
import gleam/http
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/storage
import meal_planner/web_helpers
import shared/types.{
  type DailyLog, type FoodLogEntry, type Macros, type MealType, type Recipe,
  type UserProfile, Active, Breakfast, DailyLog, Dinner, FoodLogEntry, Gain,
  Lose, Lunch, Macros, Maintain, Moderate, Sedentary, Snack, UserProfile,
}
import mist
import pog
import wisp
import wisp/wisp_mist

// ============================================================================
// Context (passed to handlers)
// ============================================================================

/// Web context holding database connection
pub type Context {
  Context(db: pog.Connection)
}

// ============================================================================
// Server Entry
// ============================================================================

/// Main entry point - starts server on port 8080
pub fn main() {
  start(8080)
}

/// Start the web server on the specified port
pub fn start(port: Int) {
  wisp.configure_logger()

  // Initialize database connection pool
  let db_config = storage.default_config()
  let assert Ok(db) = storage.start_pool(db_config)

  let secret_key_base = wisp.random_string(64)
  let ctx = Context(db: db)

  io.println("Starting server on port " <> int.to_string(port))

  let handler = fn(req) { handle_request(req, ctx) }

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(port)
    |> mist.start

  process.sleep_forever()
}

// ============================================================================
// Request Handler
// ============================================================================

fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use req <- middleware(req)

  case wisp.path_segments(req) {
    // Home page
    [] -> home_page()

    // Static assets
    ["static", ..rest] -> serve_static(req, rest)

    // API routes
    ["api", ..rest] -> handle_api(req, rest, ctx)

    // SSR pages
    ["recipes"] -> recipes_page(ctx)
    ["recipes", "new"] -> new_recipe_page()
    ["recipes", id, "edit"] -> edit_recipe_page(id, ctx)
    ["recipes", id] -> recipe_detail_page(id, ctx)
    ["dashboard"] -> dashboard_page(req, ctx)
    ["profile"] -> profile_page(ctx)
    ["foods"] -> foods_page(req, ctx)
    ["foods", id] -> food_detail_page(id, ctx)
    ["log"] -> log_meal_page(ctx)
    ["log", recipe_id] -> log_meal_form(recipe_id, ctx)

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
      html.a([attribute.href("/foods"), attribute.class("nav-card")], [
        html.span([attribute.class("nav-icon")], [element.text("🔍")]),
        html.span([], [element.text("Food Search")]),
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

fn recipes_page(ctx: Context) -> wisp.Response {
  let recipes = load_recipes(ctx)

  let content = [
    html.div([attribute.class("page-header")], [
      html.h1([], [element.text("Recipes")]),
      html.p([attribute.class("subtitle")], [
        element.text("Browse our collection of healthy meals"),
      ]),
      html.a(
        [attribute.href("/recipes/new"), attribute.class("btn btn-primary")],
        [element.text("+ New Recipe")],
      ),
    ]),
    html.div([attribute.class("recipe-grid")], list.map(recipes, recipe_card)),
  ]

  wisp.html_response(render_page("Recipes - Meal Planner", content), 200)
}

fn recipe_card(recipe: Recipe) -> element.Element(msg) {
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

fn recipe_detail_page(id: String, ctx: Context) -> wisp.Response {
  case load_recipe_by_id(ctx, id) {
    Ok(recipe) -> {
      let content = [
        html.a([attribute.href("/recipes"), attribute.class("back-link")], [
          element.text("← Back to recipes"),
        ]),
        html.div([attribute.class("recipe-detail")], [
          html.div([attribute.class("recipe-detail-header")], [
            html.h1([], [element.text(recipe.name)]),
            html.div([attribute.class("recipe-actions")], [
              html.a(
                [
                  attribute.href("/recipes/" <> id <> "/edit"),
                  attribute.class("btn btn-secondary"),
                ],
                [element.text("Edit")],
              ),
              html.form(
                [
                  attribute.method("POST"),
                  attribute.action("/api/recipes/" <> id),
                  attribute.attribute(
                    "onsubmit",
                    "return confirm('Delete this recipe?')",
                  ),
                  attribute.style("display", "inline"),
                ],
                [
                  html.input([
                    attribute.type_("hidden"),
                    attribute.name("_method"),
                    attribute.value("DELETE"),
                  ]),
                  html.button(
                    [attribute.type_("submit"), attribute.class("btn btn-danger")],
                    [element.text("Delete")],
                  ),
                ],
              ),
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

      wisp.html_response(
        render_page(recipe.name <> " - Meal Planner", content),
        200,
      )
    }
    Error(_) -> not_found_page()
  }
}

fn macro_stat_block(label: String, value: String) -> element.Element(msg) {
  html.div([attribute.class("macro-stat")], [
    html.span([attribute.class("macro-value")], [element.text(value)]),
    html.span([attribute.class("macro-name")], [element.text(label)]),
  ])
}

fn dashboard_page(req: wisp.Request, ctx: Context) -> wisp.Response {
  let profile = load_profile(ctx)
  let targets = types.daily_macro_targets(profile)

  // Get date from query parameter or use today's date
  let date = case uri.parse_query(req.query |> option.unwrap("")) {
    Ok(params) -> {
      case list.find(params, fn(p) { p.0 == "date" }) {
        Ok(#(_, d)) -> d
        Error(_) -> get_today_date()
      }
    }
    Error(_) -> get_today_date()
  }

  // Load actual daily log from storage
  let daily_log = load_daily_log(ctx, date)
  // Convert shared_types.Macros to meal_planner/types.Macros
  let current =
    Macros(
      protein: daily_log.total_macros.protein,
      fat: daily_log.total_macros.fat,
      carbs: daily_log.total_macros.carbs,
    )

  let content = [
    page_header("Dashboard", "/"),
    html.div([attribute.class("dashboard")], [
      // Date
      html.p([attribute.class("date")], [element.text(date)]),
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
      // Quick actions
      html.div([attribute.class("quick-actions")], [
        html.a([attribute.href("/recipes"), attribute.class("btn")], [
          element.text("Add Meal"),
        ]),
      ]),
    ]),
  ]

  wisp.html_response(render_page("Dashboard - Meal Planner", content), 200)
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

fn profile_page(ctx: Context) -> wisp.Response {
  let profile = load_profile(ctx)
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
          html.dd([], [element.text(activity_level_to_string(profile))]),
          html.dt([], [element.text("Goal")]),
          html.dd([], [element.text(goal_to_string(profile))]),
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

fn page_header(title: String, back_href: String) -> element.Element(msg) {
  html.header([attribute.class("page-header")], [
    html.a([attribute.href(back_href), attribute.class("back-link")], [
      element.text("←"),
    ]),
    html.h1([], [element.text(title)]),
  ])
}

fn foods_page(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Get search query from URL params
  let query = case uri.parse_query(req.query |> option.unwrap("")) {
    Ok(params) -> {
      case list.find(params, fn(p) { p.0 == "q" }) {
        Ok(#(_, q)) -> Some(q)
        Error(_) -> None
      }
    }
    Error(_) -> None
  }

  let foods = case query {
    Some(q) if q != "" -> search_foods(ctx, q, 50)
    _ -> []
  }

  let food_count = get_foods_count(ctx)

  let content = [
    html.div([attribute.class("page-header")], [
      html.h1([], [element.text("Food Search")]),
      html.p([attribute.class("subtitle")], [
        element.text("Search " <> int_to_string(food_count) <> " USDA foods"),
      ]),
    ]),
    html.form([attribute.action("/foods"), attribute.method("get")], [
      html.div([attribute.class("search-box")], [
        html.input([
          attribute.type_("search"),
          attribute.name("q"),
          attribute.placeholder("Search foods (e.g., chicken, apple, rice)"),
          attribute.value(query |> option.unwrap("")),
          attribute.class("search-input"),
        ]),
        html.button(
          [attribute.type_("submit"), attribute.class("btn btn-primary")],
          [
            element.text("Search"),
          ],
        ),
      ]),
    ]),
    case query {
      Some(q) if q != "" -> {
        case foods {
          [] ->
            html.p([attribute.class("empty-state")], [
              element.text("No foods found matching \"" <> q <> "\""),
            ])
          _ ->
            html.div([attribute.class("food-list")], list.map(foods, food_row))
        }
      }
      _ ->
        html.p([attribute.class("empty-state")], [
          element.text("Enter a search term to find foods"),
        ])
    },
  ]

  wisp.html_response(render_page("Food Search - Meal Planner", content), 200)
}

fn food_row(food: storage.UsdaFood) -> element.Element(msg) {
  html.a(
    [
      attribute.class("food-item"),
      attribute.href("/foods/" <> int_to_string(food.fdc_id)),
    ],
    [
      html.div([attribute.class("food-info")], [
        html.span([attribute.class("food-name")], [
          element.text(food.description),
        ]),
        html.span([attribute.class("food-type")], [element.text(food.data_type)]),
      ]),
    ],
  )
}

fn food_detail_page(id: String, ctx: Context) -> wisp.Response {
  case int.parse(id) {
    Error(_) -> not_found_page()
    Ok(fdc_id) -> {
      case load_food_by_id(ctx, fdc_id) {
        Error(_) -> not_found_page()
        Ok(food) -> {
          let nutrients = load_food_nutrients(ctx, fdc_id)
          // Find key macros
          let protein = find_nutrient(nutrients, "Protein")
          let fat = find_nutrient(nutrients, "Total lipid (fat)")
          let carbs = find_nutrient(nutrients, "Carbohydrate, by difference")
          let calories = find_nutrient(nutrients, "Energy")

          let content = [
            html.a([attribute.href("/foods"), attribute.class("back-link")], [
              element.text("← Back to search"),
            ]),
            html.div([attribute.class("food-detail")], [
              html.h1([], [element.text(food.description)]),
              html.p([attribute.class("meta")], [
                element.text("Type: " <> food.data_type),
              ]),
              // Macro summary card
              html.div([attribute.class("macro-card")], [
                html.h2([], [element.text("Nutrition per 100g")]),
                html.div([attribute.class("macro-grid")], [
                  macro_stat_block("Protein", format_nutrient(protein)),
                  macro_stat_block("Fat", format_nutrient(fat)),
                  macro_stat_block("Carbs", format_nutrient(carbs)),
                  macro_stat_block("Calories", format_calories(calories)),
                ]),
              ]),
              // All nutrients
              html.div([attribute.class("nutrients-list")], [
                html.h2([], [element.text("All Nutrients")]),
                html.table([attribute.class("nutrients-table")], [
                  html.thead([], [
                    html.tr([], [
                      html.th([], [element.text("Nutrient")]),
                      html.th([], [element.text("Amount")]),
                    ]),
                  ]),
                  html.tbody([], list.map(nutrients, nutrient_row)),
                ]),
              ]),
            ]),
          ]

          wisp.html_response(
            render_page(food.description <> " - Meal Planner", content),
            200,
          )
        }
      }
    }
  }
}

fn nutrient_row(n: storage.FoodNutrientValue) -> element.Element(msg) {
  html.tr([], [
    html.td([], [element.text(n.nutrient_name)]),
    html.td([], [element.text(float_to_string(n.amount) <> " " <> n.unit)]),
  ])
}

fn find_nutrient(
  nutrients: List(storage.FoodNutrientValue),
  name: String,
) -> option.Option(storage.FoodNutrientValue) {
  list.find(nutrients, fn(n) { n.nutrient_name == name })
  |> option.from_result
}

fn format_nutrient(n: option.Option(storage.FoodNutrientValue)) -> String {
  case n {
    Some(nutrient) -> float_to_string(nutrient.amount) <> " " <> nutrient.unit
    None -> "—"
  }
}

fn format_calories(n: option.Option(storage.FoodNutrientValue)) -> String {
  case n {
    Some(nutrient) -> float_to_string(nutrient.amount) <> " kcal"
    None -> "—"
  }
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
      html.body([], [html.div([attribute.class("container")], content)]),
    ])

  "<!DOCTYPE html>" <> element.to_string(body)
}

// ============================================================================
// API Routes
// ============================================================================

fn handle_api(
  req: wisp.Request,
  path: List(String),
  ctx: Context,
) -> wisp.Response {
  case path {
    ["recipes"] -> api_recipes(req, ctx)
    ["recipes", id] -> api_recipe(req, id, ctx)
    ["profile"] -> api_profile(req, ctx)
    ["foods"] -> api_foods(req, ctx)
    ["foods", id] -> api_food(req, id, ctx)
    _ -> wisp.not_found()
  }
}

fn api_recipes(_req: wisp.Request, ctx: Context) -> wisp.Response {
  let recipes = load_recipes(ctx)
  let json_data = json.array(recipes, recipe_to_json)

  wisp.json_response(json.to_string(json_data), 200)
}

fn api_recipe(_req: wisp.Request, id: String, ctx: Context) -> wisp.Response {
  case load_recipe_by_id(ctx, id) {
    Ok(recipe) -> {
      let json_data = recipe_to_json(recipe)
      wisp.json_response(json.to_string(json_data), 200)
    }
    Error(_) -> wisp.not_found()
  }
}

fn api_profile(_req: wisp.Request, ctx: Context) -> wisp.Response {
  let profile = load_profile(ctx)
  let json_data = profile_to_json(profile)
  wisp.json_response(json.to_string(json_data), 200)
}

fn api_foods(req: wisp.Request, ctx: Context) -> wisp.Response {
  let query = case uri.parse_query(req.query |> option.unwrap("")) {
    Ok(params) -> {
      case list.find(params, fn(p) { p.0 == "q" }) {
        Ok(#(_, q)) -> q
        Error(_) -> ""
      }
    }
    Error(_) -> ""
  }

  case query {
    "" -> {
      let json_data =
        json.object([
          #("error", json.string("Query parameter 'q' required")),
        ])
      wisp.json_response(json.to_string(json_data), 400)
    }
    q -> {
      let foods = search_foods(ctx, q, 50)
      let json_data = json.array(foods, food_to_json)
      wisp.json_response(json.to_string(json_data), 200)
    }
  }
}

fn api_food(_req: wisp.Request, id: String, ctx: Context) -> wisp.Response {
  case int.parse(id) {
    Error(_) -> wisp.not_found()
    Ok(fdc_id) -> {
      case load_food_by_id(ctx, fdc_id) {
        Error(_) -> wisp.not_found()
        Ok(food) -> {
          let nutrients = load_food_nutrients(ctx, fdc_id)
          let json_data =
            json.object([
              #("fdc_id", json.int(food.fdc_id)),
              #("description", json.string(food.description)),
              #("data_type", json.string(food.data_type)),
              #("category", json.string(food.category)),
              #(
                "nutrients",
                json.array(nutrients, fn(n) {
                  json.object([
                    #("name", json.string(n.nutrient_name)),
                    #("amount", json.float(n.amount)),
                    #("unit", json.string(n.unit)),
                  ])
                }),
              ),
            ])
          wisp.json_response(json.to_string(json_data), 200)
        }
      }
    }
  }
}

fn food_to_json(f: storage.UsdaFood) -> json.Json {
  json.object([
    #("fdc_id", json.int(f.fdc_id)),
    #("description", json.string(f.description)),
    #("data_type", json.string(f.data_type)),
    #("category", json.string(f.category)),
  ])
}

// ============================================================================
// Static Files
// ============================================================================

fn serve_static(req: wisp.Request, _path: List(String)) -> wisp.Response {
  let static_dir = case wisp.priv_directory("meal_planner") {
    Ok(dir) -> dir <> "/static"
    Error(_) -> "./priv/static"
  }

  wisp.serve_static(req, under: "/static", from: static_dir, next: fn() {
    wisp.not_found()
  })
}

// ============================================================================
// Data Loading (from storage)
// ============================================================================

fn load_recipes(ctx: Context) -> List(Recipe) {
  case storage.get_all_recipes(ctx.db) {
    Ok([]) -> sample_recipes()
    Ok(recipes) -> recipes
    Error(_) -> sample_recipes()
  }
}

fn load_recipe_by_id(ctx: Context, id: String) -> Result(Recipe, Nil) {
  case storage.get_recipe_by_id(ctx.db, id) {
    Ok(recipe) -> Ok(recipe)
    Error(_) -> {
      // Fallback to sample recipes
      list.find(sample_recipes(), fn(r) { r.id == id })
    }
  }
}

fn load_profile(ctx: Context) -> UserProfile {
  case storage.get_user_profile(ctx.db) {
    Ok(profile) -> profile
    Error(_) -> default_profile()
  }
}

fn default_profile() -> UserProfile {
  UserProfile(
    id: "default",
    bodyweight: 180.0,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: 3,
  )
}

fn search_foods(
  ctx: Context,
  query: String,
  limit: Int,
) -> List(storage.UsdaFood) {
  case storage.search_foods(ctx.db, query, limit) {
    Ok(foods) -> foods
    Error(_) -> []
  }
}

fn load_food_by_id(ctx: Context, fdc_id: Int) -> Result(storage.UsdaFood, Nil) {
  case storage.get_food_by_id(ctx.db, fdc_id) {
    Ok(food) -> Ok(food)
    Error(_) -> Error(Nil)
  }
}

fn load_food_nutrients(
  ctx: Context,
  fdc_id: Int,
) -> List(storage.FoodNutrientValue) {
  case storage.get_food_nutrients(ctx.db, fdc_id) {
    Ok(nutrients) -> nutrients
    Error(_) -> []
  }
}

fn get_foods_count(ctx: Context) -> Int {
  case storage.get_foods_count(ctx.db) {
    Ok(count) -> count
    Error(_) -> 0
  }
}

/// Load daily log for a specific date from storage
fn load_daily_log(ctx: Context, date: String) -> DailyLog {
  case storage.get_daily_log(ctx.db, date) {
    Ok(log) -> log
    Error(_) -> {
      // Return empty log if no entries found for this date
      DailyLog(
        date: date,
        entries: [],
        total_macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
      )
    }
  }
}

/// Get today's date in YYYY-MM-DD format
fn get_today_date() -> String {
  // This is a simplified version - in production you'd want to use a proper date library
  // For now, we'll use a system call to get the date
  "2025-12-01"
}

/// Sample recipes for fallback when database is empty
fn sample_recipes() -> List(Recipe) {
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
      macros: Macros(protein: 45.0, fat: 8.0, carbs: 45.0),
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
      macros: Macros(protein: 40.0, fat: 20.0, carbs: 35.0),
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
      macros: Macros(protein: 35.0, fat: 18.0, carbs: 8.0),
      servings: 1,
      category: "seafood",
      fodmap_level: types.Low,
      vertical_compliant: True,
    ),
  ]
}

// ============================================================================
// JSON Encoding
// ============================================================================

fn macros_to_json(m: Macros) -> json.Json {
  json.object([
    #("protein", json.float(m.protein)),
    #("fat", json.float(m.fat)),
    #("carbs", json.float(m.carbs)),
    #("calories", json.float(types.macros_calories(m))),
  ])
}

fn recipe_to_json(r: Recipe) -> json.Json {
  json.object([
    #("id", json.string(r.id)),
    #("name", json.string(r.name)),
    #(
      "ingredients",
      json.array(r.ingredients, fn(i) {
        json.object([
          #("name", json.string(i.name)),
          #("quantity", json.string(i.quantity)),
        ])
      }),
    ),
    #("instructions", json.array(r.instructions, json.string)),
    #("macros", macros_to_json(r.macros)),
    #("servings", json.int(r.servings)),
    #("category", json.string(r.category)),
  ])
}

fn profile_to_json(p: UserProfile) -> json.Json {
  let targets = types.daily_macro_targets(p)
  json.object([
    #("bodyweight", json.float(p.bodyweight)),
    #("activity_level", json.string(activity_level_to_string(p))),
    #("goal", json.string(goal_to_string(p))),
    #("meals_per_day", json.int(p.meals_per_day)),
    #("daily_targets", macros_to_json(targets)),
  ])
}

// ============================================================================
// Helpers
// ============================================================================

fn float_to_string(f: Float) -> String {
  let rounded = float.round(f)
  int.to_string(rounded)
}

fn activity_level_to_string(p: UserProfile) -> String {
  case p.activity_level {
    Sedentary -> "Sedentary"
    Moderate -> "Moderate"
    Active -> "Active"
  }
}

fn goal_to_string(p: UserProfile) -> String {
  case p.goal {
    Gain -> "Gain"
    Maintain -> "Maintain"
    Lose -> "Lose"
  }
}

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(i: Int) -> String
