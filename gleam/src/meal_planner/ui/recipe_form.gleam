// Recipe Form UI Component
// Accessible, responsive form with dynamic rows and validation

/// Generate the complete recipe creation form HTML
pub fn render_form() -> String {
  form_container_start()
  <> form_header()
  <> basic_info_section()
  <> ingredients_section()
  <> instructions_section()
  <> nutrition_section()
  <> form_actions()
  <> form_container_end()
}

fn form_container_start() -> String {
  "
<div class=\"container max-w-prose\">
  <form id=\"recipe-form\" class=\"card\" novalidate>
"
}

fn form_header() -> String {
  "
    <div class=\"card-header\">
      <h1>Create Recipe</h1>
      <p class=\"text-secondary\">Build a custom recipe with ingredients and instructions</p>
    </div>

    <div class=\"card-body\">
"
}

fn basic_info_section() -> String {
  "
      <!-- Basic Information -->
      <section class=\"mb-6\">
        <h2 class=\"text-xl font-semibold mb-4\">Basic Information</h2>

        <div class=\"form-group\">
          <label for=\"recipe-name\" class=\"required\">
            Recipe Name
            <span class=\"text-danger\" aria-label=\"required\">*</span>
          </label>
          <input
            type=\"text\"
            id=\"recipe-name\"
            name=\"name\"
            class=\"input\"
            placeholder=\"e.g., Grilled Chicken Salad\"
            required
            minlength=\"3\"
            maxlength=\"100\"
            aria-describedby=\"name-error\"
            aria-invalid=\"false\"
          />
          <span id=\"name-error\" class=\"form-error\" role=\"alert\" aria-live=\"polite\"></span>
        </div>

        <div class=\"form-group\">
          <label for=\"recipe-category\" class=\"required\">
            Category
            <span class=\"text-danger\" aria-label=\"required\">*</span>
          </label>
          <select
            id=\"recipe-category\"
            name=\"category\"
            class=\"input\"
            required
            aria-describedby=\"category-error\"
            aria-invalid=\"false\"
          >
            <option value=\"\">Select a category</option>
            <option value=\"breakfast\">Breakfast</option>
            <option value=\"lunch\">Lunch</option>
            <option value=\"dinner\">Dinner</option>
            <option value=\"snack\">Snack</option>
            <option value=\"dessert\">Dessert</option>
            <option value=\"beverage\">Beverage</option>
          </select>
          <span id=\"category-error\" class=\"form-error\" role=\"alert\" aria-live=\"polite\"></span>
        </div>

        <div class=\"grid grid-cols-2 gap-4\">
          <div class=\"form-group\">
            <label for=\"prep-time\">Prep Time (min)</label>
            <input
              type=\"number\"
              id=\"prep-time\"
              name=\"prep_time\"
              class=\"input\"
              min=\"0\"
              max=\"999\"
              placeholder=\"30\"
              aria-describedby=\"prep-time-error\"
            />
            <span id=\"prep-time-error\" class=\"form-error\" role=\"alert\" aria-live=\"polite\"></span>
          </div>

          <div class=\"form-group\">
            <label for=\"cook-time\">Cook Time (min)</label>
            <input
              type=\"number\"
              id=\"cook-time\"
              name=\"cook_time\"
              class=\"input\"
              min=\"0\"
              max=\"999\"
              placeholder=\"45\"
              aria-describedby=\"cook-time-error\"
            />
            <span id=\"cook-time-error\" class=\"form-error\" role=\"alert\" aria-live=\"polite\"></span>
          </div>
        </div>

        <div class=\"form-group\">
          <label for=\"servings\" class=\"required\">
            Servings
            <span class=\"text-danger\" aria-label=\"required\">*</span>
          </label>
          <input
            type=\"number\"
            id=\"servings\"
            name=\"servings\"
            class=\"input\"
            min=\"1\"
            max=\"100\"
            value=\"4\"
            required
            aria-describedby=\"servings-error\"
            aria-invalid=\"false\"
          />
          <span id=\"servings-error\" class=\"form-error\" role=\"alert\" aria-live=\"polite\"></span>
        </div>
      </section>
"
}

