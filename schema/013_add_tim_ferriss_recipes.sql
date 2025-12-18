-- OBSOLETE: This schema change is no longer used.
-- Schema change: Add Tim Ferriss Slow Carb Diet Recipe Examples
-- Based on "The 4-Hour Body" principles:
-- - High protein (30g+ per meal)
-- - Legumes (black beans, lentils, pinto beans)
-- - Vegetables (green preferred)
-- - NO white carbs (bread, rice, potatoes, pasta)
-- - NO fruit (except cheat day)
-- - NO dairy (except cottage cheese)
-- - Breakfast within 30 minutes of waking (eggs preferred)

-- Add tags column to recipes_simplified if it doesn't exist
ALTER TABLE recipes_simplified
ADD COLUMN IF NOT EXISTS tags VARCHAR(500);

-- Add description column for recipe details
ALTER TABLE recipes_simplified
ADD COLUMN IF NOT EXISTS description TEXT;

-- Tim Ferriss Slow Carb Recipes
INSERT INTO recipes_simplified (name, calories, protein, carbs, fat, verified, branded, category, tags, description)
VALUES
    -- HIGH-PROTEIN BREAKFASTS (Eggs + Legumes - eaten within 30 min of waking)
    (
        'Slow Carb Breakfast Bowl',
        420,
        38,
        28,
        18,
        TRUE,
        FALSE,
        'breakfast',
        'slow_carb,tim_ferriss,high_protein,legumes',
        '3 scrambled eggs with 1 cup black beans, spinach, and salsa. The foundational 4-Hour Body breakfast.'
    ),
    (
        'Mexican Breakfast Scramble',
        445,
        42,
        32,
        16,
        TRUE,
        FALSE,
        'breakfast',
        'slow_carb,tim_ferriss,high_protein,legumes,mexican',
        '4 eggs scrambled with black beans, diced tomatoes, jalapeños, cilantro, and hot sauce.'
    ),
    (
        'Lentil & Egg Power Breakfast',
        395,
        35,
        30,
        14,
        TRUE,
        FALSE,
        'breakfast',
        'slow_carb,tim_ferriss,high_protein,legumes',
        '3 fried eggs over 3/4 cup cooked lentils with sautéed spinach and garlic.'
    ),
    (
        'Cottage Cheese Protein Scramble',
        380,
        40,
        18,
        16,
        TRUE,
        FALSE,
        'breakfast',
        'slow_carb,tim_ferriss,high_protein,dairy_allowed',
        '4 eggs scrambled with 1/2 cup low-fat cottage cheese, black beans, and steamed broccoli.'
    ),
    (
        'Breakfast Burrito Bowl (No Tortilla)',
        425,
        38,
        35,
        15,
        TRUE,
        FALSE,
        'breakfast',
        'slow_carb,tim_ferriss,high_protein,legumes,mexican',
        '3 eggs, pinto beans, avocado, salsa verde, cilantro - all the burrito flavor, none of the carbs.'
    ),

    -- LEAN PROTEIN MAINS
    (
        'Grass-Fed Beef & Black Bean Bowl',
        485,
        48,
        28,
        20,
        TRUE,
        FALSE,
        'lunch',
        'slow_carb,tim_ferriss,high_protein,legumes,beef',
        '6oz grass-fed ground beef with black beans, mixed greens, and guacamole.'
    ),
    (
        'Grilled Chicken Thigh with Lentils',
        450,
        42,
        32,
        16,
        TRUE,
        FALSE,
        'lunch',
        'slow_carb,tim_ferriss,high_protein,legumes,chicken',
        '2 grilled chicken thighs with French green lentils and roasted Brussels sprouts.'
    ),
    (
        'Pan-Seared Salmon with White Beans',
        520,
        45,
        30,
        24,
        TRUE,
        FALSE,
        'dinner',
        'slow_carb,tim_ferriss,high_protein,legumes,fish,omega3',
        '6oz wild salmon with cannellini beans, garlic, and kale sautéed in olive oil.'
    ),
    (
        'Slow Cooker Pork & Pinto Beans',
        465,
        44,
        35,
        16,
        TRUE,
        FALSE,
        'dinner',
        'slow_carb,tim_ferriss,high_protein,legumes,pork',
        'Tender pulled pork shoulder with pinto beans, cumin, and roasted peppers.'
    ),
    (
        'Turkey & Lentil Chili',
        410,
        40,
        38,
        12,
        TRUE,
        FALSE,
        'dinner',
        'slow_carb,tim_ferriss,high_protein,legumes,turkey',
        'Lean ground turkey with red lentils, tomatoes, chili spices, and tons of veggies.'
    ),

    -- LEGUME-FOCUSED SIDES & MAINS
    (
        'Garlicky Black Beans with Spinach',
        280,
        18,
        42,
        4,
        TRUE,
        FALSE,
        'side',
        'slow_carb,tim_ferriss,legumes,vegetarian,high_fiber',
        '1.5 cups black beans sautéed with garlic, cumin, and 2 cups fresh spinach.'
    ),
    (
        'Spicy Lentil Soup',
        320,
        22,
        48,
        6,
        TRUE,
        FALSE,
        'lunch',
        'slow_carb,tim_ferriss,legumes,vegetarian,high_fiber',
        'Red lentils with tomatoes, curry spices, coconut milk, and cauliflower.'
    ),
    (
        'White Bean & Vegetable Medley',
        295,
        20,
        45,
        5,
        TRUE,
        FALSE,
        'side',
        'slow_carb,tim_ferriss,legumes,vegetarian,high_fiber',
        'Cannellini beans with zucchini, bell peppers, onions, and Italian herbs.'
    ),

    -- VEGETABLE-HEAVY DISHES
    (
        'Massive Spinach Salad with Chicken',
        385,
        42,
        18,
        16,
        TRUE,
        FALSE,
        'lunch',
        'slow_carb,tim_ferriss,high_protein,low_carb,vegetables',
        '6oz grilled chicken over 4 cups baby spinach with cucumbers, peppers, olive oil & vinegar.'
    ),
    (
        'Cauliflower Steak with Beef',
        425,
        38,
        22,
        22,
        TRUE,
        FALSE,
        'dinner',
        'slow_carb,tim_ferriss,high_protein,low_carb,vegetables',
        '5oz grass-fed beef with thick-cut roasted cauliflower steak and chimichurri sauce.'
    ),

    -- CHEAT DAY RECIPES (Optional - for Saturday indulgence)
    (
        'Cheat Day Pancake Stack',
        820,
        18,
        110,
        32,
        FALSE,
        FALSE,
        'breakfast',
        'cheat_day,tim_ferriss,indulgence',
        'Buttermilk pancakes with butter, syrup, and berries. Only on cheat day!'
    ),
    (
        'Cheat Day Burger & Fries',
        950,
        42,
        85,
        48,
        FALSE,
        FALSE,
        'lunch',
        'cheat_day,tim_ferriss,indulgence',
        'Double cheeseburger with bun, fries, and all the toppings. Saturday only!'
    );

