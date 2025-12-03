-- Migration 007: Insert Vertical Diet recipes
-- 25 recipes following Stan Efferding's Vertical Diet principles

-- ============================================================================
-- RED MEAT MAIN DISHES (12 recipes)
-- ============================================================================

-- 1. Classic Grilled Ribeye
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-ribeye-01', 'Classic Grilled Ribeye',
 'ribeye steak:8 oz|sea salt:1 tsp|black pepper:1/2 tsp|olive oil:1 tbsp',
 'Let steak come to room temperature for 30 minutes|Season generously with salt and pepper|Heat grill or cast iron skillet to high heat|Brush steak with olive oil|Grill 4-5 minutes per side for medium-rare|Rest for 5 minutes before serving',
 48.0, 32.0, 0.0, 1, 'beef-main', 'low', TRUE);

-- 2. Pan-Seared Strip Steak
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-strip-02', 'Pan-Seared Strip Steak',
 'NY strip steak:8 oz|butter:2 tbsp|garlic:2 cloves|sea salt:1 tsp',
 'Pat steak dry and season with salt|Heat cast iron skillet until smoking|Sear steak 3-4 minutes per side|Add butter and garlic to pan|Baste steak with melted butter|Rest 5 minutes before slicing',
 50.0, 34.0, 1.0, 1, 'beef-main', 'low', TRUE);

-- 3. Ground Beef and Rice Bowl
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-beef-rice-03', 'Ground Beef and Rice Bowl',
 'lean ground beef (90/10):6 oz|cooked white rice:1 cup|sea salt:1 tsp|olive oil:1 tbsp',
 'Heat olive oil in skillet over medium-high heat|Add ground beef and break into small pieces|Cook until browned, about 8 minutes|Season with salt|Serve over white rice',
 40.0, 18.0, 45.0, 1, 'beef-main', 'low', TRUE);

-- 4. Simple Beef Patties
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-patties-04', 'Simple Beef Patties',
 'ground beef (85/15):8 oz|sea salt:1 tsp|black pepper:1/2 tsp|olive oil:1 tbsp',
 'Form beef into 2 thick patties|Season both sides with salt and pepper|Heat oil in skillet over medium-high heat|Cook patties 4-5 minutes per side|Rest 3 minutes before serving',
 46.0, 30.0, 0.0, 2, 'beef-main', 'low', TRUE);

-- 5. Bison Burger Patty
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-bison-05', 'Bison Burger Patty',
 'ground bison:6 oz|sea salt:3/4 tsp|olive oil:1 tsp',
 'Form bison into a thick patty|Season with salt|Heat oil in skillet over medium heat|Cook 3-4 minutes per side (bison is lean, don''t overcook)|Rest 3 minutes before serving',
 38.0, 12.0, 0.0, 1, 'bison-main', 'low', TRUE);

-- 6. Grilled Bison Steak
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-bison-steak-06', 'Grilled Bison Steak',
 'bison sirloin steak:8 oz|sea salt:1 tsp|butter:1 tbsp',
 'Let steak reach room temperature|Season with salt|Grill over high heat 3 minutes per side|Top with butter and let rest 5 minutes',
 48.0, 16.0, 0.0, 1, 'bison-main', 'low', TRUE);

-- 7. Lamb Chops with Sea Salt
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-lamb-07', 'Lamb Chops with Sea Salt',
 'lamb loin chops:8 oz (3-4 chops)|sea salt:1 tsp|olive oil:1 tbsp',
 'Bring lamb to room temperature|Season generously with salt|Heat oil in skillet over high heat|Sear chops 3 minutes per side|Rest 5 minutes before serving',
 42.0, 28.0, 0.0, 1, 'lamb-main', 'low', TRUE);

-- 8. Simple Ground Lamb
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-ground-lamb-08', 'Simple Ground Lamb',
 'ground lamb:6 oz|sea salt:3/4 tsp|black pepper:1/4 tsp',
 'Heat skillet over medium-high heat|Add ground lamb and break into pieces|Cook until browned, about 8 minutes|Season with salt and pepper|Drain excess fat if desired',
 36.0, 24.0, 0.0, 1, 'lamb-main', 'low', TRUE);

