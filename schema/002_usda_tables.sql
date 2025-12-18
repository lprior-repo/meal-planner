-- USDA FoodData Central schema for PostgreSQL
-- Optimized for parallel bulk imports

-- Nutrient definitions
CREATE TABLE IF NOT EXISTS nutrients (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    unit_name TEXT NOT NULL,
    nutrient_nbr TEXT,
    rank INTEGER
);

-- Food items with partitioning hint
CREATE TABLE IF NOT EXISTS foods (
    fdc_id INTEGER PRIMARY KEY,
    data_type TEXT NOT NULL,
    description TEXT NOT NULL,
    food_category TEXT,
    publication_date TEXT
);

-- Create GIN index for fast full-text search (PostgreSQL native FTS)
CREATE INDEX IF NOT EXISTS idx_foods_description_gin
ON foods USING gin(to_tsvector('english', description));

-- B-tree indexes for filtering
CREATE INDEX IF NOT EXISTS idx_foods_data_type ON foods(data_type);
CREATE INDEX IF NOT EXISTS idx_foods_category ON foods(food_category);

-- Food nutrient values (largest table - optimized for bulk loading)
CREATE UNLOGGED TABLE IF NOT EXISTS food_nutrients_staging (
    id INTEGER,
    fdc_id INTEGER,
    nutrient_id INTEGER,
    amount REAL
);

CREATE TABLE IF NOT EXISTS food_nutrients (
    id INTEGER PRIMARY KEY,
    fdc_id INTEGER NOT NULL REFERENCES foods(fdc_id) ON DELETE CASCADE,
    nutrient_id INTEGER NOT NULL REFERENCES nutrients(id) ON DELETE CASCADE,
    amount REAL
);

-- Indexes for lookups (created after bulk load for speed)
CREATE INDEX IF NOT EXISTS idx_food_nutrients_fdc_id ON food_nutrients(fdc_id);
CREATE INDEX IF NOT EXISTS idx_food_nutrients_nutrient_id ON food_nutrients(nutrient_id);