-- Create index on tags for filtering slow carb recipes
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_tags ON recipes_simplified USING gin(to_tsvector('english', tags));

-- Verify Tim Ferriss recipes were added
SELECT
    COUNT(*) as total_tim_ferriss_recipes,
    COUNT(CASE WHEN tags LIKE '%slow_carb%' AND tags NOT LIKE '%cheat_day%' THEN 1 END) as slow_carb_recipes,
    COUNT(CASE WHEN tags LIKE '%cheat_day%' THEN 1 END) as cheat_day_recipes
FROM recipes_simplified
WHERE tags LIKE '%tim_ferriss%';

-- Show sample of Tim Ferriss breakfast recipes
SELECT name, calories, protein, carbs, fat, category, description
FROM recipes_simplified
WHERE tags LIKE '%tim_ferriss%' AND category = 'breakfast' AND tags NOT LIKE '%cheat_day%'
ORDER BY name;

-- Nutritional summary statistics for slow carb recipes
SELECT
    category,
    COUNT(*) as recipe_count,
    ROUND(AVG(protein), 1) as avg_protein,
    ROUND(AVG(carbs), 1) as avg_carbs,
    ROUND(AVG(fat), 1) as avg_fat,
    ROUND(AVG(calories), 0) as avg_calories
FROM recipes_simplified
WHERE tags LIKE '%slow_carb%' AND tags NOT LIKE '%cheat_day%'
GROUP BY category
ORDER BY category;