fn ingredients_section() -> String {
  "
      <!-- Ingredients Section -->
      <section class=\"mb-6\">
        <div class=\"flex justify-between items-center mb-4\">
          <h2 class=\"text-xl font-semibold\">
            Ingredients
            <span class=\"text-danger\" aria-label=\"required\">*</span>
          </h2>
          <button
            type=\"button\"
            id=\"add-ingredient\"
            class=\"btn btn-secondary btn-sm\"
            aria-label=\"Add ingredient row\"
          >
            + Add Ingredient
          </button>
        </div>

        <div id=\"ingredients-list\" role=\"list\" aria-label=\"Ingredient list\">
          <!-- Initial ingredient row -->
          <div class=\"ingredient-row\" role=\"listitem\" data-row-index=\"0\">
            <div class=\"grid grid-cols-12 gap-2 mb-3\">
              <div class=\"flex flex-col\" style=\"grid-column: span 5;\">
                <label for=\"ingredient-name-0\" class=\"text-sm mb-1\">
                  Food Item
                  <span class=\"text-danger\" aria-label=\"required\">*</span>
                </label>
                <input
                  type=\"text\"
                  id=\"ingredient-name-0\"
                  name=\"ingredients[0][name]\"
                  class=\"input ingredient-name\"
                  placeholder=\"e.g., Chicken breast\"
                  required
                  aria-describedby=\"ingredient-name-0-error\"
                  aria-invalid=\"false\"
                />
                <span id=\"ingredient-name-0-error\" class=\"form-error\" role=\"alert\"></span>
              </div>

              <div class=\"flex flex-col\" style=\"grid-column: span 3;\">
                <label for=\"ingredient-amount-0\" class=\"text-sm mb-1\">
                  Amount
                  <span class=\"text-danger\" aria-label=\"required\">*</span>
                </label>
                <input
                  type=\"number\"
                  id=\"ingredient-amount-0\"
                  name=\"ingredients[0][amount]\"
                  class=\"input ingredient-amount\"
                  placeholder=\"200\"
                  min=\"0\"
                  step=\"0.01\"
                  required
                  aria-describedby=\"ingredient-amount-0-error\"
                  aria-invalid=\"false\"
                />
                <span id=\"ingredient-amount-0-error\" class=\"form-error\" role=\"alert\"></span>
              </div>

              <div class=\"flex flex-col\" style=\"grid-column: span 3;\">
                <label for=\"ingredient-unit-0\" class=\"text-sm mb-1\">
                  Unit
                  <span class=\"text-danger\" aria-label=\"required\">*</span>
                </label>
                <select
                  id=\"ingredient-unit-0\"
                  name=\"ingredients[0][unit]\"
                  class=\"input ingredient-unit\"
                  required
                  aria-describedby=\"ingredient-unit-0-error\"
                  aria-invalid=\"false\"
                >
                  <option value=\"\">Select</option>
                  <option value=\"g\">g (grams)</option>
                  <option value=\"kg\">kg (kilograms)</option>
                  <option value=\"ml\">ml (milliliters)</option>
                  <option value=\"l\">L (liters)</option>
                  <option value=\"cup\">cup</option>
                  <option value=\"tbsp\">tbsp (tablespoon)</option>
                  <option value=\"tsp\">tsp (teaspoon)</option>
                  <option value=\"oz\">oz (ounce)</option>
                  <option value=\"lb\">lb (pound)</option>
                  <option value=\"piece\">piece</option>
                </select>
                <span id=\"ingredient-unit-0-error\" class=\"form-error\" role=\"alert\"></span>
              </div>

              <div class=\"flex items-end\" style=\"grid-column: span 1;\">
                <button
                  type=\"button\"
                  class=\"btn btn-danger btn-sm remove-ingredient\"
                  aria-label=\"Remove ingredient row\"
                  disabled
                >
                  ×
                </button>
              </div>
            </div>
          </div>
        </div>

        <div id=\"ingredients-error\" class=\"form-error\" role=\"alert\" aria-live=\"polite\"></div>
      </section>
"
}

fn instructions_section() -> String {
  "
      <!-- Instructions Section -->
      <section class=\"mb-6\">
        <div class=\"flex justify-between items-center mb-4\">
          <h2 class=\"text-xl font-semibold\">
            Instructions
            <span class=\"text-danger\" aria-label=\"required\">*</span>
          </h2>
          <button
            type=\"button\"
            id=\"add-instruction\"
            class=\"btn btn-secondary btn-sm\"
            aria-label=\"Add instruction step\"
          >
            + Add Step
          </button>
        </div>

        <div id=\"instructions-list\" role=\"list\" aria-label=\"Instruction steps\">
          <!-- Initial instruction row -->
          <div class=\"instruction-row mb-3\" role=\"listitem\" data-row-index=\"0\">
            <div class=\"flex gap-2\">
              <div class=\"flex-1\">
                <label for=\"instruction-0\" class=\"text-sm mb-1 flex items-center\">
                  <span class=\"badge badge-primary mr-2\">Step 1</span>
                  Description
                  <span class=\"text-danger ml-1\" aria-label=\"required\">*</span>
                </label>
                <textarea
                  id=\"instruction-0\"
                  name=\"instructions[0]\"
                  class=\"input instruction-text\"
                  placeholder=\"e.g., Preheat oven to 375°F (190°C)\"
                  required
                  rows=\"2\"
                  aria-describedby=\"instruction-0-error\"
                  aria-invalid=\"false\"
                ></textarea>
                <span id=\"instruction-0-error\" class=\"form-error\" role=\"alert\"></span>
              </div>

              <div class=\"flex items-end pb-6\">
                <button
                  type=\"button\"
                  class=\"btn btn-danger btn-sm remove-instruction\"
                  aria-label=\"Remove instruction step\"
                  disabled
                >
                  ×
                </button>
              </div>
            </div>
          </div>
        </div>

        <div id=\"instructions-error\" class=\"form-error\" role=\"alert\" aria-live=\"polite\"></div>
      </section>
"
}

