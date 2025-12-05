// Recipe Form UI Component
// Accessible, responsive form with dynamic rows and validation

import gleam/int
import lustre/attribute.{
  attribute, class, id, max, maxlength, min, minlength, name, placeholder, step,
  type_, value,
}
import lustre/element.{type Element, text}
import lustre/element/html.{
  button, div, form, h1, h2, input, label, option, p, section, select, span,
  textarea,
}
import meal_planner/nutrition_constants

/// Generate the complete recipe creation form HTML
pub fn render_form() -> Element(msg) {
  div([class("container max-w-prose")], [
    form([id("recipe-form"), class("card"), attribute("novalidate", "")], [
      form_header(),
      div([class("card-body")], [
        basic_info_section(),
        ingredients_section(),
        instructions_section(),
        nutrition_section(),
      ]),
      form_actions(),
    ]),
  ])
}

fn form_header() -> Element(msg) {
  div([class("card-header")], [
    h1([], [text("Create Recipe")]),
    p([class("text-secondary")], [
      text("Build a custom recipe with ingredients and instructions"),
    ]),
  ])
}

fn basic_info_section() -> Element(msg) {
  section([class("mb-6")], [
    h2([class("text-xl font-semibold mb-4")], [text("Basic Information")]),
    // Recipe name field
    div([class("form-group")], [
      label([attribute("for", "recipe-name"), class("required")], [
        text("Recipe Name"),
        span([class("text-danger"), attribute("aria-label", "required")], [
          text("*"),
        ]),
      ]),
      input([
        type_("text"),
        id("recipe-name"),
        name("name"),
        class("input"),
        placeholder("e.g., Grilled Chicken Salad"),
        attribute("required", ""),
        minlength(nutrition_constants.min_recipe_name_length),
        maxlength(nutrition_constants.max_recipe_name_length),
        attribute("aria-describedby", "name-error"),
        attribute("aria-invalid", "false"),
      ]),
      span(
        [
          id("name-error"),
          class("form-error"),
          attribute("role", "alert"),
          attribute("aria-live", "polite"),
        ],
        [],
      ),
    ]),
    // Category field
    div([class("form-group")], [
      label([attribute("for", "recipe-category"), class("required")], [
        text("Category"),
        span([class("text-danger"), attribute("aria-label", "required")], [
          text("*"),
        ]),
      ]),
      select(
        [
          id("recipe-category"),
          name("category"),
          class("input"),
          attribute("required", ""),
          attribute("aria-describedby", "category-error"),
          attribute("aria-invalid", "false"),
        ],
        [
          option([value("")], "Select a category"),
          option([value("breakfast")], "Breakfast"),
          option([value("lunch")], "Lunch"),
          option([value("dinner")], "Dinner"),
          option([value("snack")], "Snack"),
          option([value("dessert")], "Dessert"),
          option([value("beverage")], "Beverage"),
        ],
      ),
      span(
        [
          id("category-error"),
          class("form-error"),
          attribute("role", "alert"),
          attribute("aria-live", "polite"),
        ],
        [],
      ),
    ]),
    // Prep and cook times
    div([class("grid grid-cols-2 gap-4")], [
      div([class("form-group")], [
        label([attribute("for", "prep-time")], [text("Prep Time (min)")]),
        input([
          type_("number"),
          id("prep-time"),
          name("prep_time"),
          class("input"),
          min("0"),
          max(nutrition_constants.max_cooking_time |> int.to_string),
          placeholder("30"),
          attribute("aria-describedby", "prep-time-error"),
        ]),
        span(
          [
            id("prep-time-error"),
            class("form-error"),
            attribute("role", "alert"),
            attribute("aria-live", "polite"),
          ],
          [],
        ),
      ]),
      div([class("form-group")], [
        label([attribute("for", "cook-time")], [text("Cook Time (min)")]),
        input([
          type_("number"),
          id("cook-time"),
          name("cook_time"),
          class("input"),
          min("0"),
          max(nutrition_constants.max_cooking_time |> int.to_string),
          placeholder("45"),
          attribute("aria-describedby", "cook-time-error"),
        ]),
        span(
          [
            id("cook-time-error"),
            class("form-error"),
            attribute("role", "alert"),
            attribute("aria-live", "polite"),
          ],
          [],
        ),
      ]),
    ]),
    // Servings field
    div([class("form-group")], [
      label([attribute("for", "servings"), class("required")], [
        text("Servings"),
        span([class("text-danger"), attribute("aria-label", "required")], [
          text("*"),
        ]),
      ]),
      input([
        type_("number"),
        id("servings"),
        name("servings"),
        class("input"),
        min("1"),
        max(nutrition_constants.max_servings |> int.to_string),
        value(nutrition_constants.default_servings |> int.to_string),
        attribute("required", ""),
        attribute("aria-describedby", "servings-error"),
        attribute("aria-invalid", "false"),
      ]),
      span(
        [
          id("servings-error"),
          class("form-error"),
          attribute("role", "alert"),
          attribute("aria-live", "polite"),
        ],
        [],
      ),
    ]),
  ])
}

