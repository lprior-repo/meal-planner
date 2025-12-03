-- Migration 006: Create auto meal planner tables
-- Creates tables for auto-generated meal plans and recipe sources

-- Auto meal plans table
CREATE TABLE IF NOT EXISTS auto_meal_plans (
    id TEXT PRIMARY KEY,
    recipe_ids TEXT NOT NULL,  -- Comma-separated recipe IDs
    generated_at TEXT NOT NULL,
    total_protein REAL NOT NULL,
    total_fat REAL NOT NULL,
    total_carbs REAL NOT NULL,
    config_json TEXT NOT NULL,  -- JSON serialized config
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Recipe sources table (for external recipe APIs)
CREATE TABLE IF NOT EXISTS recipe_sources (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('database', 'api', 'user_provided')),
    config TEXT,  -- Optional JSON config for API sources
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_generated_at ON auto_meal_plans(generated_at);
CREATE INDEX IF NOT EXISTS idx_recipe_sources_type ON recipe_sources(type);
