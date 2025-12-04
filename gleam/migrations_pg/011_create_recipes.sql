-- Migration: Create recipes table with simplified structure for recipe management
-- This table stores user-created and curated recipes with macro nutritional data

CREATE TABLE IF NOT EXISTS recipes_simplified (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    calories INT NOT NULL,
    protein INT NOT NULL,
    carbs INT NOT NULL,
    fat INT NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    branded BOOLEAN DEFAULT FALSE,
    category VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for fast filtering on commonly queried columns
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_protein ON recipes_simplified(protein);
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_fat ON recipes_simplified(fat);
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_category ON recipes_simplified(category);

-- Additional useful indexes
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_verified ON recipes_simplified(verified);
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_branded ON recipes_simplified(branded);

-- Seed data: 10 realistic recipes with accurate macro data
INSERT INTO recipes_simplified (name, calories, protein, carbs, fat, verified, branded, category)
VALUES
    -- Breakfast options
    ('Greek Yogurt with Berries', 180, 20, 15, 6, TRUE, FALSE, 'breakfast'),
    ('Scrambled Eggs with Toast', 320, 18, 28, 12, TRUE, FALSE, 'breakfast'),

    -- Lunch options
    ('Grilled Chicken Breast with Brown Rice', 450, 45, 48, 8, TRUE, FALSE, 'lunch'),
    ('Tuna Salad with Olive Oil Dressing', 280, 35, 8, 12, TRUE, FALSE, 'lunch'),
    ('Turkey Sandwich on Whole Wheat', 350, 28, 35, 10, TRUE, FALSE, 'lunch'),

    -- Dinner options
    ('Salmon Fillet with Sweet Potato', 520, 42, 45, 18, TRUE, FALSE, 'dinner'),
    ('Lean Beef Steak with Broccoli', 480, 50, 20, 20, TRUE, FALSE, 'dinner'),
    ('Pasta Primavera with Vegetables', 380, 14, 62, 8, TRUE, FALSE, 'dinner'),

    -- Snacks
    ('Protein Shake with Banana', 250, 25, 32, 3, FALSE, FALSE, 'snack'),
    ('Almonds and Apple', 210, 8, 24, 10, TRUE, FALSE, 'snack');

-- Verify the data was inserted
SELECT COUNT(*) as total_recipes FROM recipes_simplified;
