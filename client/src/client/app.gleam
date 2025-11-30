//// Lustre SPA entry point for meal planner nutrition tracking

import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/attribute
import lustre/event
import shared/types.{type UserProfile, type DailyLog}

// ============================================================================
// Model
// ============================================================================

pub type Route {
  Home
  Dashboard
  Recipes
  RecipeDetail(id: String)
  Profile
  NotFound
}

pub type Model {
  Model(
    route: Route,
    user_profile: UserProfile,
    daily_log: DailyLog,
    recipes: List(types.Recipe),
    loading: Bool,
    error: String,
  )
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let default_profile = types.UserProfile(
    id: "user-1",
    bodyweight: 180.0,
    activity_level: types.Moderate,
    goal: types.Maintain,
    meals_per_day: 3,
  )
  
  let empty_log = types.DailyLog(
    date: "2024-01-01",
    entries: [],
    total_macros: types.macros_zero(),
  )
  
  let model = Model(
    route: Home,
    user_profile: default_profile,
    daily_log: empty_log,
    recipes: [],
    loading: False,
    error: "",
  )
  
  #(model, effect.none())
}

// ============================================================================
// Messages
// ============================================================================

pub type Msg {
  // Navigation
  NavigateTo(Route)
  
  // Data loading
  RecipesLoaded(List(types.Recipe))
  DailyLogLoaded(DailyLog)
  LoadError(String)
  
  // Food logging
  LogFood(recipe_id: String, servings: Float, meal_type: types.MealType)
  RemoveLogEntry(entry_id: String)
  
  // Profile updates
  UpdateBodyweight(Float)
  UpdateActivityLevel(types.ActivityLevel)
  UpdateGoal(types.Goal)
}

// ============================================================================
// Update
// ============================================================================

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NavigateTo(route) -> #(Model(..model, route: route), effect.none())
    
    RecipesLoaded(recipes) -> #(
      Model(..model, recipes: recipes, loading: False),
      effect.none(),
    )
    
    DailyLogLoaded(log) -> #(
      Model(..model, daily_log: log, loading: False),
      effect.none(),
    )
    
    LoadError(err) -> #(
      Model(..model, error: err, loading: False),
      effect.none(),
    )
    
    LogFood(_recipe_id, _servings, _meal_type) -> {
      // TODO: Implement food logging
      #(model, effect.none())
    }
    
    RemoveLogEntry(_entry_id) -> {
      // TODO: Implement entry removal
      #(model, effect.none())
    }
    
    UpdateBodyweight(weight) -> {
      let profile = types.UserProfile(..model.user_profile, bodyweight: weight)
      #(Model(..model, user_profile: profile), effect.none())
    }
    
    UpdateActivityLevel(level) -> {
      let profile = types.UserProfile(..model.user_profile, activity_level: level)
      #(Model(..model, user_profile: profile), effect.none())
    }
    
    UpdateGoal(goal) -> {
      let profile = types.UserProfile(..model.user_profile, goal: goal)
      #(Model(..model, user_profile: profile), effect.none())
    }
  }
}

// ============================================================================
// View
// ============================================================================

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    view_header(model),
    view_main(model),
    view_footer(),
  ])
}

fn view_header(model: Model) -> Element(Msg) {
  html.header([attribute.class("header")], [
    html.h1([], [element.text("Meal Planner")]),
    view_nav(model.route),
  ])
}

fn view_nav(current: Route) -> Element(Msg) {
  html.nav([attribute.class("nav")], [
    nav_link("Home", Home, current),
    nav_link("Dashboard", Dashboard, current),
    nav_link("Recipes", Recipes, current),
    nav_link("Profile", Profile, current),
  ])
}

fn nav_link(label: String, route: Route, current: Route) -> Element(Msg) {
  let class = case route == current {
    True -> "nav-link active"
    False -> "nav-link"
  }
  html.a([
    attribute.class(class),
    attribute.href("#"),
    event.on_click(NavigateTo(route)),
  ], [element.text(label)])
}

fn view_main(model: Model) -> Element(Msg) {
  html.main([attribute.class("main")], [
    case model.loading {
      True -> html.p([], [element.text("Loading...")])
      False -> case model.error {
        "" -> view_route(model)
        err -> html.p([attribute.class("error")], [element.text(err)])
      }
    }
  ])
}

fn view_route(model: Model) -> Element(Msg) {
  case model.route {
    Home -> view_home()
    Dashboard -> view_dashboard(model)
    Recipes -> view_recipes(model.recipes)
    RecipeDetail(id) -> view_recipe_detail(model.recipes, id)
    Profile -> view_profile(model.user_profile)
    NotFound -> view_not_found()
  }
}

