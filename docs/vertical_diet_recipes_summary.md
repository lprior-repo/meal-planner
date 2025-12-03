# Vertical Diet Recipes - Summary

## Overview
Created 25 Vertical Diet compliant recipes following Stan Efferding's principles.

## Recipe Categories

### Red Meat Main Dishes (12 recipes)
1. **Classic Grilled Ribeye** - 48g protein, 32g fat
2. **Pan-Seared Strip Steak** - 50g protein, 34g fat
3. **Ground Beef and Rice Bowl** - 40g protein, 45g carbs
4. **Simple Beef Patties** - 46g protein, 30g fat
5. **Bison Burger Patty** - 38g protein, 12g fat
6. **Grilled Bison Steak** - 48g protein, 16g fat
7. **Lamb Chops with Sea Salt** - 42g protein, 28g fat
8. **Simple Ground Lamb** - 36g protein, 24g fat
9. **Beef and Spinach Skillet** - 42g protein, 20g fat
10. **Ribeye with Bone Broth Reduction** - 48g protein, 38g fat
11. **Grilled Sirloin Tips** - 46g protein, 20g fat
12. **Simple Beef Chuck Roast** - 52g protein, 28g fat

### White Rice Preparations (6 recipes)
13. **Simple White Rice** - 8g protein, 90g carbs per serving
14. **Bone Broth Rice** - 10g protein, 90g carbs
15. **Butter Rice** - 8g protein, 90g carbs, 12g fat
16. **Salty Rice** (Electrolyte-Enhanced) - 8g protein, 90g carbs
17. **Spinach Rice** - 6g protein, 46g carbs
18. **Carrot-Infused Rice** - 10g protein, 98g carbs

### Vegetable Sides (7 recipes)
19. **Simple Steamed Carrots** - 2g protein, 20g carbs
20. **Sautéed Spinach** - 6g protein, 8g carbs
21. **Roasted Carrots** - 2g protein, 20g carbs
22. **Steamed Zucchini** - 2g protein, 8g carbs
23. **Butter Glazed Carrots** - 2g protein, 20g carbs
24. **Sautéed Bok Choy** - 3g protein, 6g carbs
25. **Carrot Mash** - 4g protein, 40g carbs

## Vertical Diet Principles

All recipes adhere to:
- ✅ **Low FODMAP** - Easy on digestion
- ✅ **Vertical Diet Compliant** - Red meat + white rice base
- ✅ **High Bioavailability** - Easily absorbed nutrients
- ✅ **Micronutrient Dense** - Rich in vitamins and minerals
- ✅ **Simple Ingredients** - No complex seasonings

## Nutritional Benefits

### Protein Sources
- **Beef**: High in iron, zinc, B12, creatine
- **Bison**: Lean alternative, high in iron
- **Lamb**: Rich in B vitamins, selenium

### Carbohydrate Source
- **White Rice**: Low FODMAP, easy to digest, steady energy

### Micronutrients
- **Carrots**: Beta-carotene (Vitamin A), potassium
- **Spinach**: Iron, magnesium, folate, vitamins A, C, K
- **Bok Choy**: Calcium, vitamins C and K

## Usage Instructions

### To Insert Recipes into Database:

```bash
# Option 1: Run the test file
cd gleam
gleam test --module vertical_diet_recipes_test

# Option 2: Use the shell script
chmod +x scripts/add_vertical_recipes.sh
./scripts/add_vertical_recipes.sh
```

### Recipe IDs
All recipes have IDs prefixed with `vd-` (Vertical Diet):
- Beef: `vd-ribeye-01`, `vd-strip-02`, etc.
- Bison: `vd-bison-05`, `vd-bison-steak-06`
- Lamb: `vd-lamb-07`, `vd-ground-lamb-08`
- Rice: `vd-rice-01` through `vd-rice-carrot-06`
- Vegetables: `vd-veg-carrots-01`, `vd-veg-spinach-01`, etc.

## Meal Combination Suggestions

### High Protein Meal (Post-Workout)
- Grilled Ribeye (48g protein)
- Simple White Rice (22g carbs per serving)
- Steamed Carrots (20g carbs, vitamin A)
- **Total**: 50g protein, 42g carbs

### Balanced Meal
- Ground Beef and Rice Bowl (40g protein, 45g carbs)
- Sautéed Spinach (6g protein, iron, magnesium)
- **Total**: 46g protein, 53g carbs

### Lean Mass Gain
- Bison Steak (48g protein, low fat)
- Bone Broth Rice (90g carbs, collagen)
- Butter Glazed Carrots (micronutrients)

### Easy Digestion
- Simple Beef Patties
- Salty Rice (electrolytes)
- Steamed Zucchini

## Implementation Details

**File Location**: `gleam/src/meal_planner/vertical_diet_recipes.gleam`

**Storage Function**: Uses `storage.save_recipe()` from `meal_planner/storage.gleam`

**Type System**: All recipes use shared types from `shared/types.gleam`:
- `Recipe` - Complete recipe structure
- `Ingredient` - Name and quantity
- `Macros` - Protein, fat, carbs per serving
- `FodmapLevel.Low` - All recipes are low FODMAP
- `vertical_compliant: True` - All marked as Vertical Diet compliant

## Database Schema

Recipes are stored in the `recipes` table with fields:
```sql
CREATE TABLE recipes (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    ingredients TEXT NOT NULL,  -- Pipe-separated
    instructions TEXT NOT NULL, -- Pipe-separated
    protein REAL NOT NULL,
    fat REAL NOT NULL,
    carbs REAL NOT NULL,
    servings INTEGER NOT NULL,
    category TEXT NOT NULL,
    fodmap_level TEXT NOT NULL,
    vertical_compliant INTEGER NOT NULL
);
```

## Next Steps

1. Run the insertion script to add recipes to the database
2. Recipes will be available via the API endpoints
3. Users can search and log Vertical Diet meals
4. Track micronutrients with the enhanced food logging system
