-- Migration 009: Auto Meal Planner Schema
-- Adds tables for recipe sources, auto-generated meal plans, and diet compliance tracking

-- Recipe sources table for API/scraper configuration
CREATE TABLE IF NOT EXISTS recipe_sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL CHECK(type IN ('api', 'scraper', 'manual')),
    config TEXT, -- JSON config for API keys, endpoints, etc.
    enabled BOOLEAN NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Auto-generated meal plans
CREATE TABLE IF NOT EXISTS auto_meal_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    diet_principles TEXT NOT NULL, -- JSON array: ["vertical_diet", "tim_ferriss"]
    recipe_ids TEXT NOT NULL, -- JSON array of 4 recipe IDs
    macro_targets TEXT, -- JSON object with protein/carbs/fat targets
    status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'archived')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Recipe diet compliance tracking
CREATE TABLE IF NOT EXISTS recipe_diet_compliance (
    recipe_id INTEGER PRIMARY KEY,
    vertical_diet_compliant BOOLEAN NOT NULL DEFAULT 0,
    tim_ferriss_compliant BOOLEAN NOT NULL DEFAULT 0,
    compliance_notes TEXT, -- JSON or text notes explaining compliance status
    last_checked TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
);

-- Indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_recipe_sources_type ON recipe_sources(type);
CREATE INDEX IF NOT EXISTS idx_recipe_sources_enabled ON recipe_sources(enabled);
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_user_id ON auto_meal_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_status ON auto_meal_plans(status);
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_generated_at ON auto_meal_plans(generated_at);
CREATE INDEX IF NOT EXISTS idx_recipe_diet_compliance_vertical ON recipe_diet_compliance(vertical_diet_compliant);
CREATE INDEX IF NOT EXISTS idx_recipe_diet_compliance_ferriss ON recipe_diet_compliance(tim_ferriss_compliant);

-- Trigger to update updated_at timestamp on recipe_sources
CREATE TRIGGER IF NOT EXISTS update_recipe_sources_timestamp
    AFTER UPDATE ON recipe_sources
    FOR EACH ROW
BEGIN
    UPDATE recipe_sources SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
