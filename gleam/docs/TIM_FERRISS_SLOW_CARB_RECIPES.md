# Tim Ferriss Slow Carb Diet - Recipe Collection

## Overview

This collection contains **17 recipes** designed to comply with Tim Ferriss's "Slow Carb Diet" from **The 4-Hour Body**. These recipes follow the core principles for maximum fat loss while maintaining muscle mass.

## The Five Rules of Slow Carb Diet

### Rule #1: Avoid "White" Carbohydrates
**Prohibited:**
- Bread (all types)
- Rice (white and brown)
- Cereal
- Potatoes
- Pasta
- Fried foods with breading

**Exception:** You can eat these within 1.5 hours of finishing resistance exercise (weight training).

### Rule #2: Eat the Same Few Meals Repeatedly
**The book recommends:**
- 3-4 meals from a short list of recipes
- Reduces decision fatigue
- Ensures compliance
- Makes shopping simple

**Our recipe tags help you build your rotation:**
- `slow_carb` = Core compliant meals
- `high_protein` = 30g+ protein per serving
- `legumes` = Contains beans/lentils

### Rule #3: Don't Drink Calories
**Allowed:**
- Water (with lemon is fine)
- Unsweetened tea
- Unsweetened coffee
- Red wine (max 2 glasses per night)

**Prohibited:**
- Milk (except small amounts in coffee)
- Fruit juice
- Soda
- Smoothies (except cheat day)

### Rule #4: Don't Eat Fruit
**Reasoning:**
- Fructose → lipogenesis (fat storage)
- Causes insulin spikes

**Exceptions:**
- Tomatoes (technically a fruit, but allowed)
- Avocados (technically a fruit, but allowed)
- Cheat day (eat whatever you want)

### Rule #5: Take One Day Off Per Week
**Cheat Day (Saturday recommended):**
- Eat whatever you want
- Helps prevent metabolic slowdown
- Psychological relief valve
- Actually accelerates fat loss when done weekly

**Our cheat day recipes are tagged:** `cheat_day`

## Recipe Breakdown

### High-Protein Breakfasts (5 recipes)
**Why breakfast matters:**
- Eat within 30 minutes of waking
- 30g+ protein to trigger fat loss
- Eggs are ideal (cheap, easy, complete protein)
- Legumes add fiber and slow-burning carbs

**Examples:**
1. **Slow Carb Breakfast Bowl** (420 cal, 38g protein)
   - 3 eggs + black beans + spinach
   - The foundational 4HB breakfast

2. **Mexican Breakfast Scramble** (445 cal, 42g protein)
   - 4 eggs + black beans + salsa
   - High satiety, prevents snacking

3. **Lentil & Egg Power Breakfast** (395 cal, 35g protein)
   - 3 eggs + lentils + garlic spinach
   - Great for vegetarians who eat eggs

4. **Cottage Cheese Protein Scramble** (380 cal, 40g protein)
   - 4 eggs + cottage cheese + black beans
   - Dairy exception (cottage cheese is allowed)

5. **Breakfast Burrito Bowl** (425 cal, 38g protein)
   - Eggs + pinto beans + avocado (no tortilla!)
   - All the flavor, none of the bread

### Lean Protein Mains (5 recipes)
**Protein sources Tim recommends:**
- Grass-fed beef (preferred over grain-fed)
- Wild-caught fish (salmon, sardines)
- Chicken thighs (more flavor than breast)
- Pork (leaner cuts)
- Turkey (ground or breast)

**Examples:**
1. **Grass-Fed Beef & Black Bean Bowl** (485 cal, 48g protein)
2. **Grilled Chicken Thigh with Lentils** (450 cal, 42g protein)
3. **Pan-Seared Salmon with White Beans** (520 cal, 45g protein)
4. **Slow Cooker Pork & Pinto Beans** (465 cal, 44g protein)
5. **Turkey & Lentil Chili** (410 cal, 40g protein)

### Legume Sides (3 recipes)
**Why legumes are critical:**
- Slow-burning carbs (low glycemic index)
- High fiber (keeps you full)
- Protein content (10-15g per cup)
- Prevents constipation (common on low-carb diets)

**Recommended legumes:**
- Black beans (most popular)
- Pinto beans
- Red lentils (cook fastest)
- Cannellini beans (white kidney beans)

**Examples:**
1. **Garlicky Black Beans with Spinach** (280 cal, 18g protein)
2. **Spicy Lentil Soup** (320 cal, 22g protein)
3. **White Bean & Vegetable Medley** (295 cal, 20g protein)

### Vegetable-Heavy Dishes (2 recipes)
**Best vegetables for slow carb:**
- Spinach (raw or cooked)
- Mixed greens
- Asparagus
- Broccoli
- Cauliflower
- Green beans
- Brussels sprouts

**Examples:**
1. **Massive Spinach Salad with Chicken** (385 cal, 42g protein)
2. **Cauliflower Steak with Beef** (425 cal, 38g protein)

### Cheat Day Recipes (2 recipes)
**Purpose of cheat day:**
- Prevents metabolic adaptation
- Upregulates leptin (satiety hormone)
- Psychological break from restriction
- Makes the diet sustainable long-term

**Important rules:**
1. Must be a full day (not a cheat meal)
2. Same day every week (Saturday recommended)
3. Go wild - don't hold back
4. No guilt - it's part of the protocol

**Examples:**
1. **Cheat Day Pancake Stack** (820 cal)
2. **Cheat Day Burger & Fries** (950 cal)

## Nutritional Targets Per Meal

Based on 4-Hour Body recommendations:

