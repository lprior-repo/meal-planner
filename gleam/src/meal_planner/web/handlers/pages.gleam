//// Pages handler - Renders all SSR page routes
////
//// Responsible for:
//// - Home page
//// - Recipes pages (list, detail, new, edit)
//// - Foods pages (list, detail)
//// - Meal logging pages
//// - Weekly plan page
//// - Profile page
//// - 404 page
//// - Base layout and rendering

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/uri
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/nutrition_constants
import meal_planner/storage
import meal_planner/storage_optimized
import meal_planner/types.{
  type Recipe, type SearchFilters, type UserProfile, Macros, Maintain, Moderate,
  UserProfile,
}
import meal_planner/web/utilities
import pog
import wisp

// ============================================================================
// Context
// ============================================================================

/// Web context for page handlers
pub type Context {
  Context(db: pog.Connection, search_cache: storage_optimized.SearchCache)
}

// ============================================================================
// Home Page
// ============================================================================

/// GET / - Display home page with navigation
pub fn home_page() -> wisp.Response {
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

// ============================================================================
// Recipe Pages
// ============================================================================

/// GET /recipes - Display all recipes
pub fn recipes_page(ctx: Context) -> wisp.Response {
  let recipes = utilities.load_recipes(ctx.db)

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

/// GET /recipes/new - Display new recipe form
pub fn new_recipe_page() -> wisp.Response {
  let content = [
    html.a([attribute.href("/recipes"), attribute.class("back-link")], [
      element.text("← Back to recipes"),
    ]),
    html.div([attribute.class("page-header")], [
      html.h1([], [element.text("New Recipe")]),
    ]),
    render_recipe_form(None),
  ]

  wisp.html_response(render_page("New Recipe - Meal Planner", content), 200)
}

/// GET /recipes/{id}/edit - Display recipe edit form
pub fn edit_recipe_page(id: String, ctx: Context) -> wisp.Response {
  case utilities.load_recipe_by_id(ctx.db, id) {
    Error(_) -> not_found_page()
    Ok(recipe) -> {
      let content = [
        html.a(
          [attribute.href("/recipes/" <> id), attribute.class("back-link")],
          [element.text("← Back to recipe")],
        ),
        html.div([attribute.class("page-header")], [
          html.h1([], [element.text("Edit Recipe")]),
        ]),
        render_recipe_form(Some(recipe)),
      ]

      wisp.html_response(
        render_page("Edit " <> recipe.name <> " - Meal Planner", content),
        200,
      )
    }
  }
}

/// GET /recipes/{id} - Display recipe detail
pub fn recipe_detail_page(id: String, ctx: Context) -> wisp.Response {
  case utilities.load_recipe_by_id(ctx.db, id) {
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
          html.div([attribute.class("macro-card")], [
            html.h2([], [element.text("Nutrition per serving")]),
            html.div([attribute.class("macro-grid")], [
              macro_stat_block(
                "Protein",
                float.to_string(recipe.macros.protein) <> "g",
              ),
              macro_stat_block("Fat", float.to_string(recipe.macros.fat) <> "g"),
              macro_stat_block(
                "Carbs",
                float.to_string(recipe.macros.carbs) <> "g",
              ),
              macro_stat_block(
                "Calories",
                float.to_string(types.macros_calories(recipe.macros)),
              ),
            ]),
          ]),
          html.div([attribute.class("ingredients")], [
            html.h2([], [element.text("Ingredients")]),
            html.ul(
              [],
              list.map(recipe.ingredients, fn(ing) {
                html.li([], [
                  html.span([attribute.class("ingredient-quantity")], [
                    element.text(ing.quantity),
                  ]),
                  html.span([attribute.class("ingredient-separator")], [
                    element.text(" "),
                  ]),
                  html.span([attribute.class("ingredient-name")], [
                    element.text(ing.name),
                  ]),
                ])
              }),
            ),
          ]),
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

// ============================================================================
// Food Pages
// ============================================================================

/// GET /foods - Display food search page
pub fn foods_page(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Check if this is an HTMX request
  let is_htmx = case list.key_find(req.headers, "hx-request") {
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

  // Parse filter parameters
  let filters = parse_food_filters(parsed_query)

  // Search with filters
  let #(ctx, foods) = case query {
    Some(q) if q != "" ->
      search_foods_filtered(
        ctx,
        q,
        filters,
        nutrition_constants.default_search_limit,
      )
    _ -> #(ctx, [])
  }

  // If HTMX request, return only the search results fragment
  case is_htmx {
    True -> render_foods_search_fragment(query, foods)
    False -> render_foods_full_page(query, foods, ctx, filters)
  }
}

/// GET /foods/{id} - Display food detail
pub fn food_detail_page(id: String, ctx: Context) -> wisp.Response {
  case int.parse(id) {
    Error(_) -> not_found_page()
    Ok(fdc_id) -> {
      case utilities.load_food_by_id(ctx.db, fdc_id) {
        Error(_) -> not_found_page()
        Ok(food) -> {
          let nutrients = utilities.load_food_nutrients(ctx.db, fdc_id)
          // Find key macros
          let protein = utilities.find_nutrient(nutrients, "Protein")
          let fat = utilities.find_nutrient(nutrients, "Total lipid (fat)")
          let carbs =
            utilities.find_nutrient(nutrients, "Carbohydrate, by difference")
          let calories = utilities.find_nutrient(nutrients, "Energy")

          let content = [
            html.a([attribute.href("/foods"), attribute.class("back-link")], [
              element.text("← Back to search"),
            ]),
            html.div([attribute.class("food-detail")], [
              html.h1([], [element.text(food.description)]),
              html.p([attribute.class("meta")], [
                element.text("Type: " <> food.data_type),
              ]),
              html.div([attribute.class("macro-card")], [
                html.h2([], [element.text("Nutrition per 100g")]),
                html.div([attribute.class("macro-grid")], [
                  macro_stat_block(
                    "Protein",
                    utilities.format_nutrient(protein),
                  ),
                  macro_stat_block("Fat", utilities.format_nutrient(fat)),
                  macro_stat_block("Carbs", utilities.format_nutrient(carbs)),
                  macro_stat_block(
                    "Calories",
                    utilities.format_calories(calories),
                  ),
                ]),
              ]),
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

// ============================================================================
// Meal Logging Pages
// ============================================================================

/// GET /log - Display meal logging recipe selection
pub fn log_meal_page(ctx: Context) -> wisp.Response {
  let recipes = utilities.load_recipes(ctx.db)

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
                  float.to_string(types.macros_calories(recipe.macros))
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

/// GET /log/{recipe_id} - Display meal logging form
pub fn log_meal_form(recipe_id: String, ctx: Context) -> wisp.Response {
  case utilities.load_recipe_by_id(ctx.db, recipe_id) {
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
                <> float.to_string(types.macros_calories(recipe.macros))
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

/// GET /log/food/{id} - Display USDA food logging form with portion and meal selection
pub fn log_food_form(id: String, ctx: Context) -> wisp.Response {
  case int.parse(id) {
    Error(_) -> not_found_page()
    Ok(fdc_id) -> {
      case utilities.load_food_by_id(ctx.db, fdc_id) {
        Error(_) -> not_found_page()
        Ok(food) -> {
          let nutrients = utilities.load_food_nutrients(ctx.db, fdc_id)
          // Find key macros per 100g
          let protein = utilities.find_nutrient(nutrients, "Protein")
          let fat = utilities.find_nutrient(nutrients, "Total lipid (fat)")
          let carbs =
            utilities.find_nutrient(nutrients, "Carbohydrate, by difference")

          let content = [
            html.a([attribute.href("/foods"), attribute.class("back-link")], [
              element.text("← Back to food search"),
            ]),
            html.div([attribute.class("log-form-container")], [
              html.h1([], [element.text("Log: " <> food.description)]),
              html.div([attribute.class("food-summary")], [
                html.p([attribute.class("meta")], [
                  element.text("Type: " <> food.data_type),
                ]),
                html.p([attribute.class("meta")], [
                  element.text("Nutrition per 100g:"),
                ]),
                html.div([attribute.class("macro-badges")], [
                  macro_badge("P", extract_nutrient_value(protein)),
                  macro_badge("F", extract_nutrient_value(fat)),
                  macro_badge("C", extract_nutrient_value(carbs)),
                ]),
              ]),
              html.form(
                [
                  attribute.method("POST"),
                  attribute.action("/api/logs/food?food_id=" <> id),
                  attribute.class("log-form"),
                ],
                [
                  html.div([attribute.class("form-group")], [
                    html.label([attribute.attribute("for", "portion_grams")], [
                      element.text("Portion Size (grams)"),
                    ]),
                    html.input([
                      attribute.type_("number"),
                      attribute.id("portion_grams"),
                      attribute.name("portion_grams"),
                      attribute.attribute("min", "1"),
                      attribute.attribute("step", "1"),
                      attribute.value("100"),
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
                      [element.text("Log Food")],
                    ),
                    html.a(
                      [
                        attribute.href("/foods"),
                        attribute.class("btn btn-secondary"),
                      ],
                      [element.text("Cancel")],
                    ),
                  ]),
                ],
              ),
            ]),
          ]

          wisp.html_response(
            render_page(
              "Log " <> food.description <> " - Meal Planner",
              content,
            ),
            200,
          )
        }
      }
    }
  }
}

/// Extract nutrient value from optional FoodNutrientValue
fn extract_nutrient_value(
  nutrient: option.Option(storage.FoodNutrientValue),
) -> Float {
  case nutrient {
    Some(n) -> n.amount
    None -> 0.0
  }
}

// ============================================================================
// Weekly Plan Page
// ============================================================================

/// GET /weekly-plan - Display weekly meal plan
pub fn weekly_plan_page(_ctx: Context) -> wisp.Response {
  let content = [
    html.div([attribute.class("page-header")], [
      html.h1([], [element.text("Weekly Plan")]),
      html.p([attribute.class("subtitle")], [
        element.text("Plan your meals for the week"),
      ]),
    ]),
    render_weekly_calendar(),
  ]

  wisp.html_response(render_page("Weekly Plan - Meal Planner", content), 200)
}

// ============================================================================
// Profile Page
// ============================================================================

/// GET /profile - Display user profile
pub fn profile_page(ctx: Context) -> wisp.Response {
  let profile = utilities.load_profile(ctx.db)
  let targets = types.daily_macro_targets(profile)

  let content = [
    page_header("Profile", "/"),
    html.div([attribute.class("profile")], [
      html.div([attribute.class("profile-section")], [
        html.h2([], [element.text("Stats")]),
        html.dl([], [
          html.dt([], [element.text("Bodyweight")]),
          html.dd([], [
            element.text(float.to_string(profile.bodyweight) <> " lbs"),
          ]),
          html.dt([], [element.text("Activity Level")]),
          html.dd([], [element.text(activity_level_to_string(profile))]),
          html.dt([], [element.text("Goal")]),
          html.dd([], [element.text(goal_to_string(profile))]),
          html.dt([], [element.text("Meals per Day")]),
          html.dd([], [element.text(int.to_string(profile.meals_per_day))]),
        ]),
      ]),
      html.div([attribute.class("profile-section")], [
        html.h2([], [element.text("Daily Targets")]),
        html.dl([], [
          html.dt([], [element.text("Calories")]),
          html.dd([], [
            element.text(float.to_string(types.macros_calories(targets))),
          ]),
          html.dt([], [element.text("Protein")]),
          html.dd([], [element.text(float.to_string(targets.protein) <> "g")]),
          html.dt([], [element.text("Fat")]),
          html.dd([], [element.text(float.to_string(targets.fat) <> "g")]),
          html.dt([], [element.text("Carbs")]),
          html.dd([], [element.text(float.to_string(targets.carbs) <> "g")]),
        ]),
      ]),
    ]),
  ]

  wisp.html_response(render_page("Profile - Meal Planner", content), 200)
}

// ============================================================================
// 404 Page
// ============================================================================

/// Display 404 not found page
pub fn not_found_page() -> wisp.Response {
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

// ============================================================================
// Helper Functions - Recipe Form
// ============================================================================

fn render_recipe_form(recipe: option.Option(Recipe)) -> element.Element(Nil) {
  case recipe {
    Some(r) -> render_edit_recipe_form(r)
    None -> render_new_recipe_form()
  }
}

fn render_new_recipe_form() -> element.Element(Nil) {
  html.form(
    [
      attribute.method("POST"),
      attribute.action("/api/recipes"),
      attribute.class("recipe-form"),
    ],
    [
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
      render_nutrition_section(None),
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
      render_ingredients_section([], 0),
      render_instructions_section([], 0),
      html.div([attribute.class("form-actions")], [
        html.button(
          [attribute.type_("submit"), attribute.class("btn btn-primary")],
          [element.text("Create Recipe")],
        ),
      ]),
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
  )
}

fn render_edit_recipe_form(recipe: Recipe) -> element.Element(Nil) {
  html.form(
    [
      attribute.method("POST"),
      attribute.action("/api/recipes/" <> recipe.id),
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
          attribute.value(int.to_string(recipe.servings)),
          attribute.attribute("min", "1"),
          attribute.attribute("step", "1"),
          attribute.class("form-control"),
        ]),
      ]),
      render_nutrition_section(Some(recipe.macros)),
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
      render_ingredients_section(
        recipe.ingredients,
        list.length(recipe.ingredients),
      ),
      render_instructions_section(
        recipe.instructions,
        list.length(recipe.instructions),
      ),
      html.div([attribute.class("form-actions")], [
        html.button(
          [attribute.type_("submit"), attribute.class("btn btn-primary")],
          [element.text("Update Recipe")],
        ),
        html.a(
          [
            attribute.href("/recipes/" <> recipe.id),
            attribute.class("btn btn-secondary"),
          ],
          [element.text("Cancel")],
        ),
      ]),
      html.script([], "
let ingredientCount = " <> int.to_string(list.length(recipe.ingredients)) <> ";
let instructionCount = " <> int.to_string(list.length(recipe.instructions)) <> ";

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
  )
}

fn render_nutrition_section(
  macros: option.Option(types.Macros),
) -> element.Element(Nil) {
  let #(protein, fat, carbs) = case macros {
    Some(m) -> #(
      float.to_string(m.protein),
      float.to_string(m.fat),
      float.to_string(m.carbs),
    )
    None -> #("", "", "")
  }

  html.div([attribute.class("form-section")], [
    html.h2([], [element.text("Nutrition (per serving)")]),
    html.div([attribute.class("form-row")], [
      html.div([attribute.class("form-group")], [
        html.label([attribute.for("protein")], [element.text("Protein (g)")]),
        html.input([
          attribute.type_("number"),
          attribute.name("protein"),
          attribute.id("protein"),
          attribute.required(True),
          attribute.attribute("step", "0.1"),
          attribute.placeholder("0"),
          attribute.value(protein),
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
          attribute.value(fat),
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
          attribute.value(carbs),
          attribute.class("form-control"),
        ]),
      ]),
    ]),
  ])
}

fn render_ingredients_section(
  ingredients: List(types.Ingredient),
  count: Int,
) -> element.Element(Nil) {
  html.div([attribute.class("form-section")], [
    html.h2([], [element.text("Ingredients")]),
    html.div([attribute.id("ingredients-list")], case list.length(ingredients) {
      0 -> [ingredient_input_row(0)]
      _ ->
        list.index_map(ingredients, fn(ing, idx) {
          html.div([attribute.class("form-row ingredient-row")], [
            html.div([attribute.class("form-group")], [
              html.input([
                attribute.type_("text"),
                attribute.name("ingredient_name_" <> int.to_string(idx)),
                attribute.placeholder("Ingredient"),
                attribute.value(ing.name),
                attribute.class("form-control"),
                attribute.required(True),
              ]),
            ]),
            html.div([attribute.class("form-group")], [
              html.input([
                attribute.type_("text"),
                attribute.name("ingredient_quantity_" <> int.to_string(idx)),
                attribute.placeholder("Quantity"),
                attribute.value(ing.quantity),
                attribute.class("form-control"),
                attribute.required(True),
              ]),
            ]),
          ])
        })
    }),
    html.button(
      [
        attribute.type_("button"),
        attribute.class("btn btn-secondary"),
        attribute.attribute("onclick", "addIngredient()"),
      ],
      [element.text("+ Add Ingredient")],
    ),
  ])
}

fn render_instructions_section(
  instructions: List(String),
  count: Int,
) -> element.Element(Nil) {
  html.div([attribute.class("form-section")], [
    html.h2([], [element.text("Instructions")]),
    html.div(
      [attribute.id("instructions-list")],
      case list.length(instructions) {
        0 -> [instruction_input_row(0)]
        _ ->
          list.index_map(instructions, fn(inst, idx) {
            html.div([attribute.class("form-group instruction-row")], [
              html.textarea(
                [
                  attribute.name("instruction_" <> int.to_string(idx)),
                  attribute.attribute("rows", "2"),
                  attribute.placeholder("Step " <> int.to_string(idx + 1)),
                  attribute.class("form-control"),
                  attribute.required(True),
                ],
                inst,
              ),
            ])
          })
      },
    ),
    html.button(
      [
        attribute.type_("button"),
        attribute.class("btn btn-secondary"),
        attribute.attribute("onclick", "addInstruction()"),
      ],
      [element.text("+ Add Step")],
    ),
  ])
}

fn ingredient_input_row(index: Int) -> element.Element(Nil) {
  html.div([attribute.class("form-row ingredient-row")], [
    html.div([attribute.class("form-group")], [
      html.input([
        attribute.type_("text"),
        attribute.name("ingredient_name_" <> int.to_string(index)),
        attribute.placeholder("Ingredient"),
        attribute.class("form-control"),
        attribute.required(True),
      ]),
    ]),
    html.div([attribute.class("form-group")], [
      html.input([
        attribute.type_("text"),
        attribute.name("ingredient_quantity_" <> int.to_string(index)),
        attribute.placeholder("Quantity"),
        attribute.class("form-control"),
        attribute.required(True),
      ]),
    ]),
  ])
}

fn instruction_input_row(index: Int) -> element.Element(Nil) {
  html.div([attribute.class("form-group instruction-row")], [
    html.textarea(
      [
        attribute.name("instruction_" <> int.to_string(index)),
        attribute.attribute("rows", "2"),
        attribute.placeholder("Step " <> int.to_string(index + 1)),
        attribute.class("form-control"),
        attribute.required(True),
      ],
      "",
    ),
  ])
}

fn category_option(
  value: String,
  label: String,
  current: String,
) -> element.Element(Nil) {
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
) -> element.Element(Nil) {
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

// ============================================================================
// Helper Functions - Food Pages
// ============================================================================

fn parse_food_filters(
  parsed_query: Result(List(#(String, String)), Nil),
) -> SearchFilters {
  case parsed_query {
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

fn render_foods_search_fragment(
  query: option.Option(String),
  foods: List(storage.UsdaFood),
) -> wisp.Response {
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

  wisp.html_response(element.to_string(results_html), 200)
}

fn render_foods_full_page(
  query: option.Option(String),
  foods: List(storage.UsdaFood),
  ctx: Context,
  _filters: SearchFilters,
) -> wisp.Response {
  let food_count = utilities.get_foods_count(ctx.db)

  let content = [
    html.div([attribute.class("page-header")], [
      html.h1([], [element.text("Food Search")]),
      html.p([attribute.class("subtitle")], [
        element.text("Search " <> int.to_string(food_count) <> " USDA foods"),
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
          [element.text("Search")],
        ),
      ]),
    ]),
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
    html.div([attribute.id("food-log-modal"), attribute.class("modal")], []),
  ]

  wisp.html_response(render_page("Food Search - Meal Planner", content), 200)
}

fn food_row(food: storage.UsdaFood) -> element.Element(Nil) {
  html.a(
    [
      attribute.class("food-item"),
      attribute.href("/foods/" <> int.to_string(food.fdc_id)),
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

fn nutrient_row(n: storage.FoodNutrientValue) -> element.Element(Nil) {
  html.tr([], [
    html.td([], [element.text(n.nutrient_name)]),
    html.td([], [element.text(float.to_string(n.amount) <> " " <> n.unit)]),
  ])
}

// ============================================================================
// Helper Functions - Weekly Calendar
// ============================================================================

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

fn render_day_column(day_name: String) -> element.Element(Nil) {
  html.article([attribute.class("day-column")], [
    html.h3([attribute.class("day-name")], [element.text(day_name)]),
    render_meal_slot("Breakfast"),
    render_meal_slot("Lunch"),
    render_meal_slot("Dinner"),
  ])
}

fn render_meal_slot(meal_type: String) -> element.Element(Nil) {
  html.div([attribute.class("meal-slot")], [
    html.div([attribute.class("meal-type")], [element.text(meal_type)]),
    html.div([attribute.class("meal-content empty")], [
      element.text("No meals planned"),
    ]),
  ])
}

// ============================================================================
// Helper Functions - Components
// ============================================================================

fn page_header(title: String, back_href: String) -> element.Element(Nil) {
  html.header([attribute.class("page-header")], [
    html.a([attribute.href(back_href), attribute.class("back-link")], [
      element.text("←"),
    ]),
    html.h1([], [element.text(title)]),
  ])
}

fn recipe_card(recipe: Recipe) -> element.Element(Nil) {
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
          element.text(float.to_string(calories) <> " cal"),
        ]),
      ]),
    ],
  )
}

fn macro_badge(label: String, value: Float) -> element.Element(Nil) {
  html.span([attribute.class("macro-badge")], [
    element.text(label <> ": " <> float.to_string(value) <> "g"),
  ])
}

fn macro_stat_block(label: String, value: String) -> element.Element(Nil) {
  html.div([attribute.class("macro-stat")], [
    html.span([attribute.class("macro-value")], [element.text(value)]),
    html.span([attribute.class("macro-name")], [element.text(label)]),
  ])
}

fn activity_level_to_string(profile: UserProfile) -> String {
  case profile.activity_level {
    types.Sedentary -> "Sedentary"
    types.Moderate -> "Moderate"
    types.Active -> "Active"
  }
}

fn goal_to_string(profile: UserProfile) -> String {
  case profile.goal {
    types.Gain -> "Gain"
    types.Maintain -> "Maintain"
    types.Lose -> "Lose"
  }
}

// ============================================================================
// Page Template
// ============================================================================

fn render_page(title: String, content: List(element.Element(Nil))) -> String {
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
        // Include lazy loading and skeleton styles
        html.link([
          attribute.rel("stylesheet"),
          attribute.href("/static/css/lazy-loading.css"),
        ]),
        html.script([attribute.src("https://unpkg.com/htmx.org@1.9.10")], ""),
      ]),
      html.body([], [html.div([attribute.class("container")], content)]),
    ])

  "<!DOCTYPE html>" <> element.to_string(body)
}
