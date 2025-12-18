-- OBSOLETE: This schema change is no longer used.
-- Schema change: Add Vertical Diet Example Recipes
-- Stan Efferding's Vertical Diet principles: red meat, white rice, easy digestion, low FODMAP
-- Focus: nutrient density, easy digestion, performance optimization

-- Insert into recipes_simplified table for immediate use
INSERT INTO recipes_simplified (name, calories, protein, carbs, fat, verified, branded, category)
VALUES
    -- RED MEAT MAINS (Beef & Bison)
    ('Vertical Diet Ground Beef Bowl', 680, 52, 68, 24, TRUE, FALSE, 'lunch'),
    ('Bison Burger with White Rice', 720, 55, 75, 18, TRUE, FALSE, 'dinner'),
    ('Simple Ribeye Steak with Sweet Potato', 850, 58, 62, 38, TRUE, FALSE, 'dinner'),
    ('Ground Beef and White Rice - Classic', 620, 48, 64, 20, TRUE, FALSE, 'lunch'),
    ('Bison Sirloin with Mashed Potatoes', 680, 54, 58, 22, TRUE, FALSE, 'dinner'),

    -- POST-WORKOUT MEALS (High protein + simple carbs)
    ('Post-Workout Beef and Rice', 750, 60, 85, 15, TRUE, FALSE, 'lunch'),
    ('Monster Mash - Beef, Rice & Sweet Potato', 920, 65, 112, 18, TRUE, FALSE, 'dinner'),
    ('Anabolic Ground Beef Power Bowl', 800, 68, 78, 22, TRUE, FALSE, 'lunch'),

    -- SIMPLE CARB SIDES
    ('White Rice with Butter and Salt', 280, 4, 58, 4, TRUE, FALSE, 'snack'),
    ('Baked Sweet Potato with Butter', 220, 3, 42, 5, TRUE, FALSE, 'snack'),
    ('White Potato Mash - Plain', 180, 4, 38, 2, TRUE, FALSE, 'snack'),

    -- EASY VEGETABLES (Low FODMAP)
    ('Steamed Carrots with Salt', 85, 2, 18, 1, TRUE, FALSE, 'snack'),
    ('Sautéed Spinach with Olive Oil', 120, 4, 8, 9, TRUE, FALSE, 'snack'),

    -- COMPLETE VERTICAL DIET MEALS
    ('Efferding Special - Beef, Rice, Carrots', 780, 56, 88, 20, TRUE, FALSE, 'dinner'),
    ('Monster Maker - Double Beef with Sweet Potato', 1050, 82, 95, 28, TRUE, FALSE, 'dinner')
ON CONFLICT (name) DO NOTHING;