-- 9. Beef and Spinach Skillet
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-beef-spinach-09', 'Beef and Spinach Skillet',
 'ground beef (90/10):6 oz|fresh spinach:2 cups|sea salt:1 tsp|olive oil:1 tbsp',
 'Brown ground beef in olive oil|Season with salt|Add spinach and cook until wilted, 2 minutes|Mix well and serve',
 42.0, 20.0, 2.0, 1, 'beef-main', 'low', TRUE);

-- 10. Ribeye with Bone Broth Reduction
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-ribeye-broth-10', 'Ribeye with Bone Broth Reduction',
 'ribeye steak:8 oz|beef bone broth:1/2 cup|sea salt:1 tsp|butter:2 tbsp',
 'Season and sear ribeye as usual|Remove steak and rest|Add bone broth to hot pan|Reduce by half, about 3 minutes|Whisk in butter|Pour over steak',
 48.0, 38.0, 1.0, 1, 'beef-main', 'low', TRUE);

-- 11. Grilled Sirloin Tips
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-sirloin-tips-11', 'Grilled Sirloin Tips',
 'sirloin tips:8 oz|sea salt:1 tsp|olive oil:2 tbsp',
 'Cut sirloin into 2-inch cubes|Toss with olive oil and salt|Grill over high heat, turning occasionally|Cook to desired doneness, about 8 minutes total',
 46.0, 20.0, 0.0, 1, 'beef-main', 'low', TRUE);

-- 12. Beef Chuck Roast
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-chuck-roast-12', 'Simple Beef Chuck Roast',
 'beef chuck roast:3 lbs|sea salt:2 tbsp|beef bone broth:2 cups|carrots:1 lb, large chunks',
 'Season roast generously with salt|Place in slow cooker with broth and carrots|Cook on low for 8 hours|Shred meat and serve with cooking liquid',
 52.0, 28.0, 6.0, 8, 'beef-main', 'low', TRUE);

-- ============================================================================
-- WHITE RICE PREPARATIONS (6 recipes)
-- ============================================================================

-- 13. Simple White Rice
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-rice-01', 'Simple White Rice',
 'white rice:1 cup dry|water:2 cups|sea salt:1/2 tsp',
 'Rinse rice until water runs clear|Combine rice, water, and salt in pot|Bring to boil, then reduce to simmer|Cover and cook 18 minutes|Let rest 5 minutes, fluff with fork',
 8.0, 1.0, 90.0, 4, 'rice-side', 'low', TRUE);

-- 14. Bone Broth Rice
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-rice-broth-02', 'Bone Broth Rice',
 'white rice:1 cup dry|beef bone broth:2 cups|sea salt:1/4 tsp',
 'Rinse rice thoroughly|Combine rice, bone broth, and salt|Bring to boil, reduce to simmer|Cover and cook 18 minutes|Fluff and serve',
 10.0, 2.0, 90.0, 4, 'rice-side', 'low', TRUE);

-- 15. Butter Rice
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-rice-butter-03', 'Butter Rice',
 'white rice:1 cup dry|water:2 cups|butter:3 tbsp|sea salt:1/2 tsp',
 'Cook rice as usual in water with salt|When done, stir in butter until melted|Let rest 5 minutes|Fluff and serve',
 8.0, 12.0, 90.0, 4, 'rice-side', 'low', TRUE);

-- 16. Salty Rice
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-rice-salty-04', 'Salty Rice (Electrolyte-Enhanced)',
 'white rice:1 cup dry|water:2 cups|sea salt:1 tsp',
 'Rinse rice well|Cook with water and salt|The higher salt content aids electrolyte balance|Perfect post-workout',
 8.0, 1.0, 90.0, 4, 'rice-side', 'low', TRUE);

