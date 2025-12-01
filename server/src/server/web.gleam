//// Wisp web server for the meal planner application

import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html
import mist
import wisp
import wisp/wisp_mist

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
    ["recipes", id] -> recipe_detail_page(id)
    ["dashboard"] -> dashboard_page()
    ["profile"] -> profile_page()

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
        html.a(
          [attribute.href("/recipes"), attribute.class("back-link")],
          [element.text("← Back to recipes")],
        ),
        html.div([attribute.class("recipe-detail")], [
          html.h1([], [element.text(recipe.name)]),
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
              macro_stat_block(
                "Fat",
                float_to_string(recipe.macros.fat) <> "g",
              ),
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

fn dashboard_page() -> wisp.Response {
  let profile = sample_profile()
  let daily_log = sample_daily_log()
  let targets = types.daily_macro_targets(profile)
  let current = daily_log.total_macros

  let content = [
    page_header("Dashboard", "/"),
    html.div([attribute.class("dashboard")], [
      // Date
      html.p([attribute.class("date")], [element.text(daily_log.date)]),
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
          html.dd([], [element.text(float_to_string(profile.bodyweight) <> " lbs")]),
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

fn page_header(title: String, back_href: String) -> element.Element(msg) {
  html.header([attribute.class("page-header")], [
    html.a([attribute.href(back_href), attribute.class("back-link")], [
      element.text("←"),
    ]),
    html.h1([], [element.text(title)]),
  ])
}

fn render_page(title: String, content: List(element.Element(msg))) -> String {
  let body = html.html([attribute.attribute("lang", "en")], [
    html.head([], [
      html.meta([attribute.attribute("charset", "UTF-8")]),
      html.meta([attribute.name("viewport"), attribute.attribute("content", "width=device-width, initial-scale=1.0")]),
      html.title([], title),
      html.link([attribute.rel("stylesheet"), attribute.href("/static/styles.css")]),
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
    ["recipes"] -> api_recipes(req)
    ["recipes", id] -> api_recipe(req, id)
    ["profile"] -> api_profile(req)
    ["logs", date] -> api_logs(req, date)
    _ -> wisp.not_found()
  }
}

fn api_recipes(_req: wisp.Request) -> wisp.Response {
  let recipes = sample_recipes()
  let json_data = json.array(recipes, types.recipe_to_json)
  
  wisp.json_response(json.to_string(json_data), 200)
}

fn api_recipe(_req: wisp.Request, id: String) -> wisp.Response {
  let recipes = sample_recipes()
  
  case list.find(recipes, fn(r) { r.id == id }) {
    Ok(recipe) -> {
      let json_data = types.recipe_to_json(recipe)
      wisp.json_response(json.to_string(json_data), 200)
    }
    Error(_) -> wisp.not_found()
  }
}

fn api_profile(_req: wisp.Request) -> wisp.Response {
  let profile = types.UserProfile(
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
  let log = types.DailyLog(
    date: date,
    entries: [],
    total_macros: types.macros_zero(),
  )
  
  let json_data = types.daily_log_to_json(log)
  wisp.json_response(json.to_string(json_data), 200)
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

fn sample_daily_log() -> types.DailyLog {
  types.DailyLog(
    date: "2024-01-15",
    entries: [],
    total_macros: types.Macros(protein: 120.0, fat: 65.0, carbs: 180.0),
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