-- Also insert into main recipes table with full details
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant)
VALUES
    -- 1. VERTICAL DIET GROUND BEEF BOWL
    (
        'vd-001',
        'Vertical Diet Ground Beef Bowl',
        '8oz (227g) 85/15 ground beef, 1.5 cups cooked white rice, 1 tsp salt, 1/2 cup steamed carrots',
        '1. Cook ground beef in skillet over medium-high heat until browned (8-10 min)
2. Season with salt while cooking
3. Cook white rice according to package directions
4. Steam carrots until tender (5-7 min)
5. Combine in bowl: rice base, beef on top, carrots on side
6. Serve hot

Macro per serving: 52g protein, 24g fat, 68g carbs, 680 calories',
        52.0,
        24.0,
        68.0,
        1,
        'lunch',
        'low',
        TRUE
    ),

    -- 2. BISON BURGER WITH WHITE RICE
    (
        'vd-002',
        'Bison Burger with White Rice',
        '8oz (227g) ground bison, 2 cups cooked white rice, 1 tsp salt, 1/2 tbsp olive oil',
        '1. Form bison into patty, season with salt
2. Heat olive oil in skillet over medium-high heat
3. Cook patty 4-5 minutes per side for medium
4. Let rest 3 minutes before serving
5. Serve alongside white rice
6. Optional: top with more salt to taste

Macro per serving: 55g protein, 18g fat, 75g carbs, 720 calories',
        55.0,
        18.0,
        75.0,
        1,
        'dinner',
        'low',
        TRUE
    ),

    -- 3. SIMPLE RIBEYE STEAK WITH SWEET POTATO
    (
        'vd-003',
        'Simple Ribeye Steak with Sweet Potato',
        '10oz (284g) ribeye steak, 1 large sweet potato (300g), 1 tbsp butter, salt to taste',
        '1. Preheat oven to 400°F for sweet potato
2. Pierce sweet potato with fork, bake 45-60 minutes until soft
3. Season ribeye generously with salt
4. Heat cast iron skillet to high heat
5. Sear ribeye 3-4 minutes per side for medium-rare
6. Let rest 5 minutes before serving
7. Serve with baked sweet potato topped with butter

Macro per serving: 58g protein, 38g fat, 62g carbs, 850 calories',
        58.0,
        38.0,
        62.0,
        1,
        'dinner',
        'low',
        TRUE
    ),

    -- 4. GROUND BEEF AND WHITE RICE CLASSIC
    (
        'vd-004',
        'Ground Beef and White Rice - Classic',
        '7oz (200g) 90/10 ground beef, 1.5 cups cooked white rice, 1 tsp salt, black pepper to taste',
        '1. Heat skillet over medium-high heat
2. Add ground beef, break up with spatula
3. Season with salt and pepper while cooking
4. Cook until browned and no pink remains (7-9 min)
5. Drain excess fat if desired
6. Serve over white rice
7. Mix together or keep separate

Macro per serving: 48g protein, 20g fat, 64g carbs, 620 calories',
        48.0,
        20.0,
        64.0,
        1,
        'lunch',
        'low',
        TRUE
    ),

    -- 5. BISON SIRLOIN WITH MASHED POTATOES
    (
        'vd-005',
        'Bison Sirloin with Mashed Potatoes',
        '8oz (227g) bison sirloin, 2 medium white potatoes (400g), 2 tbsp butter, 1/4 cup whole milk, salt',
        '1. Boil potatoes until fork-tender (15-20 min)
2. While potatoes cook, season bison with salt
3. Grill or pan-sear bison 4-5 minutes per side
4. Drain potatoes, add butter and milk
5. Mash until smooth, season with salt
6. Let bison rest 3 minutes before serving
7. Serve together

Macro per serving: 54g protein, 22g fat, 58g carbs, 680 calories',
        54.0,
        22.0,
        58.0,
        1,
        'dinner',
        'low',
        TRUE
    ),

    -- 6. POST-WORKOUT BEEF AND RICE
    (
        'vd-006',
        'Post-Workout Beef and Rice',
        '9oz (255g) 93/7 ground beef, 2.25 cups cooked white rice, 1 tsp salt, optional: hot sauce',
        '1. Cook ground beef in skillet over high heat
2. Break into small pieces for easy eating
3. Season with salt while cooking
4. Cook rice (high volume for post-workout carbs)
5. Combine beef and rice in large bowl
6. Mix thoroughly
7. Consume within 30-60 minutes post-workout

Macro per serving: 60g protein, 15g fat, 85g carbs, 750 calories',
        60.0,
        15.0,
        85.0,
        1,
        'lunch',
        'low',
        TRUE
    ),

    -- 7. MONSTER MASH
    (
        'vd-007',
        'Monster Mash - Beef, Rice & Sweet Potato',
        '10oz (284g) ground beef, 2 cups cooked white rice, 1 large sweet potato (300g), 1 tbsp butter, salt',
        '1. Bake sweet potato at 400°F for 45-60 minutes
2. Cook ground beef until browned, season with salt
3. Prepare white rice
4. Mash sweet potato with butter
5. In large bowl: layer rice, then beef, then sweet potato mash
6. Mix all together (the "monster mash")
7. High-volume meal for mass building

Macro per serving: 65g protein, 18g fat, 112g carbs, 920 calories',
        65.0,
        18.0,
        112.0,
        1,
        'dinner',
        'low',
        TRUE
    ),

    -- 8. ANABOLIC GROUND BEEF POWER BOWL
    (
        'vd-008',
        'Anabolic Ground Beef Power Bowl',
        '10oz (284g) 85/15 ground beef, 2 cups cooked white rice, 1/2 cup steamed spinach, 1 tsp salt',
        '1. Cook ground beef over medium-high heat until browned
2. Season generously with salt
3. Steam spinach until wilted (2-3 minutes)
4. Prepare white rice
5. Build bowl: rice base, spinach layer, beef on top
6. Optional: add more salt or pepper to taste
7. High protein for muscle building

Macro per serving: 68g protein, 22g fat, 78g carbs, 800 calories',
        68.0,
        22.0,
        78.0,
        1,
        'lunch',
        'low',
        TRUE
    ),

    -- 9. WHITE RICE WITH BUTTER AND SALT
    (
        'vd-009',
        'White Rice with Butter and Salt',
        '1.5 cups cooked white rice, 1 tbsp butter, 1/2 tsp salt',
        '1. Cook white rice according to package directions
2. Fluff with fork when done
3. Stir in butter while rice is hot
4. Season with salt
5. Let sit 2 minutes to absorb butter
6. Serve as simple carb side

Macro per serving: 4g protein, 4g fat, 58g carbs, 280 calories',
        4.0,
        4.0,
        58.0,
        1,
        'snack',
        'low',
        TRUE
    ),

    -- 10. BAKED SWEET POTATO WITH BUTTER
    (
        'vd-010',
        'Baked Sweet Potato with Butter',
        '1 large sweet potato (300g), 1 tbsp butter, salt to taste',
        '1. Preheat oven to 400°F
2. Wash sweet potato, pierce with fork
3. Place on baking sheet
4. Bake 45-60 minutes until soft when squeezed
5. Cut open, add butter and salt
6. Easy to digest carb source

Macro per serving: 3g protein, 5g fat, 42g carbs, 220 calories',
        3.0,
        5.0,
        42.0,
        1,
        'snack',
        'low',
        TRUE
    ),

    -- 11. WHITE POTATO MASH
    (
        'vd-011',
        'White Potato Mash - Plain',
        '2 medium white potatoes (400g), 1 tbsp butter, salt to taste',
        '1. Peel and cube potatoes
2. Boil in salted water until tender (15-20 min)
3. Drain well
4. Mash with butter
5. Season with salt
6. Smooth texture, easy digestion

Macro per serving: 4g protein, 2g fat, 38g carbs, 180 calories',
        4.0,
        2.0,
        38.0,
        1,
        'snack',
        'low',
        TRUE
    ),

    -- 12. STEAMED CARROTS WITH SALT
    (
        'vd-012',
        'Steamed Carrots with Salt',
        '2 cups sliced carrots (240g), 1/2 tsp salt',
        '1. Peel and slice carrots into rounds
2. Place in steamer basket over boiling water
3. Steam 5-7 minutes until tender
4. Season with salt
5. Low FODMAP vegetable option
6. Easy to digest micronutrients

Macro per serving: 2g protein, 1g fat, 18g carbs, 85 calories',
        2.0,
        1.0,
        18.0,
        1,
        'snack',
        'low',
        TRUE
    ),

    -- 13. SAUTÉED SPINACH WITH OLIVE OIL
    (
        'vd-013',
        'Sautéed Spinach with Olive Oil',
        '4 cups fresh spinach (120g), 1 tbsp olive oil, 1/2 tsp salt, 1 clove garlic (optional)',
        '1. Heat olive oil in large skillet
2. Add spinach (add garlic first if using)
3. Sauté 2-3 minutes until wilted
4. Season with salt
5. High in iron and micronutrients
6. Pairs well with red meat

Macro per serving: 4g protein, 9g fat, 8g carbs, 120 calories',
        4.0,
        9.0,
        8.0,
        1,
        'snack',
        'low',
        TRUE
    ),

    -- 14. EFFERDING SPECIAL
    (
        'vd-014',
        'Efferding Special - Beef, Rice, Carrots',
        '8oz (227g) ground beef, 2 cups cooked white rice, 1 cup steamed carrots, 1 tsp salt',
        '1. Cook ground beef in skillet until browned
2. Season with salt while cooking
3. Prepare white rice
4. Steam carrots until tender
5. Plate: rice bed, beef center, carrots around edge
6. Classic Vertical Diet meal composition
7. Complete nutrition, easy digestion

Macro per serving: 56g protein, 20g fat, 88g carbs, 780 calories',
        56.0,
        20.0,
        88.0,
        1,
        'dinner',
        'low',
        TRUE
    ),

    -- 15. MONSTER MAKER
    (
        'vd-015',
        'Monster Maker - Double Beef with Sweet Potato',
        '12oz (340g) ground beef, 2 cups cooked white rice, 1 large sweet potato (300g), 1 tbsp butter, salt',
        '1. Bake sweet potato at 400°F for 45-60 minutes
2. Cook ground beef in large skillet
3. Season beef generously with salt
4. Prepare white rice
5. Cut sweet potato open, add butter
6. Serve as massive plate: rice, double beef portion, whole sweet potato
7. For serious mass building and strength athletes

Macro per serving: 82g protein, 28g fat, 95g carbs, 1050 calories',
        82.0,
        28.0,
        95.0,
        1,
        'dinner',
        'low',
        TRUE
    )
ON CONFLICT (id) DO NOTHING;

-- Verification query
SELECT
    COUNT(*) as total_vertical_recipes,
    SUM(CASE WHEN vertical_compliant = TRUE THEN 1 ELSE 0 END) as vertical_count,
    AVG(protein) as avg_protein,
    AVG(carbs) as avg_carbs,
    AVG(fat) as avg_fat
FROM recipes
WHERE vertical_compliant = TRUE;

-- Show sample of new recipes
SELECT id, name, protein, carbs, fat, category, fodmap_level, vertical_compliant
FROM recipes
WHERE vertical_compliant = TRUE
ORDER BY name
LIMIT 5;
