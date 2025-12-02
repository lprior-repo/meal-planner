-- Application tables for meal planner
-- Recipes, user profiles, and food logging

-- Recipes table - stores meal recipes with macro information
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
    vertical_compliant INTEGER NOT NULL
);

-- User profile table - single user profile for the app
CREATE TABLE IF NOT EXISTS user_profile (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    bodyweight REAL NOT NULL,
    activity_level TEXT NOT NULL,
    goal TEXT NOT NULL,
    meals_per_day INTEGER NOT NULL
);

-- Food logs table - daily food consumption tracking
CREATE TABLE IF NOT EXISTS food_logs (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL,
    recipe_id TEXT NOT NULL,
    recipe_name TEXT NOT NULL,
    servings REAL NOT NULL,
    protein REAL NOT NULL,
    fat REAL NOT NULL,
    carbs REAL NOT NULL,
    meal_type TEXT NOT NULL,
    logged_at TEXT NOT NULL
);

-- Index for efficient date-based queries on food logs
CREATE INDEX IF NOT EXISTS idx_food_logs_date ON food_logs(date);
CREATE INDEX IF NOT EXISTS idx_food_logs_recipe ON food_logs(recipe_id);

-- Recipes index for category filtering
CREATE INDEX IF NOT EXISTS idx_recipes_category ON recipes(category);
CREATE INDEX IF NOT EXISTS idx_recipes_fodmap ON recipes(fodmap_level);