-- 17. Spinach Rice
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-rice-spinach-05', 'Spinach Rice',
 'cooked white rice:2 cups|fresh spinach:2 cups|butter:2 tbsp|sea salt:1/2 tsp',
 'Heat butter in pan|Add spinach and cook until wilted|Stir in cooked rice|Season with salt and mix well',
 6.0, 7.0, 46.0, 2, 'rice-side', 'low', TRUE);

-- 18. Carrot-Infused Rice
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-rice-carrot-06', 'Carrot-Infused Rice',
 'white rice:1 cup dry|carrot juice:1 cup|water:1 cup|sea salt:1/2 tsp',
 'Combine rice, carrot juice, water, and salt|Bring to boil, reduce to simmer|Cover and cook 18 minutes|Rice will have orange color and mild carrot flavor',
 10.0, 1.0, 98.0, 4, 'rice-side', 'low', TRUE);

-- ============================================================================
-- VEGETABLE SIDES (7 recipes)
-- ============================================================================

-- 19. Simple Steamed Carrots
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-veg-carrots-01', 'Simple Steamed Carrots',
 'carrots:1 lb, sliced|water:1 cup|sea salt:1/2 tsp|butter:1 tbsp',
 'Steam carrots until tender, about 8 minutes|Toss with butter and salt|Serve immediately',
 2.0, 3.0, 20.0, 4, 'vegetable-side', 'low', TRUE);

-- 20. Sautéed Spinach
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-veg-spinach-01', 'Sautéed Spinach',
 'fresh spinach:1 lb|olive oil:2 tbsp|sea salt:1/2 tsp',
 'Heat olive oil in large pan|Add spinach in batches|Cook until wilted, about 3 minutes|Season with salt',
 6.0, 8.0, 8.0, 4, 'vegetable-side', 'low', TRUE);

-- 21. Roasted Carrots
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-veg-carrots-roast-02', 'Roasted Carrots',
 'carrots:1 lb, whole or halved|olive oil:2 tbsp|sea salt:1 tsp',
 'Preheat oven to 425°F|Toss carrots with oil and salt|Roast 25-30 minutes until tender and caramelized|Turn once halfway through',
 2.0, 8.0, 20.0, 4, 'vegetable-side', 'low', TRUE);

-- 22. Steamed Zucchini
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-veg-zucchini-01', 'Steamed Zucchini',
 'zucchini:2 medium, sliced|water:1 cup|sea salt:1/4 tsp|butter:1 tbsp',
 'Steam zucchini until tender, 5-6 minutes|Toss with butter and salt|Serve hot',
 2.0, 3.0, 8.0, 2, 'vegetable-side', 'low', TRUE);

-- 23. Butter Glazed Carrots
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-veg-carrots-butter-03', 'Butter Glazed Carrots',
 'carrots:1 lb, sliced|butter:3 tbsp|sea salt:1/2 tsp',
 'Steam carrots until tender|Melt butter in pan|Add carrots and toss to coat|Cook 2 minutes until glazed|Season with salt',
 2.0, 9.0, 20.0, 4, 'vegetable-side', 'low', TRUE);

-- 24. Sautéed Bok Choy
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-veg-bokchoy-01', 'Sautéed Bok Choy',
 'bok choy:1 lb, chopped|olive oil:1 tbsp|sea salt:1/4 tsp',
 'Heat oil in wok or large pan|Add bok choy|Sauté 4-5 minutes until tender|Season with salt',
 3.0, 4.0, 6.0, 2, 'vegetable-side', 'low', TRUE);

-- 25. Carrot Mash
INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant) VALUES
('vd-veg-carrots-mash-04', 'Carrot Mash',
 'carrots:2 lbs, chopped|butter:4 tbsp|sea salt:1 tsp',
 'Boil carrots until very soft, 20 minutes|Drain well|Mash with butter and salt|Serve as alternative to mashed potatoes',
 4.0, 12.0, 40.0, 6, 'vegetable-side', 'low', TRUE);