fn ingredients_section() -> Element(msg) {
  section([class("mb-6")], [
    div([class("flex justify-between items-center mb-4")], [
      h2([class("text-xl font-semibold")], [
        text("Ingredients"),
        span([class("text-danger"), attribute("aria-label", "required")], [
          text("*"),
        ]),
      ]),
      button(
        [
          type_("button"),
          id("add-ingredient"),
          class("btn btn-secondary btn-sm"),
          attribute("aria-label", "Add ingredient row"),
        ],
        [text("+ Add Ingredient")],
      ),
    ]),
    div(
      [
        id("ingredients-list"),
        attribute("role", "list"),
        attribute("aria-label", "Ingredient list"),
      ],
      [ingredient_row(0)],
    ),
    div(
      [
        id("ingredients-error"),
        class("form-error"),
        attribute("role", "alert"),
        attribute("aria-live", "polite"),
      ],
      [],
    ),
  ])
}

fn ingredient_row(index: Int) -> Element(msg) {
  let idx_str = index |> int.to_string

  div(
    [
      class("ingredient-row"),
      attribute("role", "listitem"),
      attribute("data-row-index", idx_str),
    ],
    [
      div([class("grid grid-cols-12 gap-2 mb-3")], [
        // Food item name
        div(
          [class("flex flex-col"), attribute("style", "grid-column: span 5;")],
          [
            label(
              [
                attribute("for", "ingredient-name-" <> idx_str),
                class("text-sm mb-1"),
              ],
              [
                text("Food Item"),
                span(
                  [class("text-danger"), attribute("aria-label", "required")],
                  [
                    text("*"),
                  ],
                ),
              ],
            ),
            input([
              type_("text"),
              id("ingredient-name-" <> idx_str),
              name("ingredients[" <> idx_str <> "][name]"),
              class("input ingredient-name"),
              placeholder("e.g., Chicken breast"),
              attribute("required", ""),
              attribute(
                "aria-describedby",
                "ingredient-name-" <> idx_str <> "-error",
              ),
              attribute("aria-invalid", "false"),
            ]),
            span(
              [
                id("ingredient-name-" <> idx_str <> "-error"),
                class("form-error"),
                attribute("role", "alert"),
              ],
              [],
            ),
          ],
        ),
        // Amount
        div(
          [class("flex flex-col"), attribute("style", "grid-column: span 3;")],
          [
            label(
              [
                attribute("for", "ingredient-amount-" <> idx_str),
                class("text-sm mb-1"),
              ],
              [
                text("Amount"),
                span(
                  [class("text-danger"), attribute("aria-label", "required")],
                  [
                    text("*"),
                  ],
                ),
              ],
            ),
            input([
              type_("number"),
              id("ingredient-amount-" <> idx_str),
              name("ingredients[" <> idx_str <> "][amount]"),
              class("input ingredient-amount"),
              placeholder(
                nutrition_constants.default_ingredient_amount |> int.to_string,
              ),
              min("0"),
              step("0.01"),
              attribute("required", ""),
              attribute(
                "aria-describedby",
                "ingredient-amount-" <> idx_str <> "-error",
              ),
              attribute("aria-invalid", "false"),
            ]),
            span(
              [
                id("ingredient-amount-" <> idx_str <> "-error"),
                class("form-error"),
                attribute("role", "alert"),
              ],
              [],
            ),
          ],
        ),
        // Unit
        div(
          [class("flex flex-col"), attribute("style", "grid-column: span 3;")],
          [
            label(
              [
                attribute("for", "ingredient-unit-" <> idx_str),
                class("text-sm mb-1"),
              ],
              [
                text("Unit"),
                span(
                  [class("text-danger"), attribute("aria-label", "required")],
                  [
                    text("*"),
                  ],
                ),
              ],
            ),
            select(
              [
                id("ingredient-unit-" <> idx_str),
                name("ingredients[" <> idx_str <> "][unit]"),
                class("input ingredient-unit"),
                attribute("required", ""),
                attribute(
                  "aria-describedby",
                  "ingredient-unit-" <> idx_str <> "-error",
                ),
                attribute("aria-invalid", "false"),
              ],
              [
                option([value("")], "Select"),
                option([value("g")], "g (grams)"),
                option([value("kg")], "kg (kilograms)"),
                option([value("ml")], "ml (milliliters)"),
                option([value("l")], "L (liters)"),
                option([value("cup")], "cup"),
                option([value("tbsp")], "tbsp (tablespoon)"),
                option([value("tsp")], "tsp (teaspoon)"),
                option([value("oz")], "oz (ounce)"),
                option([value("lb")], "lb (pound)"),
                option([value("piece")], "piece"),
              ],
            ),
            span(
              [
                id("ingredient-unit-" <> idx_str <> "-error"),
                class("form-error"),
                attribute("role", "alert"),
              ],
              [],
            ),
          ],
        ),
        // Remove button
        div(
          [class("flex items-end"), attribute("style", "grid-column: span 1;")],
          [
            button(
              [
                type_("button"),
                class("btn btn-danger btn-sm remove-ingredient"),
                attribute("aria-label", "Remove ingredient row"),
                attribute("disabled", ""),
              ],
              [text("×")],
            ),
          ],
        ),
      ]),
    ],
  )
}

