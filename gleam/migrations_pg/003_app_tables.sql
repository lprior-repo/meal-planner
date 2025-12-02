-- Application tables for meal planner

-- Nutrition state tracking
CREATE TABLE IF NOT EXISTS nutrition_state (
    date DATE PRIMARY KEY,
    protein REAL NOT NULL,
    fat REAL NOT NULL,
    carbs REAL NOT NULL,
    calories REAL NOT NULL,
    synced_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Nutrition goals (singleton)
CREATE TABLE IF NOT EXISTS nutrition_goals (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    daily_protein REAL NOT NULL,
    daily_fat REAL NOT NULL,
    daily_carbs REAL NOT NULL,
    daily_calories REAL NOT NULL
);

-- Recipes
CREATE TABLE IF NOT EXISTS recipes (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    ingredients TEXT NOT NULL,
    instructions TEXT NOT NULL,
    protein REAL NOT NULL,
    fat REAL NOT NULL,
    carbs REAL NOT NULL,
    servings INTEGER NOT NULL,
    category TEXT NOT NULL,
    fodmap_level TEXT NOT NULL,
    vertical_compliant BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_recipes_category ON recipes(category);
CREATE INDEX IF NOT EXISTS idx_recipes_fodmap ON recipes(fodmap_level);

-- User profile (singleton)
CREATE TABLE IF NOT EXISTS user_profile (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    bodyweight REAL NOT NULL,
    activity_level TEXT NOT NULL,
    goal TEXT NOT NULL,
    meals_per_day INTEGER NOT NULL
);

-- Food logs
CREATE TABLE IF NOT EXISTS food_logs (
    id TEXT PRIMARY KEY,
    date DATE NOT NULL,
    recipe_id TEXT NOT NULL,
    recipe_name TEXT NOT NULL,
    servings REAL NOT NULL,
    protein REAL NOT NULL,
    fat REAL NOT NULL,
    carbs REAL NOT NULL,
    meal_type TEXT NOT NULL,
    logged_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_food_logs_date ON food_logs(date);
CREATE INDEX IF NOT EXISTS idx_food_logs_recipe ON food_logs(recipe_id);
