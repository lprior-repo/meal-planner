//// Wisp web server for the meal planner application
//// Server-side rendered pages with Lustre

import gleam/dynamic/decode
import gleam/erlang/process
import gleam/float
import gleam/http
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/auto_planner
import meal_planner/auto_planner/storage as auto_storage
import meal_planner/auto_planner/types as auto_types
import meal_planner/storage
import meal_planner/storage_optimized
import meal_planner/types.{
  type DailyLog, type FoodLogEntry, type Macros, type MealType, type Recipe,
  type SearchFilters, type UserProfile, Active, Breakfast, DailyLog, Dinner,
  FoodLogEntry, Gain, Lose, Lunch, Macros, Maintain, Moderate, Sedentary, Snack,
  UserProfile,
}
import meal_planner/ui/components/food_search
import meal_planner/web/handlers/dashboard
import meal_planner/web/handlers/food_log
import meal_planner/web/handlers/profile
import meal_planner/web/handlers/recipe
import meal_planner/web/handlers/search
import mist
import pog
import wisp
import wisp/wisp_mist

// ============================================================================
// Context (passed to handlers)
// ============================================================================

/// Web context holding database connection and query cache
pub type Context {
  Context(db: pog.Connection, search_cache: storage_optimized.SearchCache)
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

  // Initialize search cache (5 min TTL, 100 entry max)
  let search_cache = storage_optimized.new_search_cache()

  let secret_key_base = wisp.random_string(64)
  let ctx = Context(db: db, search_cache: search_cache)

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
    ["dashboard"] -> dashboard.dashboard(req, ctx)
    ["profile"] -> profile_page(ctx)
    ["foods"] -> foods_page(req, ctx)
    ["foods", id] -> food_detail_page(id, ctx)
    ["log"] -> log_meal_page(ctx)
    ["log", recipe_id] -> log_meal_form(recipe_id, ctx)
    ["weekly-plan"] -> weekly_plan_page(ctx)

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

  // Get response from handler and add Vary header for compression support
  // Note: Actual compression should be handled by reverse proxy (nginx/caddy)
  // See docs/nginx-compression.conf for production setup instructions
  let response = handler(req)

  // Add Vary header to indicate responses can be compressed based on Accept-Encoding
  response
  |> wisp.set_header("vary", "Accept-Encoding")
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

fn weekly_plan_page(_ctx: Context) -> wisp.Response {
  let content = [
    html.div([attribute.class("page-header")], [
      html.h1([], [element.text("Weekly Plan")]),
      html.p([attribute.class("subtitle")], [
        element.text("Plan your meals for the week"),
      ]),
    ]),
    // 7-day grid calendar
    render_weekly_calendar(),
  ]

  wisp.html_response(render_page("Weekly Plan - Meal Planner", content), 200)
}

/// Render the 7-day weekly calendar grid
fn render_weekly_calendar() -> element.Element(Nil) {
  let days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ]

  html.div([attribute.class("weekly-calendar")], [
    html.div(
      [attribute.class("weekly-grid")],
      list.map(days, render_day_column),
    ),
  ])
}

/// Render a single day column with 3 meal slots
fn render_day_column(day_name: String) -> element.Element(Nil) {
  html.article([attribute.class("day-column")], [
    html.h3([attribute.class("day-name")], [element.text(day_name)]),
    render_meal_slot("Breakfast"),
    render_meal_slot("Lunch"),
    render_meal_slot("Dinner"),
  ])
}

