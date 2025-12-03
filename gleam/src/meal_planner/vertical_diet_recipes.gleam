/// Vertical Diet compliant recipes
/// Created following Stan Efferding's Vertical Diet principles:
/// - Red meat as primary protein source
/// - White rice as primary carbohydrate
/// - Easily digestible, low FODMAP foods
/// - Micronutrient-dense vegetables
import shared/types.{type Recipe, Ingredient, Low, Macros, Recipe}

/// Generate all Vertical Diet recipes
pub fn all_recipes() -> List(Recipe) {
  [
    // ============================================================================
    // RED MEAT MAIN DISHES (12 recipes)
    // ============================================================================
    // 1. Classic Grilled Ribeye
    Recipe(
      id: "vd-ribeye-01",
      name: "Classic Grilled Ribeye",
      ingredients: [
        Ingredient("ribeye steak", "8 oz"),
        Ingredient("sea salt", "1 tsp"),
        Ingredient("black pepper", "1/2 tsp"),
        Ingredient("olive oil", "1 tbsp"),
      ],
      instructions: [
        "Let steak come to room temperature for 30 minutes",
        "Season generously with salt and pepper",
        "Heat grill or cast iron skillet to high heat",
        "Brush steak with olive oil",
        "Grill 4-5 minutes per side for medium-rare",
        "Rest for 5 minutes before serving",
      ],
      macros: Macros(protein: 48.0, fat: 32.0, carbs: 0.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 2. Simple Pan-Seared Strip Steak
    Recipe(
      id: "vd-strip-02",
      name: "Pan-Seared Strip Steak",
      ingredients: [
        Ingredient("NY strip steak", "8 oz"),
        Ingredient("butter", "2 tbsp"),
        Ingredient("garlic", "2 cloves"),
        Ingredient("sea salt", "1 tsp"),
      ],
      instructions: [
        "Pat steak dry and season with salt",
        "Heat cast iron skillet until smoking",
        "Sear steak 3-4 minutes per side",
        "Add butter and garlic to pan",
        "Baste steak with melted butter",
        "Rest 5 minutes before slicing",
      ],
      macros: Macros(protein: 50.0, fat: 34.0, carbs: 1.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 3. Ground Beef and Rice Bowl
    Recipe(
      id: "vd-beef-rice-03",
      name: "Ground Beef and Rice Bowl",
      ingredients: [
        Ingredient("lean ground beef (90/10)", "6 oz"),
        Ingredient("cooked white rice", "1 cup"),
        Ingredient("sea salt", "1 tsp"),
        Ingredient("olive oil", "1 tbsp"),
      ],
      instructions: [
        "Heat olive oil in skillet over medium-high heat",
        "Add ground beef and break into small pieces",
        "Cook until browned, about 8 minutes",
        "Season with salt",
        "Serve over white rice",
      ],
      macros: Macros(protein: 40.0, fat: 18.0, carbs: 45.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 4. Simple Beef Patties
    Recipe(
      id: "vd-patties-04",
      name: "Simple Beef Patties",
      ingredients: [
        Ingredient("ground beef (85/15)", "8 oz"),
        Ingredient("sea salt", "1 tsp"),
        Ingredient("black pepper", "1/2 tsp"),
        Ingredient("olive oil", "1 tbsp"),
      ],
      instructions: [
        "Form beef into 2 thick patties",
        "Season both sides with salt and pepper",
        "Heat oil in skillet over medium-high heat",
        "Cook patties 4-5 minutes per side",
        "Rest 3 minutes before serving",
      ],
      macros: Macros(protein: 46.0, fat: 30.0, carbs: 0.0),
      servings: 2,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 5. Bison Burger Patty
    Recipe(
      id: "vd-bison-05",
      name: "Bison Burger Patty",
      ingredients: [
        Ingredient("ground bison", "6 oz"),
        Ingredient("sea salt", "3/4 tsp"),
        Ingredient("olive oil", "1 tsp"),
      ],
      instructions: [
        "Form bison into a thick patty",
        "Season with salt",
        "Heat oil in skillet over medium heat",
        "Cook 3-4 minutes per side (bison is lean, don't overcook)",
        "Rest 3 minutes before serving",
      ],
      macros: Macros(protein: 38.0, fat: 12.0, carbs: 0.0),
      servings: 1,
      category: "bison-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 6. Grilled Bison Steak
    Recipe(
      id: "vd-bison-steak-06",
      name: "Grilled Bison Steak",
      ingredients: [
        Ingredient("bison sirloin steak", "8 oz"),
        Ingredient("sea salt", "1 tsp"),
        Ingredient("butter", "1 tbsp"),
      ],
      instructions: [
        "Let steak reach room temperature",
        "Season with salt",
        "Grill over high heat 3 minutes per side",
        "Top with butter and let rest 5 minutes",
      ],
      macros: Macros(protein: 48.0, fat: 16.0, carbs: 0.0),
      servings: 1,
      category: "bison-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 7. Lamb Chops with Sea Salt
    Recipe(
      id: "vd-lamb-07",
      name: "Lamb Chops with Sea Salt",
      ingredients: [
        Ingredient("lamb loin chops", "8 oz (3-4 chops)"),
        Ingredient("sea salt", "1 tsp"),
        Ingredient("olive oil", "1 tbsp"),
      ],
      instructions: [
        "Bring lamb to room temperature",
        "Season generously with salt",
        "Heat oil in skillet over high heat",
        "Sear chops 3 minutes per side",
        "Rest 5 minutes before serving",
      ],
      macros: Macros(protein: 42.0, fat: 28.0, carbs: 0.0),
      servings: 1,
      category: "lamb-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 8. Simple Ground Lamb
    Recipe(
      id: "vd-ground-lamb-08",
      name: "Simple Ground Lamb",
      ingredients: [
        Ingredient("ground lamb", "6 oz"),
        Ingredient("sea salt", "3/4 tsp"),
        Ingredient("black pepper", "1/4 tsp"),
      ],
      instructions: [
        "Heat skillet over medium-high heat",
        "Add ground lamb and break into pieces",
        "Cook until browned, about 8 minutes",
        "Season with salt and pepper",
        "Drain excess fat if desired",
      ],
      macros: Macros(protein: 36.0, fat: 24.0, carbs: 0.0),
      servings: 1,
      category: "lamb-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 9. Beef and Spinach Skillet
    Recipe(
      id: "vd-beef-spinach-09",
      name: "Beef and Spinach Skillet",
      ingredients: [
        Ingredient("ground beef (90/10)", "6 oz"),
        Ingredient("fresh spinach", "2 cups"),
        Ingredient("sea salt", "1 tsp"),
        Ingredient("olive oil", "1 tbsp"),
      ],
      instructions: [
        "Brown ground beef in olive oil",
        "Season with salt",
        "Add spinach and cook until wilted, 2 minutes",
        "Mix well and serve",
      ],
      macros: Macros(protein: 42.0, fat: 20.0, carbs: 2.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 10. Ribeye with Bone Broth Reduction
    Recipe(
      id: "vd-ribeye-broth-10",
      name: "Ribeye with Bone Broth Reduction",
      ingredients: [
        Ingredient("ribeye steak", "8 oz"),
        Ingredient("beef bone broth", "1/2 cup"),
        Ingredient("sea salt", "1 tsp"),
        Ingredient("butter", "2 tbsp"),
      ],
      instructions: [
        "Season and sear ribeye as usual",
        "Remove steak and rest",
        "Add bone broth to hot pan",
        "Reduce by half, about 3 minutes",
        "Whisk in butter",
        "Pour over steak",
      ],
      macros: Macros(protein: 48.0, fat: 38.0, carbs: 1.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 11. Grilled Sirloin Tips
    Recipe(
      id: "vd-sirloin-tips-11",
      name: "Grilled Sirloin Tips",
      ingredients: [
        Ingredient("sirloin tips", "8 oz"),
        Ingredient("sea salt", "1 tsp"),
        Ingredient("olive oil", "2 tbsp"),
      ],
      instructions: [
        "Cut sirloin into 2-inch cubes",
        "Toss with olive oil and salt",
        "Grill over high heat, turning occasionally",
        "Cook to desired doneness, about 8 minutes total",
      ],
      macros: Macros(protein: 46.0, fat: 20.0, carbs: 0.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 12. Beef Chuck Roast (Slow-Cooked)
    Recipe(
      id: "vd-chuck-roast-12",
      name: "Simple Beef Chuck Roast",
      ingredients: [
        Ingredient("beef chuck roast", "3 lbs"),
        Ingredient("sea salt", "2 tbsp"),
        Ingredient("beef bone broth", "2 cups"),
        Ingredient("carrots", "1 lb, large chunks"),
      ],
      instructions: [
        "Season roast generously with salt",
        "Place in slow cooker with broth and carrots",
        "Cook on low for 8 hours",
        "Shred meat and serve with cooking liquid",
      ],
      macros: Macros(protein: 52.0, fat: 28.0, carbs: 6.0),
      servings: 8,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // ============================================================================
    // WHITE RICE PREPARATIONS (6 recipes)
    // ============================================================================
    // 13. Simple White Rice
    Recipe(
      id: "vd-rice-01",
      name: "Simple White Rice",
      ingredients: [
        Ingredient("white rice", "1 cup dry"),
        Ingredient("water", "2 cups"),
        Ingredient("sea salt", "1/2 tsp"),
      ],
      instructions: [
        "Rinse rice until water runs clear",
        "Combine rice, water, and salt in pot",
        "Bring to boil, then reduce to simmer",
        "Cover and cook 18 minutes",
        "Let rest 5 minutes, fluff with fork",
      ],
      macros: Macros(protein: 8.0, fat: 1.0, carbs: 90.0),
      servings: 4,
      category: "rice-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 14. Bone Broth Rice
    Recipe(
      id: "vd-rice-broth-02",
      name: "Bone Broth Rice",
      ingredients: [
        Ingredient("white rice", "1 cup dry"),
        Ingredient("beef bone broth", "2 cups"),
        Ingredient("sea salt", "1/4 tsp"),
      ],
      instructions: [
        "Rinse rice thoroughly",
        "Combine rice, bone broth, and salt",
        "Bring to boil, reduce to simmer",
        "Cover and cook 18 minutes",
        "Fluff and serve",
      ],
      macros: Macros(protein: 10.0, fat: 2.0, carbs: 90.0),
      servings: 4,
      category: "rice-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 15. Butter Rice
    Recipe(
      id: "vd-rice-butter-03",
      name: "Butter Rice",
      ingredients: [
        Ingredient("white rice", "1 cup dry"),
        Ingredient("water", "2 cups"),
        Ingredient("butter", "3 tbsp"),
        Ingredient("sea salt", "1/2 tsp"),
      ],
      instructions: [
        "Cook rice as usual in water with salt",
        "When done, stir in butter until melted",
        "Let rest 5 minutes",
        "Fluff and serve",
      ],
      macros: Macros(protein: 8.0, fat: 12.0, carbs: 90.0),
      servings: 4,
      category: "rice-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 16. Salty Rice
    Recipe(
      id: "vd-rice-salty-04",
      name: "Salty Rice (Electrolyte-Enhanced)",
      ingredients: [
        Ingredient("white rice", "1 cup dry"),
        Ingredient("water", "2 cups"),
        Ingredient("sea salt", "1 tsp"),
      ],
      instructions: [
        "Rinse rice well",
        "Cook with water and salt",
        "The higher salt content aids electrolyte balance",
        "Perfect post-workout",
      ],
      macros: Macros(protein: 8.0, fat: 1.0, carbs: 90.0),
      servings: 4,
      category: "rice-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 17. Spinach Rice
    Recipe(
      id: "vd-rice-spinach-05",
      name: "Spinach Rice",
      ingredients: [
        Ingredient("cooked white rice", "2 cups"),
        Ingredient("fresh spinach", "2 cups"),
        Ingredient("butter", "2 tbsp"),
        Ingredient("sea salt", "1/2 tsp"),
      ],
      instructions: [
        "Heat butter in pan",
        "Add spinach and cook until wilted",
        "Stir in cooked rice",
        "Season with salt and mix well",
      ],
      macros: Macros(protein: 6.0, fat: 7.0, carbs: 46.0),
      servings: 2,
      category: "rice-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 18. Carrot-Infused Rice
    Recipe(
      id: "vd-rice-carrot-06",
      name: "Carrot-Infused Rice",
      ingredients: [
        Ingredient("white rice", "1 cup dry"),
        Ingredient("carrot juice", "1 cup"),
        Ingredient("water", "1 cup"),
        Ingredient("sea salt", "1/2 tsp"),
      ],
      instructions: [
        "Combine rice, carrot juice, water, and salt",
        "Bring to boil, reduce to simmer",
        "Cover and cook 18 minutes",
        "Rice will have orange color and mild carrot flavor",
      ],
      macros: Macros(protein: 10.0, fat: 1.0, carbs: 98.0),
      servings: 4,
      category: "rice-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // ============================================================================
    // VEGETABLE SIDES (7 recipes)
    // ============================================================================
    // 19. Steamed Carrots
    Recipe(
      id: "vd-veg-carrots-01",
      name: "Simple Steamed Carrots",
      ingredients: [
        Ingredient("carrots", "1 lb, sliced"),
        Ingredient("water", "1 cup"),
        Ingredient("sea salt", "1/2 tsp"),
        Ingredient("butter", "1 tbsp"),
      ],
      instructions: [
        "Steam carrots until tender, about 8 minutes",
        "Toss with butter and salt",
        "Serve immediately",
      ],
      macros: Macros(protein: 2.0, fat: 3.0, carbs: 20.0),
      servings: 4,
      category: "vegetable-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 20. Sautéed Spinach
    Recipe(
      id: "vd-veg-spinach-01",
      name: "Sautéed Spinach",
      ingredients: [
        Ingredient("fresh spinach", "1 lb"),
        Ingredient("olive oil", "2 tbsp"),
        Ingredient("sea salt", "1/2 tsp"),
      ],
      instructions: [
        "Heat olive oil in large pan",
        "Add spinach in batches",
        "Cook until wilted, about 3 minutes",
        "Season with salt",
      ],
      macros: Macros(protein: 6.0, fat: 8.0, carbs: 8.0),
      servings: 4,
      category: "vegetable-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 21. Roasted Carrots
    Recipe(
      id: "vd-veg-carrots-roast-02",
      name: "Roasted Carrots",
      ingredients: [
        Ingredient("carrots", "1 lb, whole or halved"),
        Ingredient("olive oil", "2 tbsp"),
        Ingredient("sea salt", "1 tsp"),
      ],
      instructions: [
        "Preheat oven to 425°F",
        "Toss carrots with oil and salt",
        "Roast 25-30 minutes until tender and caramelized",
        "Turn once halfway through",
      ],
      macros: Macros(protein: 2.0, fat: 8.0, carbs: 20.0),
      servings: 4,
      category: "vegetable-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 22. Steamed Zucchini
    Recipe(
      id: "vd-veg-zucchini-01",
      name: "Steamed Zucchini",
      ingredients: [
        Ingredient("zucchini", "2 medium, sliced"),
        Ingredient("water", "1 cup"),
        Ingredient("sea salt", "1/4 tsp"),
        Ingredient("butter", "1 tbsp"),
      ],
      instructions: [
        "Steam zucchini until tender, 5-6 minutes",
        "Toss with butter and salt",
        "Serve hot",
      ],
      macros: Macros(protein: 2.0, fat: 3.0, carbs: 8.0),
      servings: 2,
      category: "vegetable-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 23. Butter Carrots
    Recipe(
      id: "vd-veg-carrots-butter-03",
      name: "Butter Glazed Carrots",
      ingredients: [
        Ingredient("carrots", "1 lb, sliced"),
        Ingredient("butter", "3 tbsp"),
        Ingredient("sea salt", "1/2 tsp"),
      ],
      instructions: [
        "Steam carrots until tender",
        "Melt butter in pan",
        "Add carrots and toss to coat",
        "Cook 2 minutes until glazed",
        "Season with salt",
      ],
      macros: Macros(protein: 2.0, fat: 9.0, carbs: 20.0),
      servings: 4,
      category: "vegetable-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 24. Simple Bok Choy
    Recipe(
      id: "vd-veg-bokchoy-01",
      name: "Sautéed Bok Choy",
      ingredients: [
        Ingredient("bok choy", "1 lb, chopped"),
        Ingredient("olive oil", "1 tbsp"),
        Ingredient("sea salt", "1/4 tsp"),
      ],
      instructions: [
        "Heat oil in wok or large pan",
        "Add bok choy",
        "Sauté 4-5 minutes until tender",
        "Season with salt",
      ],
      macros: Macros(protein: 3.0, fat: 4.0, carbs: 6.0),
      servings: 2,
      category: "vegetable-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),

    // 25. Carrot Mash
    Recipe(
      id: "vd-veg-carrots-mash-04",
      name: "Carrot Mash",
      ingredients: [
        Ingredient("carrots", "2 lbs, chopped"),
        Ingredient("butter", "4 tbsp"),
        Ingredient("sea salt", "1 tsp"),
      ],
      instructions: [
        "Boil carrots until very soft, 20 minutes",
        "Drain well",
        "Mash with butter and salt",
        "Serve as alternative to mashed potatoes",
      ],
      macros: Macros(protein: 4.0, fat: 12.0, carbs: 40.0),
      servings: 6,
      category: "vegetable-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
  ]
}
