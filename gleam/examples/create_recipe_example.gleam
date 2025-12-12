import gleam/io
import gleam/option.{None, Some}
import meal_planner/config
import meal_planner/mealie/client
import meal_planner/mealie/types.{
  MealieFood, MealieIngredient, MealieInstruction, MealieRecipe,
}

/// Example of how to programmatically create a recipe in Mealie
///
/// Run this with: gleam run -m examples/create_recipe_example
pub fn main() {
  // Load configuration from environment
  let cfg = config.load()

  // Create a simple recipe
  let recipe =
    MealieRecipe(
      id: "",
      // Empty - Mealie will generate
      slug: "",
      // Empty - Mealie will auto-generate from name
      name: "Simple Pasta",
      description: Some("A quick and easy pasta dish"),
      image: None,
      recipe_yield: Some("2 servings"),
      total_time: Some("20 minutes"),
      prep_time: Some("5 minutes"),
      cook_time: Some("15 minutes"),
      rating: None,
      org_url: None,
      // Ingredients
      recipe_ingredient: [
        MealieIngredient(
          reference_id: "",
          quantity: Some(8.0),
          unit: None,
          food: Some(MealieFood(
            id: "",
            name: "pasta",
            description: Some("spaghetti"),
          )),
          note: None,
          is_food: True,
          disable_amount: False,
          display: "8 oz pasta",
          original_text: Some("8 oz pasta (spaghetti)"),
        ),
        MealieIngredient(
          reference_id: "",
          quantity: Some(2.0),
          unit: None,
          food: Some(MealieFood(
            id: "",
            name: "olive oil",
            description: None,
          )),
          note: None,
          is_food: True,
          disable_amount: False,
          display: "2 tbsp olive oil",
          original_text: Some("2 tbsp olive oil"),
        ),
        MealieIngredient(
          reference_id: "",
          quantity: Some(3.0),
          unit: None,
          food: Some(MealieFood(id: "", name: "garlic", description: None)),
          note: Some("minced"),
          is_food: True,
          disable_amount: False,
          display: "3 cloves garlic, minced",
          original_text: Some("3 cloves garlic, minced"),
        ),
      ],
      // Instructions
      recipe_instructions: [
        MealieInstruction(
          id: "",
          title: Some("Boil Pasta"),
          text: "Bring a large pot of salted water to boil. Add pasta and cook according to package directions.",
        ),
        MealieInstruction(
          id: "",
          title: Some("Prepare Sauce"),
          text: "While pasta cooks, heat olive oil in a large pan. Add minced garlic and sauté until fragrant.",
        ),
        MealieInstruction(
          id: "",
          title: Some("Combine"),
          text: "Drain pasta and add to the pan with garlic. Toss to combine. Season with salt and pepper.",
        ),
      ],
      recipe_category: [],
      tags: [],
      nutrition: None,
      date_added: None,
      date_updated: None,
    )

  // Create the recipe in Mealie
  case client.create_recipe(cfg, recipe) {
    Ok(created_recipe) -> {
      io.println("✅ Recipe created successfully!")
      io.println("   Slug: " <> created_recipe.slug)
      io.println("   ID: " <> created_recipe.id)
      io.println("   Name: " <> created_recipe.name)
      io.println(
        "\n🌐 View in Mealie: "
        <> cfg.mealie.base_url
        <> "/recipe/"
        <> created_recipe.slug,
      )
    }
    Error(err) -> {
      io.println("❌ Error creating recipe:")
      io.println("   " <> client.error_to_string(err))
      io.println("\n💡 Make sure:")
      io.println("   - Mealie is running (http://localhost:9000)")
      io.println("   - MEALIE_API_TOKEN is set in your .env file")
      io.println("   - MEALIE_BASE_URL is set correctly")
    }
  }
}