/// Render a single meal slot (empty state)
fn render_meal_slot(meal_type: String) -> element.Element(Nil) {
  html.div([attribute.class("meal-slot")], [
    html.div([attribute.class("meal-type")], [element.text(meal_type)]),
    html.div([attribute.class("meal-content empty")], [
      element.text("No meals planned"),
    ]),
  ])
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

fn new_recipe_page() -> wisp.Response {
  let content = [
    html.a([attribute.href("/recipes"), attribute.class("back-link")], [
      element.text("← Back to recipes"),
    ]),
    html.div([attribute.class("page-header")], [
      html.h1([], [element.text("New Recipe")]),
    ]),
    html.form(
      [
        attribute.method("POST"),
        attribute.action("/api/recipes"),
        attribute.class("recipe-form"),
      ],
      [
        // Name input
        html.div([attribute.class("form-group")], [
          html.label([attribute.for("name")], [element.text("Recipe Name")]),
          html.input([
            attribute.type_("text"),
            attribute.name("name"),
            attribute.id("name"),
            attribute.required(True),
            attribute.placeholder("e.g., Chicken and Rice"),
            attribute.class("form-control"),
          ]),
        ]),
        // Category select
        html.div([attribute.class("form-group")], [
          html.label([attribute.for("category")], [element.text("Category")]),
          html.select(
            [
              attribute.name("category"),
              attribute.id("category"),
              attribute.required(True),
              attribute.class("form-control"),
            ],
            [
              html.option([attribute.value("chicken")], "Chicken"),
              html.option([attribute.value("beef")], "Beef"),
              html.option([attribute.value("pork")], "Pork"),
              html.option([attribute.value("seafood")], "Seafood"),
              html.option([attribute.value("vegetarian")], "Vegetarian"),
              html.option([attribute.value("other")], "Other"),
            ],
          ),
        ]),
        // Servings input
        html.div([attribute.class("form-group")], [
          html.label([attribute.for("servings")], [element.text("Servings")]),
          html.input([
            attribute.type_("number"),
            attribute.name("servings"),
            attribute.id("servings"),
            attribute.required(True),
            attribute.value("1"),
            attribute.attribute("min", "1"),
            attribute.class("form-control"),
          ]),
        ]),
        // Macros section
        html.div([attribute.class("form-section")], [
          html.h2([], [element.text("Nutrition (per serving)")]),
          html.div([attribute.class("form-row")], [
            html.div([attribute.class("form-group")], [
              html.label([attribute.for("protein")], [
                element.text("Protein (g)"),
              ]),
              html.input([
                attribute.type_("number"),
                attribute.name("protein"),
                attribute.id("protein"),
                attribute.required(True),
                attribute.attribute("step", "0.1"),
                attribute.placeholder("0"),
                attribute.class("form-control"),
              ]),
            ]),
            html.div([attribute.class("form-group")], [
              html.label([attribute.for("fat")], [element.text("Fat (g)")]),
              html.input([
                attribute.type_("number"),
                attribute.name("fat"),
                attribute.id("fat"),
                attribute.required(True),
                attribute.attribute("step", "0.1"),
                attribute.placeholder("0"),
                attribute.class("form-control"),
              ]),
            ]),
            html.div([attribute.class("form-group")], [
              html.label([attribute.for("carbs")], [element.text("Carbs (g)")]),
              html.input([
                attribute.type_("number"),
                attribute.name("carbs"),
                attribute.id("carbs"),
                attribute.required(True),
                attribute.attribute("step", "0.1"),
                attribute.placeholder("0"),
                attribute.class("form-control"),
              ]),
            ]),
          ]),
        ]),
        // FODMAP level select
        html.div([attribute.class("form-group")], [
          html.label([attribute.for("fodmap_level")], [
            element.text("FODMAP Level"),
          ]),
          html.select(
            [
              attribute.name("fodmap_level"),
              attribute.id("fodmap_level"),
              attribute.required(True),
              attribute.class("form-control"),
            ],
            [
              html.option([attribute.value("low")], "Low"),
              html.option([attribute.value("medium")], "Medium"),
              html.option([attribute.value("high")], "High"),
            ],
          ),
        ]),
        // Vertical compliant checkbox
        html.div([attribute.class("form-group")], [
          html.label([attribute.class("checkbox-label")], [
            html.input([
              attribute.type_("checkbox"),
              attribute.name("vertical_compliant"),
              attribute.id("vertical_compliant"),
              attribute.value("true"),
            ]),
            element.text(" Vertical Diet Compliant"),
          ]),
        ]),
        // Ingredients section
        html.div([attribute.class("form-section")], [
          html.h2([], [element.text("Ingredients")]),
          html.div([attribute.id("ingredients-list")], [
            ingredient_input_row(0),
          ]),
          html.button(
            [
              attribute.type_("button"),
              attribute.class("btn btn-secondary"),
              attribute.attribute("onclick", "addIngredient()"),
            ],
            [element.text("+ Add Ingredient")],
          ),
        ]),
        // Instructions section
        html.div([attribute.class("form-section")], [
          html.h2([], [element.text("Instructions")]),
          html.div([attribute.id("instructions-list")], [
            instruction_input_row(0),
          ]),
          html.button(
            [
              attribute.type_("button"),
              attribute.class("btn btn-secondary"),
              attribute.attribute("onclick", "addInstruction()"),
            ],
            [element.text("+ Add Step")],
          ),
        ]),
        // Submit button
        html.div([attribute.class("form-actions")], [
          html.button(
            [attribute.type_("submit"), attribute.class("btn btn-primary")],
            [element.text("Create Recipe")],
          ),
        ]),
        // JavaScript for dynamic fields
        html.script(
          [],
          "
let ingredientCount = 1;
let instructionCount = 1;

function addIngredient() {
  const container = document.getElementById('ingredients-list');
  const div = document.createElement('div');
  div.className = 'form-row ingredient-row';
  div.innerHTML = `
    <div class=\"form-group\">
      <input type=\"text\" name=\"ingredient_name_${ingredientCount}\"
             placeholder=\"Ingredient\" class=\"form-control\" required>
    </div>
    <div class=\"form-group\">
      <input type=\"text\" name=\"ingredient_quantity_${ingredientCount}\"
             placeholder=\"Quantity\" class=\"form-control\" required>
    </div>
    <button type=\"button\" class=\"btn btn-danger btn-small\"
            onclick=\"this.parentElement.remove()\">Remove</button>
  `;
  container.appendChild(div);
  ingredientCount++;
}

function addInstruction() {
  const container = document.getElementById('instructions-list');
  const div = document.createElement('div');
  div.className = 'form-group instruction-row';
  div.innerHTML = `
    <textarea name=\"instruction_${instructionCount}\" rows=\"2\"
              placeholder=\"Step ${instructionCount + 1}\"
              class=\"form-control\" required></textarea>
    <button type=\"button\" class=\"btn btn-danger btn-small\"
            onclick=\"this.parentElement.remove()\">Remove</button>
  `;
  container.appendChild(div);
  instructionCount++;
}
        ",
        ),
      ],
    ),
  ]

  wisp.html_response(render_page("New Recipe - Meal Planner", content), 200)
}

fn edit_recipe_page(id: String, ctx: Context) -> wisp.Response {
  case load_recipe_by_id(ctx, id) {
    Error(_) -> not_found_page()
    Ok(recipe) -> {
      let content = [
        html.a(
          [attribute.href("/recipes/" <> id), attribute.class("back-link")],
          [
            element.text("← Back to recipe"),
          ],
        ),
        html.div([attribute.class("page-header")], [
          html.h1([], [element.text("Edit Recipe")]),
        ]),
        html.form(
          [
            attribute.method("POST"),
            attribute.action("/api/recipes/" <> id),
            attribute.class("recipe-form"),
          ],
          [
            html.input([
              attribute.type_("hidden"),
              attribute.name("_method"),
              attribute.value("PUT"),
            ]),
            html.div([attribute.class("form-group")], [
              html.label([attribute.for("name")], [element.text("Recipe Name")]),
              html.input([
                attribute.type_("text"),
                attribute.name("name"),
                attribute.id("name"),
                attribute.required(True),
                attribute.value(recipe.name),
                attribute.class("form-control"),
              ]),
            ]),
            html.div([attribute.class("form-group")], [
              html.label([attribute.for("category")], [element.text("Category")]),
              html.select(
                [
                  attribute.name("category"),
                  attribute.id("category"),
                  attribute.required(True),
                  attribute.class("form-control"),
                ],
                [
                  category_option("chicken", "Chicken", recipe.category),
                  category_option("beef", "Beef", recipe.category),
                  category_option("pork", "Pork", recipe.category),
                  category_option("seafood", "Seafood", recipe.category),
                  category_option("vegetarian", "Vegetarian", recipe.category),
                  category_option("other", "Other", recipe.category),
                ],
              ),
            ]),
            html.div([attribute.class("form-group")], [
              html.label([attribute.for("servings")], [element.text("Servings")]),
              html.input([
                attribute.type_("number"),
                attribute.name("servings"),
                attribute.id("servings"),
                attribute.required(True),
                attribute.value(int_to_string(recipe.servings)),
                attribute.attribute("min", "1"),
                attribute.class("form-control"),
              ]),
            ]),
            html.div([attribute.class("form-section")], [
              html.h2([], [element.text("Nutrition (per serving)")]),
              html.div([attribute.class("form-row")], [
                html.div([attribute.class("form-group")], [
                  html.label([attribute.for("protein")], [
                    element.text("Protein (g)"),
                  ]),
                  html.input([
                    attribute.type_("number"),
                    attribute.name("protein"),
                    attribute.id("protein"),
                    attribute.required(True),
                    attribute.attribute("step", "0.1"),
                    attribute.value(float_to_string(recipe.macros.protein)),
                    attribute.class("form-control"),
                  ]),
                ]),
                html.div([attribute.class("form-group")], [
                  html.label([attribute.for("fat")], [element.text("Fat (g)")]),
                  html.input([
                    attribute.type_("number"),
                    attribute.name("fat"),
                    attribute.id("fat"),
                    attribute.required(True),
                    attribute.attribute("step", "0.1"),
                    attribute.value(float_to_string(recipe.macros.fat)),
                    attribute.class("form-control"),
                  ]),
                ]),
                html.div([attribute.class("form-group")], [
                  html.label([attribute.for("carbs")], [
                    element.text("Carbs (g)"),
                  ]),
                  html.input([
                    attribute.type_("number"),
                    attribute.name("carbs"),
                    attribute.id("carbs"),
                    attribute.required(True),
                    attribute.attribute("step", "0.1"),
                    attribute.value(float_to_string(recipe.macros.carbs)),
                    attribute.class("form-control"),
                  ]),
                ]),
              ]),
            ]),
            html.div([attribute.class("form-group")], [
              html.label([attribute.for("fodmap_level")], [
                element.text("FODMAP Level"),
              ]),
              html.select(
                [
                  attribute.name("fodmap_level"),
                  attribute.id("fodmap_level"),
                  attribute.required(True),
                  attribute.class("form-control"),
                ],
                [
                  fodmap_option("low", "Low", recipe.fodmap_level),
                  fodmap_option("medium", "Medium", recipe.fodmap_level),
                  fodmap_option("high", "High", recipe.fodmap_level),
                ],
              ),
            ]),
            html.div([attribute.class("form-group")], [
              html.label([attribute.class("checkbox-label")], [
                html.input(case recipe.vertical_compliant {
                  True -> [
                    attribute.type_("checkbox"),
                    attribute.name("vertical_compliant"),
                    attribute.id("vertical_compliant"),
                    attribute.value("true"),
                    attribute.checked(True),
                  ]
                  False -> [
                    attribute.type_("checkbox"),
                    attribute.name("vertical_compliant"),
                    attribute.id("vertical_compliant"),
                    attribute.value("true"),
                  ]
                }),
                element.text(" Vertical Diet Compliant"),
              ]),
            ]),
            html.div([attribute.class("form-section")], [
              html.h2([], [element.text("Ingredients")]),
              html.div(
                [attribute.id("ingredients-list")],
                list.index_map(recipe.ingredients, fn(ing, idx) {
                  html.div([attribute.class("form-row ingredient-row")], [
                    html.div([attribute.class("form-group")], [
                      html.input([
                        attribute.type_("text"),
                        attribute.name("ingredient_name_" <> int_to_string(idx)),
                        attribute.placeholder("Ingredient"),
                        attribute.value(ing.name),
                        attribute.class("form-control"),
                        attribute.required(True),
                      ]),
                    ]),
                    html.div([attribute.class("form-group")], [
                      html.input([
                        attribute.type_("text"),
                        attribute.name(
                          "ingredient_quantity_" <> int_to_string(idx),
                        ),
                        attribute.placeholder("Quantity"),
                        attribute.value(ing.quantity),
                        attribute.class("form-control"),
                        attribute.required(True),
                      ]),
                    ]),
                  ])
                }),
              ),
              html.button(
                [
                  attribute.type_("button"),
                  attribute.class("btn btn-secondary"),
                  attribute.attribute("onclick", "addIngredient()"),
                ],
                [element.text("+ Add Ingredient")],
              ),
            ]),
            html.div([attribute.class("form-section")], [
              html.h2([], [element.text("Instructions")]),
              html.div(
                [attribute.id("instructions-list")],
                list.index_map(recipe.instructions, fn(inst, idx) {
                  html.div([attribute.class("form-group instruction-row")], [
                    html.textarea(
                      [
                        attribute.name("instruction_" <> int_to_string(idx)),
                        attribute.attribute("rows", "2"),
                        attribute.placeholder("Step " <> int_to_string(idx + 1)),
                        attribute.class("form-control"),
                        attribute.required(True),
                      ],
                      inst,
                    ),
                  ])
                }),
              ),
              html.button(
                [
                  attribute.type_("button"),
                  attribute.class("btn btn-secondary"),
                  attribute.attribute("onclick", "addInstruction()"),
                ],
                [element.text("+ Add Step")],
              ),
            ]),
            html.div([attribute.class("form-actions")], [
              html.button(
                [attribute.type_("submit"), attribute.class("btn btn-primary")],
                [element.text("Update Recipe")],
              ),
              html.a(
                [
                  attribute.href("/recipes/" <> id),
                  attribute.class("btn btn-secondary"),
                ],
                [element.text("Cancel")],
              ),
            ]),
            html.script([], "
let ingredientCount = " <> int_to_string(
              list.fold(recipe.ingredients, 0, fn(acc, _) { acc + 1 }),
            ) <> ";
let instructionCount = " <> int_to_string(
              list.fold(recipe.instructions, 0, fn(acc, _) { acc + 1 }),
            ) <> ";

function addIngredient() {
  const container = document.getElementById('ingredients-list');
  const div = document.createElement('div');
  div.className = 'form-row ingredient-row';
  div.innerHTML = `
    <div class=\"form-group\">
      <input type=\"text\" name=\"ingredient_name_${ingredientCount}\"
             placeholder=\"Ingredient\" class=\"form-control\" required>
    </div>
    <div class=\"form-group\">
      <input type=\"text\" name=\"ingredient_quantity_${ingredientCount}\"
             placeholder=\"Quantity\" class=\"form-control\" required>
    </div>
    <button type=\"button\" class=\"btn btn-danger btn-small\"
            onclick=\"this.parentElement.remove()\">Remove</button>
  `;
  container.appendChild(div);
  ingredientCount++;
}

function addInstruction() {
  const container = document.getElementById('instructions-list');
  const div = document.createElement('div');
  div.className = 'form-group instruction-row';
  div.innerHTML = `
    <textarea name=\"instruction_${instructionCount}\" rows=\"2\"
              placeholder=\"Step ${instructionCount + 1}\"
              class=\"form-control\" required></textarea>
    <button type=\"button\" class=\"btn btn-danger btn-small\"
            onclick=\"this.parentElement.remove()\">Remove</button>
  `;
  container.appendChild(div);
  instructionCount++;
}
              "),
          ],
        ),
      ]

      wisp.html_response(
        render_page("Edit " <> recipe.name <> " - Meal Planner", content),
        200,
      )
    }
  }
}