fn instructions_section() -> Element(msg) {
  section([class("mb-6")], [
    div([class("flex justify-between items-center mb-4")], [
      h2([class("text-xl font-semibold")], [
        text("Instructions"),
        span([class("text-danger"), attribute("aria-label", "required")], [
          text("*"),
        ]),
      ]),
      button(
        [
          type_("button"),
          id("add-instruction"),
          class("btn btn-secondary btn-sm"),
          attribute("aria-label", "Add instruction step"),
        ],
        [text("+ Add Step")],
      ),
    ]),
    div(
      [
        id("instructions-list"),
        attribute("role", "list"),
        attribute("aria-label", "Instruction steps"),
      ],
      [instruction_row(0)],
    ),
    div(
      [
        id("instructions-error"),
        class("form-error"),
        attribute("role", "alert"),
        attribute("aria-live", "polite"),
      ],
      [],
    ),
  ])
}

fn instruction_row(index: Int) -> Element(msg) {
  let idx_str = index |> int.to_string
  let step_num = index + 1 |> int.to_string

  div(
    [
      class("instruction-row mb-3"),
      attribute("role", "listitem"),
      attribute("data-row-index", idx_str),
    ],
    [
      div([class("flex gap-2")], [
        div([class("flex-1")], [
          label(
            [
              attribute("for", "instruction-" <> idx_str),
              class("text-sm mb-1 flex items-center"),
            ],
            [
              span([class("badge badge-primary mr-2")], [
                text("Step " <> step_num),
              ]),
              text("Description"),
              span(
                [class("text-danger ml-1"), attribute("aria-label", "required")],
                [
                  text("*"),
                ],
              ),
            ],
          ),
          textarea(
            [
              id("instruction-" <> idx_str),
              name("instructions[" <> idx_str <> "]"),
              class("input instruction-text"),
              placeholder("e.g., Preheat oven to 375°F (190°C)"),
              attribute("required", ""),
              attribute("rows", "2"),
              attribute(
                "aria-describedby",
                "instruction-" <> idx_str <> "-error",
              ),
              attribute("aria-invalid", "false"),
            ],
            "",
          ),
          span(
            [
              id("instruction-" <> idx_str <> "-error"),
              class("form-error"),
              attribute("role", "alert"),
            ],
            [],
          ),
        ]),
        div([class("flex items-end pb-6")], [
          button(
            [
              type_("button"),
              class("btn btn-danger btn-sm remove-instruction"),
              attribute("aria-label", "Remove instruction step"),
              attribute("disabled", ""),
            ],
            [text("×")],
          ),
        ]),
      ]),
    ],
  )
}

