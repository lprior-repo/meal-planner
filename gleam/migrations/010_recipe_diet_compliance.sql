-- Migration 010: Recipe Diet Compliance Table
-- Tracks which dietary protocols each recipe complies with

CREATE TABLE IF NOT EXISTS recipe_diet_compliance (
    recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    diet_type TEXT NOT NULL, -- 'vertical_diet', 'tim_ferriss', 'low_fodmap', 'keto', etc.
    compliant BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT, -- Optional notes about compliance or modifications needed
    verified_at TEXT, -- Timestamp when compliance was last verified
    verified_by TEXT, -- Who verified this compliance (user, system, nutritionist)
    
    PRIMARY KEY (recipe_id, diet_type)
);

-- Index for finding all recipes compliant with a specific diet
CREATE INDEX IF NOT EXISTS idx_recipe_diet_compliance_diet 
    ON recipe_diet_compliance(diet_type, compliant);

-- Index for finding all diets a specific recipe complies with
CREATE INDEX IF NOT EXISTS idx_recipe_diet_compliance_recipe 
    ON recipe_diet_compliance(recipe_id);

-- Index for verified recipes only
CREATE INDEX IF NOT EXISTS idx_recipe_diet_compliance_verified 
    ON recipe_diet_compliance(diet_type, compliant, verified_at) 
    WHERE verified_at IS NOT NULL;

-- Common diet types we'll track
-- This is informational, not enforced by database
-- 'vertical_diet' - Stan Efferding's Vertical Diet principles
-- 'tim_ferriss' - Tim Ferriss Slow Carb Diet principles  
-- 'low_fodmap' - Low FODMAP for digestive health
-- 'keto' - Ketogenic diet (high fat, very low carb)
-- 'paleo' - Paleo diet principles
-- 'whole30' - Whole30 compliant
-- 'vegan' - Vegan friendly
-- 'vegetarian' - Vegetarian friendly
-- 'dairy_free' - No dairy products
-- 'gluten_free' - No gluten
