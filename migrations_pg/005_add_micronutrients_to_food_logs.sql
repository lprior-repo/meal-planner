-- Migration 005: Add micronutrients to food_logs
-- Adds 21 micronutrient columns for complete nutrition tracking
-- All columns are REAL NULL for backward compatibility

-- Dietary components
ALTER TABLE food_logs ADD COLUMN fiber REAL;
ALTER TABLE food_logs ADD COLUMN sugar REAL;
ALTER TABLE food_logs ADD COLUMN sodium REAL;
ALTER TABLE food_logs ADD COLUMN cholesterol REAL;

-- Vitamins
ALTER TABLE food_logs ADD COLUMN vitamin_a REAL;
ALTER TABLE food_logs ADD COLUMN vitamin_c REAL;
ALTER TABLE food_logs ADD COLUMN vitamin_d REAL;
ALTER TABLE food_logs ADD COLUMN vitamin_e REAL;
ALTER TABLE food_logs ADD COLUMN vitamin_k REAL;
ALTER TABLE food_logs ADD COLUMN vitamin_b6 REAL;
ALTER TABLE food_logs ADD COLUMN vitamin_b12 REAL;
ALTER TABLE food_logs ADD COLUMN folate REAL;
ALTER TABLE food_logs ADD COLUMN thiamin REAL;
ALTER TABLE food_logs ADD COLUMN riboflavin REAL;
ALTER TABLE food_logs ADD COLUMN niacin REAL;

-- Minerals
ALTER TABLE food_logs ADD COLUMN calcium REAL;
ALTER TABLE food_logs ADD COLUMN iron REAL;
ALTER TABLE food_logs ADD COLUMN magnesium REAL;
ALTER TABLE food_logs ADD COLUMN phosphorus REAL;
ALTER TABLE food_logs ADD COLUMN potassium REAL;
ALTER TABLE food_logs ADD COLUMN zinc REAL;

-- Note: All existing rows will have NULL for these columns
-- This is intentional and handled gracefully by Option(Micronutrients) type