fn view_home() -> Element(Msg) {
  html.div([attribute.class("home")], [
    html.h2([], [element.text("Welcome to Meal Planner")]),
    html.p([], [element.text("Track your nutrition and reach your goals.")]),
    html.button([
      attribute.class("btn btn-primary"),
      event.on_click(NavigateTo(Dashboard)),
    ], [element.text("Go to Dashboard")]),
  ])
}

fn view_dashboard(model: Model) -> Element(Msg) {
  let targets = types.daily_macro_targets(model.user_profile)
  let current = model.daily_log.total_macros
  
  html.div([attribute.class("dashboard")], [
    html.h2([], [element.text("Nutrition Dashboard")]),
    view_macro_progress("Calories", types.macros_calories(current), types.macros_calories(targets)),
    view_macro_progress("Protein", current.protein, targets.protein),
    view_macro_progress("Fat", current.fat, targets.fat),
    view_macro_progress("Carbs", current.carbs, targets.carbs),
  ])
}

fn view_macro_progress(label: String, current: Float, target: Float) -> Element(Msg) {
  let percent = case target >. 0.0 {
    True -> { current /. target } *. 100.0
    False -> 0.0
  }
  let percent_capped = case percent >. 100.0 {
    True -> 100.0
    False -> percent
  }
  
  html.div([attribute.class("macro-progress")], [
    html.div([attribute.class("macro-label")], [
      html.span([], [element.text(label)]),
      html.span([], [element.text(float_to_string(current) <> " / " <> float_to_string(target))]),
    ]),
    html.div([attribute.class("progress-bar")], [
      html.div([
        attribute.class("progress-fill"),
        attribute.style("width", float_to_string(percent_capped) <> "%"),
      ], []),
    ]),
  ])
}

fn view_recipes(recipes: List(types.Recipe)) -> Element(Msg) {
  html.div([attribute.class("recipes")], [
    html.h2([], [element.text("Recipes")]),
    html.ul([attribute.class("recipe-list")],
      list_map(recipes, fn(recipe) {
        html.li([attribute.class("recipe-item")], [
          html.a([
            attribute.href("#"),
            event.on_click(NavigateTo(RecipeDetail(recipe.id))),
          ], [element.text(recipe.name)]),
          html.span([attribute.class("category")], [element.text(recipe.category)]),
        ])
      })
    ),
  ])
}

fn view_recipe_detail(recipes: List(types.Recipe), id: String) -> Element(Msg) {
  case find_recipe(recipes, id) {
    Ok(recipe) -> html.div([attribute.class("recipe-detail")], [
      html.h2([], [element.text(recipe.name)]),
      html.p([], [element.text("Category: " <> recipe.category)]),
      html.h3([], [element.text("Macros per serving")]),
      html.ul([], [
        html.li([], [element.text("Protein: " <> float_to_string(recipe.macros.protein) <> "g")]),
        html.li([], [element.text("Fat: " <> float_to_string(recipe.macros.fat) <> "g")]),
        html.li([], [element.text("Carbs: " <> float_to_string(recipe.macros.carbs) <> "g")]),
        html.li([], [element.text("Calories: " <> float_to_string(types.macros_calories(recipe.macros)))]),
      ]),
      html.button([
        attribute.class("btn"),
        event.on_click(NavigateTo(Recipes)),
      ], [element.text("Back to Recipes")]),
    ])
    Error(_) -> view_not_found()
  }
}

fn view_profile(profile: UserProfile) -> Element(Msg) {
  html.div([attribute.class("profile")], [
    html.h2([], [element.text("Profile")]),
    html.p([], [element.text("Bodyweight: " <> float_to_string(profile.bodyweight) <> " lbs")]),
    html.p([], [element.text("Activity: " <> types.activity_level_to_string(profile.activity_level))]),
    html.p([], [element.text("Goal: " <> types.goal_to_string(profile.goal))]),
  ])
}

fn view_not_found() -> Element(Msg) {
  html.div([attribute.class("not-found")], [
    html.h2([], [element.text("Page Not Found")]),
    html.button([
      attribute.class("btn"),
      event.on_click(NavigateTo(Home)),
    ], [element.text("Go Home")]),
  ])
}

fn view_footer() -> Element(Msg) {
  html.footer([attribute.class("footer")], [
    html.p([], [element.text("Meal Planner - Track your nutrition")]),
  ])
}

// ============================================================================
// Helpers
// ============================================================================

fn find_recipe(recipes: List(types.Recipe), id: String) -> Result(types.Recipe, Nil) {
  case recipes {
    [] -> Error(Nil)
    [first, ..rest] -> case first.id == id {
      True -> Ok(first)
      False -> find_recipe(rest, id)
    }
  }
}

fn list_map(items: List(a), f: fn(a) -> b) -> List(b) {
  case items {
    [] -> []
    [first, ..rest] -> [f(first), ..list_map(rest, f)]
  }
}

@external(javascript, "../ffi.mjs", "floatToString")
fn float_to_string(f: Float) -> String

// ============================================================================
// Main
// ============================================================================

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
