-- Schema change 008: Create custom_foods table
-- User-defined custom foods with complete nutritional information including 21 micronutrients

CREATE TABLE IF NOT EXISTS custom_foods (
    -- Identity and ownership
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,

    -- Basic information
    name TEXT NOT NULL,
    brand TEXT,
    description TEXT,

    -- Serving information
    serving_size REAL NOT NULL,
    serving_unit TEXT NOT NULL,

    -- Macronutrients
    protein REAL NOT NULL,
    fat REAL NOT NULL,
    carbs REAL NOT NULL,
    calories REAL NOT NULL,

    -- Dietary components
    fiber REAL,
    sugar REAL,
    sodium REAL,
    cholesterol REAL,

    -- Vitamins
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

    -- Minerals
    calcium REAL,
    iron REAL,
    magnesium REAL,
    phosphorus REAL,
    potassium REAL,
    zinc REAL,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_custom_foods_user ON custom_foods(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_foods_name ON custom_foods(name);
CREATE INDEX IF NOT EXISTS idx_custom_foods_created ON custom_foods(created_at);