fn nutrition_section() -> Element(msg) {
  section([class("mb-6")], [
    h2([class("text-xl font-semibold mb-4")], [
      text("Nutrition Information (per serving)"),
    ]),
    div([class("grid grid-cols-2 gap-4")], [
      nutrition_field(
        "calories",
        "Calories (kcal)",
        nutrition_constants.max_calories_per_serving |> int.to_string,
        "1",
        "e.g., 350",
      ),
      nutrition_field(
        "protein",
        "Protein (g)",
        nutrition_constants.max_macronutrient_grams |> int.to_string,
        "0.1",
        "e.g., 30",
      ),
      nutrition_field(
        "carbs",
        "Carbohydrates (g)",
        nutrition_constants.max_macronutrient_grams |> int.to_string,
        "0.1",
        "e.g., 25",
      ),
      nutrition_field(
        "fat",
        "Fat (g)",
        nutrition_constants.max_macronutrient_grams |> int.to_string,
        "0.1",
        "e.g., 15",
      ),
      nutrition_field(
        "fiber",
        "Fiber (g)",
        nutrition_constants.max_macronutrient_grams |> int.to_string,
        "0.1",
        "e.g., 5",
      ),
      nutrition_field(
        "sugar",
        "Sugar (g)",
        nutrition_constants.max_macronutrient_grams |> int.to_string,
        "0.1",
        "e.g., 8",
      ),
    ]),
  ])
}

fn nutrition_field(
  field_name: String,
  label_text: String,
  max_val: String,
  step_val: String,
  placeholder_text: String,
) -> Element(msg) {
  div([class("form-group")], [
    label([attribute("for", field_name)], [text(label_text)]),
    input([
      type_("number"),
      id(field_name),
      name(field_name),
      class("input"),
      min("0"),
      max(max_val),
      step(step_val),
      placeholder(placeholder_text),
      attribute("aria-describedby", field_name <> "-error"),
    ]),
    span(
      [
        id(field_name <> "-error"),
        class("form-error"),
        attribute("role", "alert"),
      ],
      [],
    ),
  ])
}

fn form_actions() -> Element(msg) {
  div([class("card-footer")], [
    button(
      [
        type_("submit"),
        class("btn btn-primary"),
        id("submit-btn"),
        attribute("aria-label", "Create recipe"),
      ],
      [text("Create Recipe")],
    ),
    button(
      [
        type_("button"),
        class("btn btn-secondary"),
        id("cancel-btn"),
        attribute("aria-label", "Cancel and return"),
      ],
      [text("Cancel")],
    ),
    span(
      [
        id("form-status"),
        class("text-sm text-muted ml-auto"),
        attribute("role", "status"),
        attribute("aria-live", "polite"),
      ],
      [],
    ),
  ])
}
// Required for int.to_string
