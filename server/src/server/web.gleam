//// Wisp web server for the meal planner application

import gleam/erlang/process
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
    
    // API routes
    ["api", ..rest] -> handle_api(req, rest)
    
    // SSR pages
    ["recipes"] -> recipes_page()
    ["recipes", id] -> recipe_detail_page(id)
    
    // SPA fallback - serve the app shell
    _ -> app_shell()
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
  let html = render_page("Meal Planner", [
    html.h1([], [element.text("Welcome to Meal Planner")]),
    html.p([], [element.text("A nutrition tracking application built with Gleam and Lustre.")]),
    html.ul([], [
      html.li([], [html.a([attribute.href("/recipes")], [element.text("Browse Recipes")])]),
      html.li([], [html.a([attribute.href("/api/profile")], [element.text("View Profile (API)")])]),
    ]),
  ])
  
  wisp.html_response(html, 200)
}

fn app_shell() -> wisp.Response {
  let html = "<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>Meal Planner</title>
  <link rel=\"stylesheet\" href=\"/static/styles.css\">
</head>
<body>
  <div id=\"app\">Loading...</div>
  <script type=\"module\" src=\"/static/app.js\"></script>
</body>
</html>"
  
  wisp.html_response(html, 200)
}

fn recipes_page() -> wisp.Response {
  // TODO: Load recipes from storage
  let recipes = sample_recipes()
  
  let content = [
    html.h1([], [element.text("Recipes")]),
    html.ul([attribute.class("recipe-list")],
      list.map(recipes, fn(r) {
        html.li([], [
          html.a([attribute.href("/recipes/" <> r.id)], [
            element.text(r.name),
          ]),
          html.span([attribute.class("category")], [
            element.text(" - " <> r.category),
          ]),
        ])
      })
    ),
  ]
  
  let html = render_page("Recipes - Meal Planner", content)
  wisp.html_response(html, 200)
}

fn recipe_detail_page(id: String) -> wisp.Response {
  let recipes = sample_recipes()
  
  case list.find(recipes, fn(r) { r.id == id }) {
    Ok(recipe) -> {
      let content = [
        html.h1([], [element.text(recipe.name)]),
        html.p([], [element.text("Category: " <> recipe.category)]),
        html.h2([], [element.text("Nutrition per serving")]),
        html.ul([], [
          html.li([], [element.text("Protein: " <> float_to_string(recipe.macros.protein) <> "g")]),
          html.li([], [element.text("Fat: " <> float_to_string(recipe.macros.fat) <> "g")]),
          html.li([], [element.text("Carbs: " <> float_to_string(recipe.macros.carbs) <> "g")]),
          html.li([], [element.text("Calories: " <> float_to_string(types.macros_calories(recipe.macros)))]),
        ]),
        html.a([attribute.href("/recipes")], [element.text("Back to recipes")]),
      ]
      
      let html = render_page(recipe.name <> " - Meal Planner", content)
      wisp.html_response(html, 200)
    }
    Error(_) -> wisp.not_found()
  }
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

// ============================================================================
// Helpers
// ============================================================================

@external(erlang, "erlang", "float_to_binary")
fn float_to_string(f: Float) -> String
