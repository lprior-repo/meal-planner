import * as $lustre from "../../lustre/lustre.mjs";
import * as $attribute from "../../lustre/lustre/attribute.mjs";
import * as $effect from "../../lustre/lustre/effect.mjs";
import * as $element from "../../lustre/lustre/element.mjs";
import * as $html from "../../lustre/lustre/element/html.mjs";
import * as $event from "../../lustre/lustre/event.mjs";
import * as $types from "../../shared/shared/types.mjs";
import { floatToString as float_to_string } from "../ffi.mjs";
import {
  Ok,
  Error,
  toList,
  Empty as $Empty,
  prepend as listPrepend,
  CustomType as $CustomType,
  makeError,
  divideFloat,
  isEqual,
} from "../gleam.mjs";

const FILEPATH = "src/client/app.gleam";

export class Home extends $CustomType {}
export const Route$Home = () => new Home();
export const Route$isHome = (value) => value instanceof Home;

export class Dashboard extends $CustomType {}
export const Route$Dashboard = () => new Dashboard();
export const Route$isDashboard = (value) => value instanceof Dashboard;

export class Recipes extends $CustomType {}
export const Route$Recipes = () => new Recipes();
export const Route$isRecipes = (value) => value instanceof Recipes;

export class RecipeDetail extends $CustomType {
  constructor(id) {
    super();
    this.id = id;
  }
}
export const Route$RecipeDetail = (id) => new RecipeDetail(id);
export const Route$isRecipeDetail = (value) => value instanceof RecipeDetail;
export const Route$RecipeDetail$id = (value) => value.id;
export const Route$RecipeDetail$0 = (value) => value.id;

export class Profile extends $CustomType {}
export const Route$Profile = () => new Profile();
export const Route$isProfile = (value) => value instanceof Profile;

export class NotFound extends $CustomType {}
export const Route$NotFound = () => new NotFound();
export const Route$isNotFound = (value) => value instanceof NotFound;

export class Model extends $CustomType {
  constructor(route, user_profile, daily_log, recipes, loading, error) {
    super();
    this.route = route;
    this.user_profile = user_profile;
    this.daily_log = daily_log;
    this.recipes = recipes;
    this.loading = loading;
    this.error = error;
  }
}
export const Model$Model = (route, user_profile, daily_log, recipes, loading, error) =>
  new Model(route, user_profile, daily_log, recipes, loading, error);
export const Model$isModel = (value) => value instanceof Model;
export const Model$Model$route = (value) => value.route;
export const Model$Model$0 = (value) => value.route;
export const Model$Model$user_profile = (value) => value.user_profile;
export const Model$Model$1 = (value) => value.user_profile;
export const Model$Model$daily_log = (value) => value.daily_log;
export const Model$Model$2 = (value) => value.daily_log;
export const Model$Model$recipes = (value) => value.recipes;
export const Model$Model$3 = (value) => value.recipes;
export const Model$Model$loading = (value) => value.loading;
export const Model$Model$4 = (value) => value.loading;
export const Model$Model$error = (value) => value.error;
export const Model$Model$5 = (value) => value.error;

export class NavigateTo extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Msg$NavigateTo = ($0) => new NavigateTo($0);
export const Msg$isNavigateTo = (value) => value instanceof NavigateTo;
export const Msg$NavigateTo$0 = (value) => value[0];

export class RecipesLoaded extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Msg$RecipesLoaded = ($0) => new RecipesLoaded($0);
export const Msg$isRecipesLoaded = (value) => value instanceof RecipesLoaded;
export const Msg$RecipesLoaded$0 = (value) => value[0];

export class DailyLogLoaded extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Msg$DailyLogLoaded = ($0) => new DailyLogLoaded($0);
export const Msg$isDailyLogLoaded = (value) => value instanceof DailyLogLoaded;
export const Msg$DailyLogLoaded$0 = (value) => value[0];

export class LoadError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Msg$LoadError = ($0) => new LoadError($0);
export const Msg$isLoadError = (value) => value instanceof LoadError;
export const Msg$LoadError$0 = (value) => value[0];

export class LogFood extends $CustomType {
  constructor(recipe_id, servings, meal_type) {
    super();
    this.recipe_id = recipe_id;
    this.servings = servings;
    this.meal_type = meal_type;
  }
}
export const Msg$LogFood = (recipe_id, servings, meal_type) =>
  new LogFood(recipe_id, servings, meal_type);