| Macro | Breakfast | Lunch | Dinner |
|-------|-----------|-------|--------|
| **Protein** | 30-40g | 30-40g | 30-40g |
| **Carbs** | 25-35g | 25-35g | 25-35g |
| **Fat** | 12-20g | 12-20g | 12-20g |
| **Calories** | 380-450 | 380-500 | 380-520 |

**Daily totals (3 meals):**
- Protein: 90-120g
- Carbs: 75-105g (all from legumes/vegetables)
- Fat: 36-60g
- Calories: 1,140-1,470

*Note: Tim recommends eating 3-4 meals per day. Snacking is discouraged.*

## Querying Tim Ferriss Recipes

### SQL Queries

```sql
-- Get all slow carb breakfast options
SELECT name, calories, protein, carbs, fat, description
FROM recipes_simplified
WHERE tags LIKE '%slow_carb%'
  AND category = 'breakfast'
  AND tags NOT LIKE '%cheat_day%'
ORDER BY protein DESC;

-- Find high-protein lunch options (40g+)
SELECT name, calories, protein, carbs, fat
FROM recipes_simplified
WHERE tags LIKE '%tim_ferriss%'
  AND protein >= 40
  AND category = 'lunch';

-- Get all recipes with legumes
SELECT name, category, protein, carbs, description
FROM recipes_simplified
WHERE tags LIKE '%legumes%'
ORDER BY category, protein DESC;

-- Cheat day options only
SELECT name, calories, protein, carbs, fat
FROM recipes_simplified
WHERE tags LIKE '%cheat_day%';

-- Vegetarian slow carb options
SELECT name, calories, protein, carbs, fat, description
FROM recipes_simplified
WHERE tags LIKE '%slow_carb%'
  AND tags LIKE '%vegetarian%';
```

## Sample Weekly Meal Plan

### Monday - Friday (Slow Carb Days)

**Breakfast (7:00 AM):**
- Slow Carb Breakfast Bowl
- Black coffee

**Lunch (12:30 PM):**
- Grass-Fed Beef & Black Bean Bowl
- Unsweetened iced tea

**Dinner (7:00 PM):**
- Pan-Seared Salmon with White Beans
- Side of roasted broccoli
- 1 glass red wine (optional)

**Snack (if needed):**
- Carrots with hummus
- Hard-boiled eggs

### Saturday (Cheat Day!)

**Breakfast:**
- Cheat Day Pancake Stack
- Orange juice
- Coffee with cream and sugar

**Lunch:**
- Cheat Day Burger & Fries
- Milkshake

**Dinner:**
- Pizza
- Garlic bread
- Beer

**Dessert:**
- Ice cream
- Cookies

### Sunday (Back to Slow Carb)

Resume normal slow carb eating as Monday-Friday.

## Tips for Success

### Meal Prep Strategy
1. **Cook legumes in bulk** (Sunday)
   - 3 cups dry black beans → 9 cups cooked
   - Portion into containers for the week

2. **Hard-boil eggs** (18-24 eggs)
   - Quick breakfast protein
   - Emergency snacks

3. **Pre-chop vegetables**
   - Spinach, peppers, onions
   - Saves 10 minutes per meal

4. **Cook protein in batches**
   - Grill 3-4 chicken thighs at once
   - Brown 2 lbs ground beef
   - Bake salmon fillets

### Restaurant Ordering
- Mexican: Fajitas (no tortillas), side of black beans
- Steakhouse: Steak + vegetables + side salad
- Asian: Avoid (everything has white rice/noodles)
- Breakfast: Eggs + vegetables + black beans (ask to substitute)

### Common Mistakes
1. **Not eating enough protein at breakfast**
   - Minimum 30g to trigger fat loss
   - Don't skimp on eggs

2. **Forgetting legumes**
   - Without them, you'll be constipated
   - They're not optional

3. **Eating too little**
   - Slow carb is not calorie restriction
   - Eat until satisfied (not stuffed)

4. **Skipping cheat day**
   - Don't be "too good"
   - Cheat day prevents metabolic slowdown

5. **Eating fruit**
   - "But it's healthy!" - doesn't matter
   - Fructose interferes with fat loss

## Expected Results

**Tim Ferriss's claims (from 4-Hour Body):**
- 10-20 lbs lost in first month
- Primarily fat loss (not muscle)
- Visible results in 2 weeks
- Sustainable long-term

**Average macros from our recipes:**
- Breakfast: 38g protein, 27g carbs, 16g fat (413 cal)
- Lunch: 42g protein, 30g carbs, 16g fat (445 cal)
- Dinner: 44g protein, 32g carbs, 19g fat (485 cal)

**Daily total (3 meals):**
- 124g protein
- 89g carbs (all slow-burning)
- 51g fat
- 1,343 calories

*Note: Actual calorie needs vary by bodyweight, activity, and goals.*

## References

- **Book:** "The 4-Hour Body" by Tim Ferriss (2010)
- **Chapter 2:** "The Slow-Carb Diet"
- **Key sections:**
  - "The Four Horsemen of Fat-Loss" (pages 72-92)
  - "The Last Mile" (pages 107-120)
  - "Damage Control" (pages 121-140)

## Tags Reference

| Tag | Meaning | Count |
|-----|---------|-------|
| `slow_carb` | Core compliant meal | 15 |
| `tim_ferriss` | From 4-Hour Body | 17 |
| `high_protein` | 30g+ protein | 13 |
| `legumes` | Contains beans/lentils | 13 |
| `cheat_day` | Saturday indulgence | 2 |
| `vegetarian` | No meat | 3 |

---

**Migration file:** `/gleam/migrations_pg/013_add_tim_ferriss_recipes.sql`

**To apply:**
```bash
cd /home/lewis/src/meal-planner/gleam
psql -U your_user -d meal_planner -f migrations_pg/013_add_tim_ferriss_recipes.sql
```
