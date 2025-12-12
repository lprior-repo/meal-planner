-- Rollback for 019_drop_recipes_table.sql
-- Restores the recipes table structure (without data)

CREATE TABLE IF NOT EXISTS recipes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    ingredients TEXT,
    instructions TEXT,
    servings INT,
    prep_time_minutes INT,
    cook_time_minutes INT,
    total_time_minutes INT,
    difficulty VARCHAR(50),
    cuisine VARCHAR(100),
    dietary_tags TEXT,
    calories_per_serving INT,
    protein_per_serving DECIMAL(10, 2),
    carbs_per_serving DECIMAL(10, 2),
    fat_per_serving DECIMAL(10, 2),
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Recreate indexes that may have existed
CREATE INDEX IF NOT EXISTS idx_recipes_name ON recipes(name);
CREATE INDEX IF NOT EXISTS idx_recipes_cuisine ON recipes(cuisine);
CREATE INDEX IF NOT EXISTS idx_recipes_difficulty ON recipes(difficulty);
CREATE INDEX IF NOT EXISTS idx_recipes_calories ON recipes(calories_per_serving);
CREATE INDEX IF NOT EXISTS idx_recipes_dietary ON recipes USING gin(to_tsvector('english', dietary_tags));
CREATE INDEX IF NOT EXISTS idx_recipes_verified ON recipes(verified);

-- Note: Original data is not restored. This only recreates the schema.
-- To restore data, you would need to recover from a backup.