export const Msg$isLogFood = (value) => value instanceof LogFood;
export const Msg$LogFood$recipe_id = (value) => value.recipe_id;
export const Msg$LogFood$0 = (value) => value.recipe_id;
export const Msg$LogFood$servings = (value) => value.servings;
export const Msg$LogFood$1 = (value) => value.servings;
export const Msg$LogFood$meal_type = (value) => value.meal_type;
export const Msg$LogFood$2 = (value) => value.meal_type;

export class RemoveLogEntry extends $CustomType {
  constructor(entry_id) {
    super();
    this.entry_id = entry_id;
  }
}
export const Msg$RemoveLogEntry = (entry_id) => new RemoveLogEntry(entry_id);
export const Msg$isRemoveLogEntry = (value) => value instanceof RemoveLogEntry;
export const Msg$RemoveLogEntry$entry_id = (value) => value.entry_id;
export const Msg$RemoveLogEntry$0 = (value) => value.entry_id;

export class UpdateBodyweight extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Msg$UpdateBodyweight = ($0) => new UpdateBodyweight($0);
export const Msg$isUpdateBodyweight = (value) =>
  value instanceof UpdateBodyweight;
export const Msg$UpdateBodyweight$0 = (value) => value[0];

export class UpdateActivityLevel extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Msg$UpdateActivityLevel = ($0) => new UpdateActivityLevel($0);
export const Msg$isUpdateActivityLevel = (value) =>
  value instanceof UpdateActivityLevel;
export const Msg$UpdateActivityLevel$0 = (value) => value[0];

export class UpdateGoal extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Msg$UpdateGoal = ($0) => new UpdateGoal($0);
export const Msg$isUpdateGoal = (value) => value instanceof UpdateGoal;
export const Msg$UpdateGoal$0 = (value) => value[0];

function init(_) {
  let default_profile = new $types.UserProfile(
    "user-1",
    180.0,
    new $types.Moderate(),
    new $types.Maintain(),
    3,
  );
  let empty_log = new $types.DailyLog(
    "2024-01-01",
    toList([]),
    $types.macros_zero(),
  );
  let model = new Model(
    new Home(),
    default_profile,
    empty_log,
    toList([]),
    true,
    "",
  );
  return [model, $effect.none()];
}

function update(model, msg) {
  if (msg instanceof NavigateTo) {
    let route = msg[0];
    return [
      new Model(
        route,
        model.user_profile,
        model.daily_log,
        model.recipes,
        model.loading,
        model.error,
      ),
      $effect.none(),
    ];
  } else if (msg instanceof RecipesLoaded) {
    let recipes = msg[0];
    return [
      new Model(
        model.route,
        model.user_profile,
        model.daily_log,
        recipes,
        false,
        model.error,
      ),
      $effect.none(),
    ];
  } else if (msg instanceof DailyLogLoaded) {
    let log = msg[0];
    return [
      new Model(
        model.route,
        model.user_profile,
        log,
        model.recipes,
        false,
        model.error,
      ),
      $effect.none(),
    ];
  } else if (msg instanceof LoadError) {
    let err = msg[0];
    return [
      new Model(
        model.route,
        model.user_profile,
        model.daily_log,
        model.recipes,
        false,
        err,
      ),
      $effect.none(),
    ];
  } else if (msg instanceof LogFood) {
    return [model, $effect.none()];
  } else if (msg instanceof RemoveLogEntry) {
    return [model, $effect.none()];
  } else if (msg instanceof UpdateBodyweight) {
    let weight = msg[0];
    let _block;
    let _record = model.user_profile;
    _block = new $types.UserProfile(
      _record.id,
      weight,
      _record.activity_level,
      _record.goal,
      _record.meals_per_day,
    );
    let profile = _block;
    return [
      new Model(
        model.route,
        profile,
        model.daily_log,
        model.recipes,
        model.loading,
        model.error,
      ),
      $effect.none(),
    ];
  } else if (msg instanceof UpdateActivityLevel) {
    let level = msg[0];
    let _block;
    let _record = model.user_profile;
    _block = new $types.UserProfile(
      _record.id,
      _record.bodyweight,
      level,
      _record.goal,
      _record.meals_per_day,
    );
    let profile = _block;
    return [
      new Model(
        model.route,
        profile,
        model.daily_log,
        model.recipes,
        model.loading,
        model.error,
      ),
      $effect.none(),
    ];
  } else {
    let goal = msg[0];
    let _block;
    let _record = model.user_profile;
    _block = new $types.UserProfile(
      _record.id,
      _record.bodyweight,
      _record.activity_level,
      goal,
      _record.meals_per_day,
    );
    let profile = _block;
    return [
      new Model(
        model.route,
        profile,
        model.daily_log,
        model.recipes,
        model.loading,
        model.error,
      ),
      $effect.none(),
    ];
  }
}

