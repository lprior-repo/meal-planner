-- Migration 008: Custom Foods Table
-- Allows users to create and store custom food entries with nutrition data

CREATE TABLE IF NOT EXISTS custom_foods (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    brand TEXT,  -- Optional brand name
    description TEXT,  -- Optional description
    serving_size REAL NOT NULL,  -- e.g., 100, 1.5, 2
    serving_unit TEXT NOT NULL,  -- e.g., 'g', 'oz', 'cup', 'piece'
    
    -- Macronutrients (per serving)
    protein REAL NOT NULL,
    fat REAL NOT NULL,
    carbs REAL NOT NULL,
    calories REAL NOT NULL,
    
    -- Micronutrients (optional, per serving)
    fiber REAL,
    sugar REAL,
    sodium REAL,
    cholesterol REAL,
    vitamin_a REAL,
    vitamin_c REAL,
    vitamin_d REAL,
    vitamin_e REAL,
    vitamin_k REAL,
    vitamin_b6 REAL,
    vitamin_b12 REAL,
    folate REAL,
    thiamin REAL,
    riboflavin REAL,
    niacin REAL,
    calcium REAL,
    iron REAL,
    magnesium REAL,
    phosphorus REAL,
    potassium REAL,
    zinc REAL,
    
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index for user-scoped queries
CREATE INDEX IF NOT EXISTS idx_custom_foods_user ON custom_foods(user_id);

-- Index for name search
CREATE INDEX IF NOT EXISTS idx_custom_foods_name ON custom_foods(name);

-- Compound index for user + name search
CREATE INDEX IF NOT EXISTS idx_custom_foods_user_name ON custom_foods(user_id, name);