fn category_option(
  value: String,
  label: String,
  current: String,
) -> element.Element(msg) {
  case value == current {
    True ->
      html.option([attribute.value(value), attribute.selected(True)], label)
    False -> html.option([attribute.value(value)], label)
  }
}

fn fodmap_option(
  value: String,
  label: String,
  current: types.FodmapLevel,
) -> element.Element(msg) {
  let current_str = case current {
    types.Low -> "low"
    types.Medium -> "medium"
    types.High -> "high"
  }
  case value == current_str {
    True ->
      html.option([attribute.value(value), attribute.selected(True)], label)
    False -> html.option([attribute.value(value)], label)
  }
}

fn ingredient_input_row(index: Int) -> element.Element(msg) {
  html.div([attribute.class("form-row ingredient-row")], [
    html.div([attribute.class("form-group")], [
      html.input([
        attribute.type_("text"),
        attribute.name("ingredient_name_" <> int_to_string(index)),
        attribute.placeholder("Ingredient"),
        attribute.class("form-control"),
        attribute.required(True),
      ]),
    ]),
    html.div([attribute.class("form-group")], [
      html.input([
        attribute.type_("text"),
        attribute.name("ingredient_quantity_" <> int_to_string(index)),
        attribute.placeholder("Quantity"),
        attribute.class("form-control"),
        attribute.required(True),
      ]),
    ]),
  ])
}