function nav_link(label, route, current) {
  let _block;
  let $ = isEqual(route, current);
  if ($) {
    _block = "nav-link active";
  } else {
    _block = "nav-link";
  }
  let class$ = _block;
  return $html.a(
    toList([
      $attribute.class$(class$),
      $attribute.href("#"),
      $event.on_click(new NavigateTo(route)),
    ]),
    toList([$element.text(label)]),
  );
}

function view_nav(current) {
  return $html.nav(
    toList([$attribute.class$("nav")]),
    toList([
      nav_link("Home", new Home(), current),
      nav_link("Dashboard", new Dashboard(), current),
      nav_link("Recipes", new Recipes(), current),
      nav_link("Profile", new Profile(), current),
    ]),
  );
}

function view_header(model) {
  return $html.header(
    toList([$attribute.class$("header")]),
    toList([
      $html.h1(toList([]), toList([$element.text("Meal Planner")])),
      view_nav(model.route),
    ]),
  );
}

function view_home() {
  return $html.div(
    toList([$attribute.class$("home")]),
    toList([
      $html.h2(toList([]), toList([$element.text("Welcome to Meal Planner")])),
      $html.p(
        toList([]),
        toList([$element.text("Track your nutrition and reach your goals.")]),
      ),
      $html.button(
        toList([
          $attribute.class$("btn btn-primary"),
          $event.on_click(new NavigateTo(new Dashboard())),
        ]),
        toList([$element.text("Go to Dashboard")]),
      ),
    ]),
  );
}

function view_not_found() {
  return $html.div(
    toList([$attribute.class$("not-found")]),
    toList([
      $html.h2(toList([]), toList([$element.text("Page Not Found")])),
      $html.button(
        toList([
          $attribute.class$("btn"),
          $event.on_click(new NavigateTo(new Home())),
        ]),
        toList([$element.text("Go Home")]),
      ),
    ]),
  );
}

function view_footer() {
  return $html.footer(
    toList([$attribute.class$("footer")]),
    toList([
      $html.p(
        toList([]),
        toList([$element.text("Meal Planner - Track your nutrition")]),
      ),
    ]),
  );
}

function find_recipe(loop$recipes, loop$id) {
  while (true) {
    let recipes = loop$recipes;
    let id = loop$id;
    if (recipes instanceof $Empty) {
      return new Error(undefined);
    } else {
      let first = recipes.head;
      let rest = recipes.tail;
      let $ = first.id === id;
      if ($) {
        return new Ok(first);
      } else {
        loop$recipes = rest;
        loop$id = id;
      }
    }
  }
}

function list_map(items, f) {
  if (items instanceof $Empty) {
    return items;
  } else {
    let first = items.head;
    let rest = items.tail;
    return listPrepend(f(first), list_map(rest, f));
  }
}

function view_recipes(recipes) {
  return $html.div(
    toList([$attribute.class$("recipes")]),
    toList([
      $html.h2(toList([]), toList([$element.text("Recipes")])),
      $html.ul(
        toList([$attribute.class$("recipe-list")]),
        list_map(
          recipes,
          (recipe) => {
            return $html.li(
              toList([$attribute.class$("recipe-item")]),
              toList([
                $html.a(
                  toList([
                    $attribute.href("#"),
                    $event.on_click(new NavigateTo(new RecipeDetail(recipe.id))),
                  ]),
                  toList([$element.text(recipe.name)]),
                ),
                $html.span(
                  toList([$attribute.class$("category")]),
                  toList([$element.text(recipe.category)]),
                ),
              ]),
            );
          },
        ),
      ),
    ]),
  );
}

function view_macro_progress(label, current, target) {
  let _block;
  let $ = target > 0.0;
  if ($) {
    _block = (divideFloat(current, target)) * 100.0;
  } else {
    _block = 0.0;
  }
  let percent = _block;
  let _block$1;
  let $1 = percent > 100.0;
  if ($1) {
    _block$1 = 100.0;
  } else {
    _block$1 = percent;
  }
  let percent_capped = _block$1;
  return $html.div(
    toList([$attribute.class$("macro-progress")]),
    toList([
      $html.div(
        toList([$attribute.class$("macro-label")]),
        toList([
          $html.span(toList([]), toList([$element.text(label)])),
          $html.span(
            toList([]),
            toList([
              $element.text(
                (float_to_string(current) + " / ") + float_to_string(target),
              ),
            ]),
          ),
        ]),
      ),
      $html.div(
        toList([$attribute.class$("progress-bar")]),
        toList([
          $html.div(
            toList([
              $attribute.class$("progress-fill"),
              $attribute.style("width", float_to_string(percent_capped) + "%"),
            ]),
            toList([]),
          ),
        ]),
      ),
    ]),
  );
}

