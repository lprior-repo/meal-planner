-- Schema change 009: Auto Meal Planner Schema (PostgreSQL)
-- Adds tables for recipe sources, auto-generated meal plans, and diet compliance tracking

-- Recipe sources table for API/scraper configuration
CREATE TABLE IF NOT EXISTS recipe_sources (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL CHECK(type IN ('api', 'scraper', 'manual')),
    config JSONB, -- JSON config for API keys, endpoints, etc.
    enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Auto-generated meal plans
CREATE TABLE IF NOT EXISTS auto_meal_plans (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    diet_principles JSONB NOT NULL, -- JSON array: ["vertical_diet", "tim_ferriss"]
    recipe_ids JSONB NOT NULL, -- JSON array of 4 recipe IDs
    macro_targets JSONB, -- JSON object with protein/carbs/fat targets
    status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'archived')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_recipe_sources_type ON recipe_sources(type);
CREATE INDEX IF NOT EXISTS idx_recipe_sources_enabled ON recipe_sources(enabled);
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_user_id ON auto_meal_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_status ON auto_meal_plans(status);
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_generated_at ON auto_meal_plans(generated_at);

-- GIN indexes for JSONB columns (PostgreSQL specific)
CREATE INDEX IF NOT EXISTS idx_recipe_sources_config ON recipe_sources USING GIN (config);
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_diet_principles ON auto_meal_plans USING GIN (diet_principles);
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_recipe_ids ON auto_meal_plans USING GIN (recipe_ids);
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_macro_targets ON auto_meal_plans USING GIN (macro_targets);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at timestamp on recipe_sources
DROP TRIGGER IF EXISTS update_recipe_sources_timestamp ON recipe_sources;
CREATE TRIGGER update_recipe_sources_timestamp
    BEFORE UPDATE ON recipe_sources
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