fn instruction_input_row(index: Int) -> element.Element(msg) {
  html.div([attribute.class("form-group instruction-row")], [
    html.textarea(
      [
        attribute.name("instruction_" <> int_to_string(index)),
        attribute.attribute("rows", "2"),
        attribute.placeholder("Step " <> int_to_string(index + 1)),
        attribute.class("form-control"),
        attribute.required(True),
      ],
      "",
    ),
  ])
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
                    [
                      attribute.type_("submit"),
                      attribute.class("btn btn-danger"),
                    ],
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
  let entries = daily_log.entries

  // Get filter from query params
  let filter = case uri.parse_query(req.query |> option.unwrap("")) {
    Ok(params) -> {
      case list.find(params, fn(p) { p.0 == "filter" }) {
        Ok(#(_, f)) -> f
        Error(_) -> "all"
      }
    }
    Error(_) -> "all"
  }

  // Filter entries by meal type
  let filtered_entries = case filter {
    "breakfast" ->
      list.filter(entries, fn(e: FoodLogEntry) { e.meal_type == Breakfast })
    "lunch" ->
      list.filter(entries, fn(e: FoodLogEntry) { e.meal_type == Lunch })
    "dinner" ->
      list.filter(entries, fn(e: FoodLogEntry) { e.meal_type == Dinner })
    "snack" ->
      list.filter(entries, fn(e: FoodLogEntry) { e.meal_type == Snack })
    _ -> entries
  }

  // Calculate current macros from filtered entries
  let current = sum_macros(filtered_entries)

  let content = [
    page_header("Dashboard", "/"),
    html.div([attribute.class("dashboard")], [
      // Date
      html.p([attribute.class("date")], [element.text(date)]),
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
    [element.text(label)],
  )
}

fn meal_entry_item(entry: FoodLogEntry) -> element.Element(msg) {
  html.li([attribute.class("meal-entry")], [
    html.div([attribute.class("meal-info")], [
      html.span([attribute.class("meal-name")], [
        element.text(entry.recipe_name),
      ]),
      html.span([attribute.class("meal-servings")], [
        element.text(" (" <> float_to_string(entry.servings) <> " serving)"),
      ]),
      html.span([attribute.class("meal-type-badge")], [
        element.text(meal_type_to_string(entry.meal_type)),
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
      [element.text("×")],
    ),
  ])
}

fn sum_macros(entries: List(FoodLogEntry)) -> Macros {
  list.fold(entries, Macros(protein: 0.0, fat: 0.0, carbs: 0.0), fn(acc, entry) {
    Macros(
      protein: acc.protein +. entry.macros.protein,
      fat: acc.fat +. entry.macros.fat,
      carbs: acc.carbs +. entry.macros.carbs,
    )
  })
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

fn log_meal_page(ctx: Context) -> wisp.Response {
  let recipes = load_recipes(ctx)

  let content = [
    page_header("Log Meal", "/dashboard"),
    html.div([attribute.class("page-description")], [
      html.p([], [element.text("Select a recipe to log:")]),
    ]),
    html.div(
      [attribute.class("recipe-grid")],
      list.map(recipes, fn(recipe) {
        html.a(
          [
            attribute.class("recipe-card"),
            attribute.href("/log/" <> recipe.id),
          ],
          [
            html.div([attribute.class("recipe-card-content")], [
              html.h3([attribute.class("recipe-title")], [
                element.text(recipe.name),
              ]),
              html.span([attribute.class("recipe-category")], [
                element.text(recipe.category),
              ]),
              html.div([attribute.class("recipe-macros")], [
                macro_badge("P", recipe.macros.protein),
                macro_badge("F", recipe.macros.fat),
                macro_badge("C", recipe.macros.carbs),
              ]),
              html.div([attribute.class("recipe-calories")], [
                element.text(
                  float_to_string(types.macros_calories(recipe.macros))
                  <> " cal",
                ),
              ]),
            ]),
          ],
        )
      }),
    ),
  ]

  wisp.html_response(render_page("Log Meal - Meal Planner", content), 200)
}

fn log_meal_form(recipe_id: String, ctx: Context) -> wisp.Response {
  case load_recipe_by_id(ctx, recipe_id) {
    Ok(recipe) -> {
      let content = [
        html.a([attribute.href("/log"), attribute.class("back-link")], [
          element.text("← Back to recipe selection"),
        ]),
        html.div([attribute.class("log-form-container")], [
          html.h1([], [element.text("Log: " <> recipe.name)]),
          html.div([attribute.class("recipe-summary")], [
            html.p([attribute.class("meta")], [
              element.text(
                "Per serving: "
                <> float_to_string(types.macros_calories(recipe.macros))
                <> " cal",
              ),
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
                html.button(
                  [
                    attribute.type_("submit"),
                    attribute.class("btn btn-primary"),
                  ],
                  [element.text("Log Meal")],
                ),
                html.a(
                  [attribute.href("/log"), attribute.class("btn btn-secondary")],
                  [element.text("Cancel")],
                ),
              ]),
            ],
          ),
        ]),
      ]

      wisp.html_response(
        render_page("Log " <> recipe.name <> " - Meal Planner", content),
        200,
      )
    }
    Error(_) -> not_found_page()
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

fn foods_page(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Check if this is an HTMX request
  let is_htmx = case request.get_header(req, "hx-request") {
    Ok(_) -> True
    Error(_) -> False
  }

  // Parse query parameters
  let parsed_query = uri.parse_query(req.query |> option.unwrap(""))

  // Get search query from URL params
  let query = case parsed_query {
    Ok(params) -> {
      case list.find(params, fn(p) { p.0 == "q" }) {
        Ok(#(_, q)) -> Some(q)
        Error(_) -> None
      }
    }
    Error(_) -> None
  }

  // Parse filter parameters for HTMX requests
  let filters = case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified" || p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        Ok(#(_, "1")) -> True
        _ -> False
      }

      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded" || p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        Ok(#(_, "1")) -> True
        _ -> False
      }

      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" && cat != "all" -> Some(cat)
        _ -> None
      }

      types.SearchFilters(
        verified_only: verified_only,
        branded_only: branded_only,
        category: category,
      )
    }
    Error(_) ->
      types.SearchFilters(
        verified_only: False,
        branded_only: False,
        category: None,
      )
  }

  // Search with filters
  let #(ctx, foods) = case query {
    Some(q) if q != "" -> search_foods_filtered(ctx, q, filters, 50)
    _ -> #(ctx, [])
  }

  // If HTMX request, return only the search results fragment
  case is_htmx {
    True -> {
      let results_html =
        html.div([attribute.id("search-results")], [
          case query {
            Some(q) if q != "" -> {
              case foods {
                [] ->
                  html.p([attribute.class("empty-state")], [
                    element.text("No foods found matching \"" <> q <> "\""),
                  ])
                _ ->
                  html.div(
                    [attribute.class("food-list")],
                    list.map(foods, food_row),
                  )
              }
            }
            _ ->
              html.p([attribute.class("empty-state")], [
                element.text("Enter a search term to find foods"),
              ])
          },
        ])

      // Return just the HTML fragment for HTMX
      wisp.html_response(element.to_string(results_html), 200)
    }
    False -> {
      // Normal request - return full page
      let food_count = get_foods_count(ctx)

      // Create filter chips and categories
      let chips = food_search.default_filter_chips()
      let categories = food_search.default_categories()

      let content = [
        html.div([attribute.class("page-header")], [
          html.h1([], [element.text("Food Search")]),
          html.p([attribute.class("subtitle")], [
            element.text(
              "Search " <> int_to_string(food_count) <> " USDA foods",
            ),
          ]),
        ]),
        // Filter chips above search form
        food_search.render_filter_chips_with_dropdown(chips, categories),
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
        // Wrap search results in HTMX target container
        html.div([attribute.id("search-results")], [
          case query {
            Some(q) if q != "" -> {
              case foods {
                [] ->
                  html.p([attribute.class("empty-state")], [
                    element.text("No foods found matching \"" <> q <> "\""),
                  ])
                _ ->
                  html.div(
                    [attribute.class("food-list")],
                    list.map(foods, food_row),
                  )
              }
            }
            _ ->
              html.p([attribute.class("empty-state")], [
                element.text("Enter a search term to find foods"),
              ])
          },
        ]),
      ]

      wisp.html_response(
        render_page("Food Search - Meal Planner", content),
        200,
      )
    }
  }
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
        // HTMX library - the ONLY JavaScript allowed in the project
        // All interactivity must use HTMX attributes, not custom JS files
        html.script([attribute.src("https://unpkg.com/htmx.org@1.9.10")], ""),
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
    ["recipes"] -> recipe.api_recipes(req, recipe.Context(db: ctx.db))
    ["recipes", id] -> recipe.api_recipe(req, id, recipe.Context(db: ctx.db))
    ["profile"] -> profile.api_profile(req, profile.Context(db: ctx.db))
    ["foods"] -> search.api_foods(req, search.Context(db: ctx.db))
    ["foods", "search"] -> api_foods_search(req, ctx)
    ["foods", id] -> search.api_food(req, id, search.Context(db: ctx.db))
    ["logs"] -> food_log.api_logs_create(req, food_log.Context(db: ctx.db))
    ["logs", "entry", id] ->
      food_log.api_log_entry(req, id, food_log.Context(db: ctx.db))
    ["recipe-sources"] -> api_recipe_sources(req, ctx)
    ["meal-plans", "auto"] -> api_auto_meal_plan(req, ctx)
    ["meal-plans", "auto", id] -> api_auto_meal_plan_by_id(req, id, ctx)
    _ -> wisp.not_found()
  }
}

fn api_recipes(req: wisp.Request, ctx: Context) -> wisp.Response {
  case req.method {
    http.Get -> {
      let recipes = load_recipes(ctx)
      let json_data = json.array(recipes, recipe_to_json)
      wisp.json_response(json.to_string(json_data), 200)
    }
    http.Post -> create_recipe_handler(req, ctx)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn create_recipe_handler(req: wisp.Request, ctx: Context) -> wisp.Response {
  use form_data <- wisp.require_form(req)

  case parse_recipe_from_form(form_data.values) {
    Ok(recipe) -> {
      case storage.save_recipe(ctx.db, recipe) {
        Ok(_) -> {
          wisp.redirect("/recipes/" <> recipe.id)
        }
        Error(storage.DatabaseError(msg)) -> {
          let error_json =
            json.object([
              #("error", json.string("Failed to save recipe: " <> msg)),
            ])
          wisp.json_response(json.to_string(error_json), 500)
        }
        Error(storage.NotFound) -> {
          let error_json = json.object([#("error", json.string("Not found"))])
          wisp.json_response(json.to_string(error_json), 404)
        }
        Error(storage.InvalidInput(msg)) -> {
          let error_json =
            json.object([#("error", json.string("Invalid input: " <> msg))])
          wisp.json_response(json.to_string(error_json), 400)
        }
        Error(storage.Unauthorized(msg)) -> {
          let error_json =
            json.object([#("error", json.string("Unauthorized: " <> msg))])
          wisp.json_response(json.to_string(error_json), 401)
        }
      }
    }
    Error(errors) -> {
      let error_json =
        json.object([
          #("error", json.string("Validation failed")),
          #("details", json.array(errors, json.string)),
        ])
      wisp.json_response(json.to_string(error_json), 400)
    }
  }
}

fn parse_recipe_from_form(
  values: List(#(String, String)),
) -> Result(Recipe, List(String)) {
  // Extract basic fields
  let name = case list.key_find(values, "name") {
    Ok(n) if n != "" -> Ok(n)
    _ -> Error("Recipe name is required")
  }

  let category = case list.key_find(values, "category") {
    Ok(c) if c != "" -> Ok(c)
    _ -> Error("Category is required")
  }

  let servings = case list.key_find(values, "servings") {
    Ok(s) ->
      case int.parse(s) {
        Ok(num) if num > 0 -> Ok(num)
        _ -> Error("Servings must be a positive number")
      }
    _ -> Error("Servings is required")
  }

  // Extract macros
  let protein = case list.key_find(values, "protein") {
    Ok(p) ->
      case float.parse(p) {
        Ok(num) if num >=. 0.0 -> Ok(num)
        _ -> Error("Protein must be a non-negative number")
      }
    _ -> Error("Protein is required")
  }

  let fat = case list.key_find(values, "fat") {
    Ok(f) ->
      case float.parse(f) {
        Ok(num) if num >=. 0.0 -> Ok(num)
        _ -> Error("Fat must be a non-negative number")
      }
    _ -> Error("Fat is required")
  }

  let carbs = case list.key_find(values, "carbs") {
    Ok(c) ->
      case float.parse(c) {
        Ok(num) if num >=. 0.0 -> Ok(num)
        _ -> Error("Carbs must be a non-negative number")
      }
    _ -> Error("Carbs is required")
  }

  // Extract FODMAP level
  let fodmap_level = case list.key_find(values, "fodmap_level") {
    Ok("low") -> Ok(types.Low)
    Ok("medium") -> Ok(types.Medium)
    Ok("high") -> Ok(types.High)
    _ -> Error("FODMAP level must be 'low', 'medium', or 'high'")
  }

  // Extract vertical_compliant (checkbox)
  let vertical_compliant = case list.key_find(values, "vertical_compliant") {
    Ok("true") -> True
    _ -> False
  }

  // Extract ingredients (dynamic fields)
  let ingredients = extract_ingredients(values)
  let ingredients_result = case ingredients {
    [] -> Error("At least one ingredient is required")
    _ -> Ok(ingredients)
  }

  // Extract instructions (dynamic fields)
  let instructions = extract_instructions(values)
  let instructions_result = case instructions {
    [] -> Error("At least one instruction is required")
    _ -> Ok(instructions)
  }

  // Collect all errors
  let all_errors =
    []
    |> add_error(name)
    |> add_error(category)
    |> add_error(servings)
    |> add_error(protein)
    |> add_error(fat)
    |> add_error(carbs)
    |> add_error(fodmap_level)
    |> add_error(ingredients_result)
    |> add_error(instructions_result)

  case all_errors {
    [] -> {
      // All validations passed, create Recipe
      let assert Ok(name_val) = name
      let assert Ok(category_val) = category
      let assert Ok(servings_val) = servings
      let assert Ok(protein_val) = protein
      let assert Ok(fat_val) = fat
      let assert Ok(carbs_val) = carbs
      let assert Ok(fodmap_val) = fodmap_level
      let assert Ok(ingredients_val) = ingredients_result
      let assert Ok(instructions_val) = instructions_result

      let recipe =
        types.Recipe(
          id: generate_recipe_id(name_val),
          name: name_val,
          ingredients: ingredients_val,
          instructions: instructions_val,
          macros: Macros(protein: protein_val, fat: fat_val, carbs: carbs_val),
          servings: servings_val,
          category: category_val,
          fodmap_level: fodmap_val,
          vertical_compliant: vertical_compliant,
        )

      Ok(recipe)
    }
    errs -> Error(errs)
  }
}

fn add_error(errors: List(String), result: Result(a, String)) -> List(String) {
  case result {
    Ok(_) -> errors
    Error(msg) -> [msg, ..errors]
  }
}

fn extract_ingredients(
  values: List(#(String, String)),
) -> List(types.Ingredient) {
  let ingredient_pairs =
    list.filter_map(values, fn(pair) {
      let #(key, _) = pair
      case string.starts_with(key, "ingredient_name_") {
        True -> {
          let index = string.replace(key, "ingredient_name_", "")
          Ok(index)
        }
        False -> Error(Nil)
      }
    })

  list.filter_map(ingredient_pairs, fn(index) {
    let name_key = "ingredient_name_" <> index
    let quantity_key = "ingredient_quantity_" <> index

    let name = list.key_find(values, name_key) |> result.unwrap("")
    let quantity = list.key_find(values, quantity_key) |> result.unwrap("")

    case name != "" && quantity != "" {
      True -> Ok(types.Ingredient(name: name, quantity: quantity))
      False -> Error(Nil)
    }
  })
}

fn extract_instructions(values: List(#(String, String))) -> List(String) {
  let instruction_indices =
    list.filter_map(values, fn(pair) {
      let #(key, _) = pair
      case string.starts_with(key, "instruction_") {
        True -> {
          let index = string.replace(key, "instruction_", "")
          Ok(index)
        }
        False -> Error(Nil)
      }
    })

  list.filter_map(instruction_indices, fn(index) {
    let key = "instruction_" <> index
    case list.key_find(values, key) {
      Ok(instruction) -> {
        case instruction != "" {
          True -> Ok(instruction)
          False -> Error(Nil)
        }
      }
      Error(_) -> Error(Nil)
    }
  })
}

fn generate_recipe_id(name: String) -> String {
  let normalized =
    name
    |> string.lowercase
    |> string.replace(" ", "-")
    |> string.replace("'", "")
    |> string.replace("\"", "")

  // Add timestamp to ensure uniqueness
  let timestamp = get_timestamp_string()
  normalized <> "-" <> timestamp
}

@external(erlang, "erlang", "system_time")
fn system_time(unit: Int) -> Int

fn get_timestamp_string() -> String {
  // Get milliseconds since epoch
  let millis = system_time(1000)
  // Take last 6 digits to keep ID shorter
  let short_id = millis % 1_000_000
  int_to_string(short_id)
}

fn api_recipe(req: wisp.Request, id: String, ctx: Context) -> wisp.Response {
  case req.method {
    http.Get -> {
      case load_recipe_by_id(ctx, id) {
        Ok(recipe) -> {
          let json_data = recipe_to_json(recipe)
          wisp.json_response(json.to_string(json_data), 200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    http.Post -> {
      // Handle both DELETE (_method=DELETE) and UPDATE (_method=PUT) via method override
      use form_data <- wisp.require_form(req)

      let method_override = list.key_find(form_data.values, "_method")

      case method_override {
        Ok("DELETE") -> {
          // Handle delete
          case storage.delete_recipe(ctx.db, id) {
            Ok(_) -> wisp.redirect("/recipes")
            Error(_) -> wisp.not_found()
          }
        }
        Ok("PUT") -> {
          // Handle update
          case parse_recipe_from_form(form_data.values) {
            Ok(recipe) -> {
              let updated_recipe = types.Recipe(..recipe, id: id)
              case storage.save_recipe(ctx.db, updated_recipe) {
                Ok(_) -> wisp.redirect("/recipes/" <> id)
                Error(storage.DatabaseError(msg)) -> {
                  let error_json =
                    json.object([
                      #(
                        "error",
                        json.string("Failed to update recipe: " <> msg),
                      ),
                    ])
                  wisp.json_response(json.to_string(error_json), 500)
                }
                Error(storage.NotFound) -> {
                  let error_json =
                    json.object([#("error", json.string("Recipe not found"))])
                  wisp.json_response(json.to_string(error_json), 404)
                }
                Error(storage.InvalidInput(msg)) -> {
                  let error_json =
                    json.object([
                      #("error", json.string("Invalid input: " <> msg)),
                    ])
                  wisp.json_response(json.to_string(error_json), 400)
                }
                Error(storage.Unauthorized(msg)) -> {
                  let error_json =
                    json.object([
                      #("error", json.string("Unauthorized: " <> msg)),
                    ])
                  wisp.json_response(json.to_string(error_json), 401)
                }
              }
            }
            Error(errors) -> {
              let error_json =
                json.object([
                  #("error", json.string("Validation failed")),
                  #("details", json.array(errors, json.string)),
                ])
              wisp.json_response(json.to_string(error_json), 400)
            }
          }
        }
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    }
    http.Delete -> {
      case storage.delete_recipe(ctx.db, id) {
        Ok(_) -> wisp.json_response("{\"success\": true}", 200)
        Error(_) -> wisp.not_found()
      }
    }
    _ -> wisp.method_not_allowed([http.Get, http.Post, http.Delete])
  }
}

fn api_profile(_req: wisp.Request, ctx: Context) -> wisp.Response {
  let profile = load_profile(ctx)
  let json_data = profile_to_json(profile)
  wisp.json_response(json.to_string(json_data), 200)
}

fn api_foods(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Parse all query parameters
  let parsed_query = uri.parse_query(req.query |> option.unwrap(""))

  // Read search query - support both 'q' and 'query' parameter names
  let query = case parsed_query {
    Ok(params) -> {
      // Try 'q' first, then 'query' as fallback
      case list.find(params, fn(p) { p.0 == "q" }) {
        Ok(#(_, q)) -> q
        Error(_) ->
          case list.find(params, fn(p) { p.0 == "query" }) {
            Ok(#(_, q)) -> q
            Error(_) -> ""
          }
      }
    }
    Error(_) -> ""
  }

  // Parse all filter parameters from URL query string
  // This ensures the handler is stateless and works with HTMX URL-based state
  let filters = case parsed_query {
    Ok(params) -> {
      // Parse verified filter - accepts "true" string or "1"
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified" || p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        Ok(#(_, "1")) -> True
        _ -> False
      }

      // Parse branded filter - accepts "true" string or "1"
      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded" || p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        Ok(#(_, "1")) -> True
        _ -> False
      }

      // Parse category filter - empty string treated as None
      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" && cat != "all" -> Some(cat)
        _ -> None
      }

      types.SearchFilters(
        verified_only: verified_only,
        branded_only: branded_only,
        category: category,
      )
    }
    Error(_) ->
      // Default filters when no query params
      types.SearchFilters(
        verified_only: False,
        branded_only: False,
        category: None,
      )
  }

  case query {
    "" -> {
      let json_data =
        json.object([
          #("error", json.string("Query parameter 'q' or 'query' required")),
        ])
      wisp.json_response(json.to_string(json_data), 400)
    }
    q -> {
      let #(_updated_ctx, foods) = search_foods_filtered(ctx, q, filters, 50)
      let json_data = json.array(foods, food_to_json)
      wisp.json_response(json.to_string(json_data), 200)
    }
  }
}

/// API endpoint for HTMX filter requests - returns HTML fragment
/// GET /api/foods/search?q=query&filter=all|verified|branded|category&category=Vegetables
fn api_foods_search(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Parse all query parameters
  let parsed_query = uri.parse_query(req.query |> option.unwrap(""))

  // Read search query - support both 'q' and 'query' parameter names
  let query = case parsed_query {
    Ok(params) -> {
      // Try 'q' first, then 'query' as fallback
      case list.find(params, fn(p) { p.0 == "q" }) {
        Ok(#(_, q)) -> q
        Error(_) ->
          case list.find(params, fn(p) { p.0 == "query" }) {
            Ok(#(_, q)) -> q
            Error(_) -> ""
          }
      }
    }
    Error(_) -> ""
  }

  // Parse filter parameter: all, verified, branded, or category
  let filter_type = case parsed_query {
    Ok(params) ->
      case list.find(params, fn(p) { p.0 == "filter" }) {
        Ok(#(_, f)) -> f
        Error(_) -> "all"
      }
    Error(_) -> "all"
  }

  // Parse category parameter
  let category_param = case parsed_query {
    Ok(params) ->
      case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        Ok(#(_, _)) -> None
        Error(_) -> None
      }
    Error(_) -> None
  }

  // Build SearchFilters based on filter type
  let filters = case filter_type {
    "verified" ->
      types.SearchFilters(
        verified_only: True,
        branded_only: False,
        category: None,
      )
    "branded" ->
      types.SearchFilters(
        verified_only: False,
        branded_only: True,
        category: None,
      )
    "category" ->
      types.SearchFilters(
        verified_only: False,
        branded_only: False,
        category: category_param,
      )
    _ ->
      // "all" or any other value
      types.SearchFilters(
        verified_only: False,
        branded_only: False,
        category: None,
      )
  }

  // Execute search or return empty state
  let #(_updated_ctx, foods) = case query {
    "" -> #(ctx, [])
    q -> search_foods_filtered(ctx, q, filters, 50)
  }

  // Render HTML fragment for HTMX to swap in
  let search_results = case query {
    "" ->
      html.div(
        [attribute.id("search-results"), attribute.class("empty-state")],
        [
          element.text("Enter a search term to find foods"),
        ],
      )
    q ->
      case foods {
        [] ->
          html.div(
            [attribute.id("search-results"), attribute.class("empty-state")],
            [element.text("No foods found matching \"" <> q <> "\"")],
          )
        _ ->
          html.div(
            [attribute.id("search-results"), attribute.class("food-list")],
            list.map(foods, food_row),
          )
      }
  }

  // Return only the HTML fragment (not a full page)
  wisp.html_response(element.to_string(search_results), 200)
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

/// POST /api/logs - Create a new food log entry
fn api_logs_create(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Get query params for form submission
  case uri.parse_query(req.query |> option.unwrap("")) {
    Ok(params) -> {
      let recipe_id =
        list.find(params, fn(p) { p.0 == "recipe_id" })
        |> result.map(fn(p) { p.1 })
      let servings_str =
        list.find(params, fn(p) { p.0 == "servings" })
        |> result.map(fn(p) { p.1 })
      let meal_type_str =
        list.find(params, fn(p) { p.0 == "meal_type" })
        |> result.map(fn(p) { p.1 })

      case recipe_id, servings_str, meal_type_str {
        Ok(rid), Ok(sstr), Ok(mtstr) -> {
          let servings = case float.parse(sstr) {
            Ok(s) -> s
            Error(_) -> 1.0
          }
          let meal_type = string_to_meal_type(mtstr)
          let today = get_today_date()

          // Get recipe to calculate macros
          case load_recipe_by_id(ctx, rid) {
            Error(_) -> wisp.not_found()
            Ok(recipe) -> {
              let scaled_macros = types.macros_scale(recipe.macros, servings)
              let entry =
                FoodLogEntry(
                  id: generate_entry_id(),
                  recipe_id: recipe.id,
                  recipe_name: recipe.name,
                  servings: servings,
                  macros: scaled_macros,
                  micronutrients: None,
                  meal_type: meal_type,
                  logged_at: current_timestamp(),
                  source_type: "recipe",
                  source_id: recipe.id,
                )

              case storage.save_food_log_entry(ctx.db, today, entry) {
                Ok(_) -> wisp.redirect("/dashboard")
                Error(_) -> {
                  let err =
                    json.object([
                      #("error", json.string("Failed to save entry")),
                    ])
                  wisp.json_response(json.to_string(err), 500)
                }
              }
            }
          }
        }
        _, _, _ -> {
          let err =
            json.object([
              #("error", json.string("Missing required parameters")),
            ])
          wisp.json_response(json.to_string(err), 400)
        }
      }
    }
    Error(_) -> {
      let err =
        json.object([#("error", json.string("Invalid query parameters"))])
      wisp.json_response(json.to_string(err), 400)
    }
  }
}

/// GET/DELETE /api/logs/entry/:id - Manage a log entry
fn api_log_entry(
  req: wisp.Request,
  entry_id: String,
  ctx: Context,
) -> wisp.Response {
  // Check for delete action in query params
  case uri.parse_query(req.query |> option.unwrap("")) {
    Ok(params) -> {
      case list.find(params, fn(p) { p.0 == "action" && p.1 == "delete" }) {
        Ok(_) -> {
          case storage.delete_food_log(ctx.db, entry_id) {
            Ok(_) -> wisp.redirect("/dashboard")
            Error(_) -> wisp.not_found()
          }
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(_) -> wisp.not_found()
  }
}

fn api_recipe_sources(req: wisp.Request, ctx: Context) -> wisp.Response {
  case req.method {
    http.Post -> create_recipe_source(req, ctx)
    http.Get -> list_recipe_sources(ctx)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn create_recipe_source(req: wisp.Request, ctx: Context) -> wisp.Response {
  use json_body <- wisp.require_json(req)

  // Decode the JSON body using the decoder
  case decode.run(json_body, auto_types.recipe_source_decoder()) {
    Error(_) -> {
      let error_json =
        json.object([#("error", json.string("Invalid JSON format"))])
      wisp.json_response(json.to_string(error_json), 400)
    }
    Ok(source_data) -> {
      // Generate a unique ID for the new source
      let id = "src-" <> int.to_string(int.random(100_000_000))
      let source =
        auto_types.RecipeSource(
          id: id,
          name: source_data.name,
          source_type: source_data.source_type,
          config: source_data.config,
        )

      // Save to database
      case auto_storage.save_recipe_source(ctx.db, source) {
        Ok(_) -> {
          let response_json = auto_types.recipe_source_to_json(source)
          wisp.json_response(json.to_string(response_json), 201)
        }
        Error(storage.DatabaseError(msg)) -> {
          let error_json = json.object([#("error", json.string(msg))])
          wisp.json_response(json.to_string(error_json), 500)
        }
        Error(_) -> {
          let error_json =
            json.object([
              #("error", json.string("Failed to create recipe source")),
            ])
          wisp.json_response(json.to_string(error_json), 500)
        }
      }
    }
  }
}

fn list_recipe_sources(ctx: Context) -> wisp.Response {
  case auto_storage.get_recipe_sources(ctx.db) {
    Ok(sources) -> {
      let json_data = json.array(sources, auto_types.recipe_source_to_json)
      wisp.json_response(json.to_string(json_data), 200)
    }
    Error(storage.DatabaseError(msg)) -> {
      let error_json = json.object([#("error", json.string(msg))])
      wisp.json_response(json.to_string(error_json), 500)
    }
    Error(_) -> {
      let error_json =
        json.object([
          #("error", json.string("Failed to fetch recipe sources")),
        ])
      wisp.json_response(json.to_string(error_json), 500)
    }
  }
}

// ============================================================================
// Auto Meal Plan API
// ============================================================================

/// POST /api/meal-plans/auto - Generate auto meal plan
fn api_auto_meal_plan(req: wisp.Request, ctx: Context) -> wisp.Response {
  case req.method {
    http.Post -> create_auto_meal_plan(req, ctx)
    _ -> wisp.method_not_allowed([http.Post])
  }
}

fn create_auto_meal_plan(req: wisp.Request, ctx: Context) -> wisp.Response {
  use json_body <- wisp.require_json(req)

  // Decode the JSON body using the config decoder
  case decode.run(json_body, auto_types.auto_plan_config_decoder()) {
    Error(_) -> {
      let error_json =
        json.object([#("error", json.string("Invalid JSON format"))])
      wisp.json_response(json.to_string(error_json), 400)
    }
    Ok(config) -> {
      // Validate config
      case auto_types.validate_config(config) {
        Error(msg) -> {
          let error_json = json.object([#("error", json.string(msg))])
          wisp.json_response(json.to_string(error_json), 400)
        }
        Ok(_) -> {
          // Load all recipes from database
          let recipes = load_recipes(ctx)

          // Generate auto meal plan
          case auto_planner.generate_auto_plan(recipes, config) {
            Error(msg) -> {
              let error_json = json.object([#("error", json.string(msg))])
              wisp.json_response(json.to_string(error_json), 400)
            }
            Ok(plan) -> {
              // Save plan to database
              case auto_storage.save_auto_plan(ctx.db, plan) {
                Error(storage.DatabaseError(msg)) -> {
                  let error_json =
                    json.object([
                      #("error", json.string("Failed to save plan: " <> msg)),
                    ])
                  wisp.json_response(json.to_string(error_json), 500)
                }
                Error(_) -> {
                  let error_json =
                    json.object([
                      #("error", json.string("Failed to save plan")),
                    ])
                  wisp.json_response(json.to_string(error_json), 500)
                }
                Ok(_) -> {
                  // Return the generated plan
                  let response_json = auto_types.auto_meal_plan_to_json(plan)
                  wisp.json_response(json.to_string(response_json), 201)
                }
              }
            }
          }
        }
      }
    }
  }
}

/// GET /api/meal-plans/auto/:id - Retrieve auto meal plan by ID
fn api_auto_meal_plan_by_id(
  req: wisp.Request,
  id: String,
  ctx: Context,
) -> wisp.Response {
  case req.method {
    http.Get -> get_auto_meal_plan_by_id(id, ctx)
    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn get_auto_meal_plan_by_id(id: String, ctx: Context) -> wisp.Response {
  case auto_storage.get_auto_plan(ctx.db, id) {
    Error(storage.NotFound) -> {
      let error_json =
        json.object([#("error", json.string("Meal plan not found"))])
      wisp.json_response(json.to_string(error_json), 404)
    }
    Error(storage.DatabaseError(msg)) -> {
      let error_json =
        json.object([#("error", json.string("Database error: " <> msg))])
      wisp.json_response(json.to_string(error_json), 500)
    }
    Error(_) -> {
      let error_json =
        json.object([#("error", json.string("Failed to retrieve meal plan"))])
      wisp.json_response(json.to_string(error_json), 500)
    }
    Ok(plan) -> {
      let response_json = auto_types.auto_meal_plan_to_json(plan)
      wisp.json_response(json.to_string(response_json), 200)
    }
  }
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
) -> #(Context, List(storage.UsdaFood)) {
  let #(updated_cache, result) =
    storage_optimized.search_foods_cached(
      ctx.db,
      ctx.search_cache,
      query,
      limit,
    )

  let updated_ctx = Context(..ctx, search_cache: updated_cache)

  case result {
    Ok(foods) -> #(updated_ctx, foods)
    Error(_) -> #(updated_ctx, [])
  }
}

fn search_foods_filtered(
  ctx: Context,
  query: String,
  filters: SearchFilters,
  limit: Int,
) -> #(Context, List(storage.UsdaFood)) {
  let #(updated_cache, result) =
    storage_optimized.search_foods_filtered_cached(
      ctx.db,
      ctx.search_cache,
      query,
      filters,
      limit,
    )

  let updated_ctx = Context(..ctx, search_cache: updated_cache)

  case result {
    Ok(foods) -> #(updated_ctx, foods)
    Error(_) -> #(updated_ctx, [])
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
        total_micronutrients: Some(types.micronutrients_zero()),
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

fn meal_type_to_string(meal_type: MealType) -> String {
  case meal_type {
    Breakfast -> "Breakfast"
    Lunch -> "Lunch"
    Dinner -> "Dinner"
    Snack -> "Snack"
  }
}

/// Convert string to meal type
fn string_to_meal_type(s: String) -> MealType {
  case s {
    "breakfast" -> Breakfast
    "lunch" -> Lunch
    "dinner" -> Dinner
    "snack" -> Snack
    _ -> Lunch
  }
}

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

fn pad_two(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}

@external(erlang, "calendar", "local_time")
fn erlang_localtime() -> #(#(Int, Int, Int), #(Int, Int, Int))

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(i: Int) -> String

// ============================================================================
// Error Response Helpers
// ============================================================================

/// Create a user-friendly error response page
fn error_response(
  status: Int,
  title: String,
  message: String,
  retry_url: option.Option(String),
) -> wisp.Response {
  let retry_button = case retry_url {
    Some(url) -> [
      html.a([attribute.href(url), attribute.class("btn btn-primary")], [
        element.text("Try Again"),
      ]),
    ]
    None -> []
  }

  let content = [
    html.div([attribute.class("error-page")], [
      html.div([attribute.class("error-page-content")], [
        html.div([attribute.class("error-icon-large")], [element.text("⚠")]),
        html.h1([attribute.class("error-title")], [element.text(title)]),
        html.p([attribute.class("error-message")], [element.text(message)]),
        html.div([attribute.class("error-actions")], [
          html.a([attribute.href("/"), attribute.class("btn btn-secondary")], [
            element.text("Go Home"),
          ]),
          ..retry_button
        ]),
      ]),
    ]),
  ]

  wisp.html_response(render_page(title, content), status)
}

/// 500 Server Error response
fn server_error_response(message: String) -> wisp.Response {
  error_response(
    500,
    "500 Server Error",
    "Something went wrong on our end. " <> message,
    None,
  )
}

/// 400 Bad Request response
fn bad_request_response(message: String) -> wisp.Response {
  error_response(400, "400 Bad Request", "Invalid request. " <> message, None)
}

/// 404 Not Found response with helpful actions
fn enhanced_not_found() -> wisp.Response {
  let content = [
    html.div([attribute.class("error-page")], [
      html.div([attribute.class("error-page-content")], [
        html.h1([attribute.class("error-code")], [element.text("404")]),
        html.h2([attribute.class("error-title")], [
          element.text("Page Not Found"),
        ]),
        html.p([attribute.class("error-message")], [
          element.text(
            "The page you're looking for doesn't exist or has been moved.",
          ),
        ]),
        html.div([attribute.class("error-actions")], [
          html.a([attribute.href("/"), attribute.class("btn btn-primary")], [
            element.text("Go Home"),
          ]),
          html.a(
            [attribute.href("/recipes"), attribute.class("btn btn-secondary")],
            [element.text("Browse Recipes")],
          ),
        ]),
      ]),
    ]),
  ]

  wisp.html_response(render_page("404 Not Found", content), 404)
}

/// JSON error response for API endpoints
fn json_error_response(status: Int, error_message: String) -> wisp.Response {
  let error_json = json.object([#("error", json.string(error_message))])
  wisp.json_response(json.to_string(error_json), status)
}

/// Handle storage errors with appropriate HTTP responses
fn handle_storage_error(error: storage.StorageError) -> wisp.Response {
  case error {
    storage.NotFound -> json_error_response(404, "Resource not found")
    storage.InvalidInput(msg) ->
      json_error_response(400, "Invalid input: " <> msg)
    storage.Unauthorized(msg) ->
      json_error_response(401, "Unauthorized: " <> msg)
    storage.DatabaseError(msg) ->
      json_error_response(500, "Database error: " <> msg)
  }
}