function view_dashboard(model) {
  let targets = $types.daily_macro_targets(model.user_profile);
  let current = model.daily_log.total_macros;
  return $html.div(
    toList([$attribute.class$("dashboard")]),
    toList([
      $html.h2(toList([]), toList([$element.text("Nutrition Dashboard")])),
      view_macro_progress(
        "Calories",
        $types.macros_calories(current),
        $types.macros_calories(targets),
      ),
      view_macro_progress("Protein", current.protein, targets.protein),
      view_macro_progress("Fat", current.fat, targets.fat),
      view_macro_progress("Carbs", current.carbs, targets.carbs),
    ]),
  );
}

function view_recipe_detail(recipes, id) {
  let $ = find_recipe(recipes, id);
  if ($ instanceof Ok) {
    let recipe = $[0];
    return $html.div(
      toList([$attribute.class$("recipe-detail")]),
      toList([
        $html.h2(toList([]), toList([$element.text(recipe.name)])),
        $html.p(
          toList([]),
          toList([$element.text("Category: " + recipe.category)]),
        ),
        $html.h3(toList([]), toList([$element.text("Macros per serving")])),
        $html.ul(
          toList([]),
          toList([
            $html.li(
              toList([]),
              toList([
                $element.text(
                  ("Protein: " + float_to_string(recipe.macros.protein)) + "g",
                ),
              ]),
            ),
            $html.li(
              toList([]),
              toList([
                $element.text(
                  ("Fat: " + float_to_string(recipe.macros.fat)) + "g",
                ),
              ]),
            ),
            $html.li(
              toList([]),
              toList([
                $element.text(
                  ("Carbs: " + float_to_string(recipe.macros.carbs)) + "g",
                ),
              ]),
            ),
            $html.li(
              toList([]),
              toList([
                $element.text(
                  "Calories: " + float_to_string(
                    $types.macros_calories(recipe.macros),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        $html.button(
          toList([
            $attribute.class$("btn"),
            $event.on_click(new NavigateTo(new Recipes())),
          ]),
          toList([$element.text("Back to Recipes")]),
        ),
      ]),
    );
  } else {
    return view_not_found();
  }
}

function view_profile(profile) {
  return $html.div(
    toList([$attribute.class$("profile")]),
    toList([
      $html.h2(toList([]), toList([$element.text("Profile")])),
      $html.p(
        toList([]),
        toList([
          $element.text(
            ("Bodyweight: " + float_to_string(profile.bodyweight)) + " lbs",
          ),
        ]),
      ),
      $html.p(
        toList([]),
        toList([
          $element.text(
            "Activity: " + $types.activity_level_to_string(
              profile.activity_level,
            ),
          ),
        ]),
      ),
      $html.p(
        toList([]),
        toList([$element.text("Goal: " + $types.goal_to_string(profile.goal))]),
      ),
    ]),
  );
}

function view_route(model) {
  let $ = model.route;
  if ($ instanceof Home) {
    return view_home();
  } else if ($ instanceof Dashboard) {
    return view_dashboard(model);
  } else if ($ instanceof Recipes) {
    return view_recipes(model.recipes);
  } else if ($ instanceof RecipeDetail) {
    let id = $.id;
    return view_recipe_detail(model.recipes, id);
  } else if ($ instanceof Profile) {
    return view_profile(model.user_profile);
  } else {
    return view_not_found();
  }
}

function view_main(model) {
  return $html.main(
    toList([$attribute.class$("main")]),
    toList([
      (() => {
        let $ = model.loading;
        if ($) {
          return $html.p(toList([]), toList([$element.text("Loading...")]));
        } else {
          let $1 = model.error;
          if ($1 === "") {
            return view_route(model);
          } else {
            let err = $1;
            return $html.p(
              toList([$attribute.class$("error")]),
              toList([$element.text(err)]),
            );
          }
        }
      })(),
    ]),
  );
}

function view(model) {
  return $html.div(
    toList([$attribute.class$("app")]),
    toList([view_header(model), view_main(model), view_footer()]),
  );
}

export function main() {
  let app = $lustre.application(init, update, view);
  let $ = $lustre.start(app, "#app", undefined);
  if (!($ instanceof Ok)) {
    throw makeError(
      "let_assert",
      FILEPATH,
      "client/app",
      339,
      "main",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 9953,
        end: 10002,
        pattern_start: 9964,
        pattern_end: 9969
      }
    )
  }
  return undefined;
}