fn nutrition_section() -> String {
  "
      <!-- Nutrition Information (Optional) -->
      <section class=\"mb-6\">
        <h2 class=\"text-xl font-semibold mb-4\">Nutrition Information (per serving)</h2>

        <div class=\"grid grid-cols-2 gap-4\">
          <div class=\"form-group\">
            <label for=\"calories\">Calories (kcal)</label>
            <input
              type=\"number\"
              id=\"calories\"
              name=\"calories\"
              class=\"input\"
              min=\"0\"
              max=\"9999\"
              step=\"1\"
              placeholder=\"e.g., 350\"
              aria-describedby=\"calories-error\"
            />
            <span id=\"calories-error\" class=\"form-error\" role=\"alert\"></span>
          </div>

          <div class=\"form-group\">
            <label for=\"protein\">Protein (g)</label>
            <input
              type=\"number\"
              id=\"protein\"
              name=\"protein\"
              class=\"input\"
              min=\"0\"
              max=\"999\"
              step=\"0.1\"
              placeholder=\"e.g., 30\"
              aria-describedby=\"protein-error\"
            />
            <span id=\"protein-error\" class=\"form-error\" role=\"alert\"></span>
          </div>

          <div class=\"form-group\">
            <label for=\"carbs\">Carbohydrates (g)</label>
            <input
              type=\"number\"
              id=\"carbs\"
              name=\"carbs\"
              class=\"input\"
              min=\"0\"
              max=\"999\"
              step=\"0.1\"
              placeholder=\"e.g., 25\"
              aria-describedby=\"carbs-error\"
            />
            <span id=\"carbs-error\" class=\"form-error\" role=\"alert\"></span>
          </div>

          <div class=\"form-group\">
            <label for=\"fat\">Fat (g)</label>
            <input
              type=\"number\"
              id=\"fat\"
              name=\"fat\"
              class=\"input\"
              min=\"0\"
              max=\"999\"
              step=\"0.1\"
              placeholder=\"e.g., 15\"
              aria-describedby=\"fat-error\"
            />
            <span id=\"fat-error\" class=\"form-error\" role=\"alert\"></span>
          </div>

          <div class=\"form-group\">
            <label for=\"fiber\">Fiber (g)</label>
            <input
              type=\"number\"
              id=\"fiber\"
              name=\"fiber\"
              class=\"input\"
              min=\"0\"
              max=\"999\"
              step=\"0.1\"
              placeholder=\"e.g., 5\"
              aria-describedby=\"fiber-error\"
            />
            <span id=\"fiber-error\" class=\"form-error\" role=\"alert\"></span>
          </div>

          <div class=\"form-group\">
            <label for=\"sugar\">Sugar (g)</label>
            <input
              type=\"number\"
              id=\"sugar\"
              name=\"sugar\"
              class=\"input\"
              min=\"0\"
              max=\"999\"
              step=\"0.1\"
              placeholder=\"e.g., 8\"
              aria-describedby=\"sugar-error\"
            />
            <span id=\"sugar-error\" class=\"form-error\" role=\"alert\"></span>
          </div>
        </div>
      </section>
"
}

fn form_actions() -> String {
  "
    </div>

    <!-- Form Actions -->
    <div class=\"card-footer\">
      <button
        type=\"submit\"
        class=\"btn btn-primary\"
        id=\"submit-btn\"
        aria-label=\"Create recipe\"
      >
        Create Recipe
      </button>
      <button
        type=\"button\"
        class=\"btn btn-secondary\"
        id=\"cancel-btn\"
        aria-label=\"Cancel and return\"
      >
        Cancel
      </button>
      <span id=\"form-status\" class=\"text-sm text-muted ml-auto\" role=\"status\" aria-live=\"polite\"></span>
    </div>
"
}

fn form_container_end() -> String {
  "
  </form>
</div>
"
}
