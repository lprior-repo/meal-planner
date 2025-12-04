# Recipe Collections Index

This directory contains recipe collections for various dietary protocols.

## Available Collections

### 1. Tim Ferriss Slow Carb Diet
**Files:**
- `/gleam/migrations_pg/013_add_tim_ferriss_recipes.sql` - Database migration
- `/gleam/docs/TIM_FERRISS_SLOW_CARB_RECIPES.md` - Comprehensive guide
- `/gleam/docs/tim_ferriss_recipes.yaml` - YAML format reference

**Recipe Count:** 17 total (15 slow carb compliant + 2 cheat day)

**Categories:**
- High-Protein Breakfasts: 5 recipes (30-42g protein)
- Lean Protein Mains: 5 recipes (40-48g protein)
- Legume Sides: 3 recipes (18-22g protein)
- Vegetable-Heavy Dishes: 2 recipes (38-42g protein)
- Cheat Day Recipes: 2 recipes

**Key Principles:**
1. Avoid white carbs (bread, rice, pasta, potatoes)
2. Eat same meals repeatedly
3. Don't drink calories
4. Don't eat fruit
5. Take one cheat day per week (Saturday)

**Target Macros Per Meal:**
- Protein: 30-40g (minimum 30g at breakfast)
- Carbs: 25-35g (from legumes/vegetables only)
- Fat: 12-20g
- Calories: 380-520

**Tags:**
- `slow_carb` - Core compliant meals
- `tim_ferriss` - From 4-Hour Body
- `high_protein` - 30g+ protein
- `legumes` - Contains beans/lentils
- `cheat_day` - Saturday indulgence

**Example Queries:**
```sql
-- Get all slow carb breakfast options
SELECT name, calories, protein, carbs, fat, description
FROM recipes_simplified
WHERE tags LIKE '%slow_carb%'
  AND category = 'breakfast'
  AND tags NOT LIKE '%cheat_day%';

-- Find high-protein options (40g+)
SELECT name, protein, category
FROM recipes_simplified
WHERE tags LIKE '%tim_ferriss%'
  AND protein >= 40;
```

---

### 2. Vertical Diet (If Available)
**Files:**
- `/gleam/migrations_pg/013_add_vertical_diet_recipes.sql`
- `/gleam/vertical_diet_recipes.yaml`

**Focus:** Red meat, white rice, sweet potatoes, bone broth, spinach

---

## How to Apply Migrations

### PostgreSQL
```bash
cd /home/lewis/src/meal-planner/gleam

# Apply Tim Ferriss recipes
psql -U your_user -d meal_planner -f migrations_pg/013_add_tim_ferriss_recipes.sql

# Verify
psql -U your_user -d meal_planner -c "
  SELECT COUNT(*) as total,
         COUNT(CASE WHEN tags LIKE '%slow_carb%' THEN 1 END) as slow_carb
  FROM recipes_simplified
  WHERE tags LIKE '%tim_ferriss%';
"
```

## File Formats

### SQL Migration
- Primary format for database seeding
- Includes indexes and verification queries
- Contains INSERT statements with full recipe data

### Markdown Documentation
- Human-readable guide
- Explains dietary principles
- Provides meal planning examples
- Includes tips and expected results

### YAML Reference
- Machine-readable format
- Easy import/export
- Contains ingredients and instructions
- Structured for programmatic access

## Adding New Collections

When adding a new recipe collection:

1. **Create SQL migration** (`/gleam/migrations_pg/XXX_add_DIET_recipes.sql`)
   - Follow existing schema (name, calories, protein, carbs, fat, tags, description)
   - Add tags for filtering
   - Include verification queries

2. **Write documentation** (`/gleam/docs/DIET_RECIPES.md`)
   - Explain diet principles
   - List all recipes with macros
   - Provide sample meal plans
   - Include SQL query examples

3. **Optional: YAML format** (`/gleam/docs/diet_recipes.yaml`)
   - Structured data format
   - Include ingredients and instructions
   - Add metadata and guidelines

4. **Update this index** with new collection details

## Recipe Schema

```sql
CREATE TABLE recipes_simplified (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    calories INT NOT NULL,
    protein INT NOT NULL,
    carbs INT NOT NULL,
    fat INT NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    branded BOOLEAN DEFAULT FALSE,
    category VARCHAR(100) NOT NULL,
    tags VARCHAR(500),           -- Added for filtering
    description TEXT,            -- Added for recipe details
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

## Tag Conventions

Use comma-separated tags in the `tags` column:

**Diet Types:**
- `slow_carb` - Tim Ferriss Slow Carb Diet
- `vertical_diet` - Stan Efferding Vertical Diet
- `keto` - Ketogenic diet
- `paleo` - Paleo diet
- `mediterranean` - Mediterranean diet

**Nutritional Focus:**
- `high_protein` - 30g+ protein per serving
- `low_carb` - <20g net carbs
- `high_fiber` - 10g+ fiber
- `omega3` - Rich in omega-3 fatty acids

**Food Components:**
- `legumes` - Contains beans/lentils
- `vegetables` - Vegetable-focused
- `beef`, `chicken`, `fish`, `pork`, `turkey` - Protein source

**Dietary Restrictions:**
- `vegetarian` - No meat
- `vegan` - No animal products
- `dairy_free` - No dairy
- `gluten_free` - No gluten

**Special Categories:**
- `cheat_day` - Off-protocol indulgence
- `meal_prep` - Batch cooking friendly
- `quick` - <20 minutes prep+cook

## References

- **Tim Ferriss Slow Carb:** "The 4-Hour Body" (2010), Chapter 2
- **Stan Efferding Vertical Diet:** verticaldiethq.com
- **USDA Nutrition Data:** fdc.nal.usda.gov

---

**Last Updated:** 2025-12-04
**Maintainer:** Claude Code Agent
