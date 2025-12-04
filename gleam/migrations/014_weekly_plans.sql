-- Migration 014: Weekly Meal Plans
-- Adds tables for managing weekly meal plans with daily meals

-- Weekly plans table for organizing meals by week
CREATE TABLE IF NOT EXISTS weekly_plans (
    id SERIAL PRIMARY KEY,
    week_start_date DATE NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Weekly plan meals linking table
-- Maps recipes to specific days and meal types within a weekly plan
CREATE TABLE IF NOT EXISTS weekly_plan_meals (
    id SERIAL PRIMARY KEY,
    weekly_plan_id INTEGER NOT NULL REFERENCES weekly_plans(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK(day_of_week >= 0 AND day_of_week < 7), -- 0=Monday, 6=Sunday
    meal_type TEXT NOT NULL CHECK(meal_type IN ('breakfast', 'lunch', 'dinner')),
    recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Ensure each meal slot (day + meal_type) can only have one recipe per week
    UNIQUE(weekly_plan_id, day_of_week, meal_type)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_weekly_plans_week_start
    ON weekly_plans(week_start_date DESC);

CREATE INDEX IF NOT EXISTS idx_weekly_plan_meals_plan
    ON weekly_plan_meals(weekly_plan_id);

CREATE INDEX IF NOT EXISTS idx_weekly_plan_meals_recipe
    ON weekly_plan_meals(recipe_id);

CREATE INDEX IF NOT EXISTS idx_weekly_plan_meals_day_meal
    ON weekly_plan_meals(weekly_plan_id, day_of_week, meal_type);

-- Trigger function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_weekly_plans_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function
DROP TRIGGER IF EXISTS update_weekly_plans_timestamp ON weekly_plans;
CREATE TRIGGER update_weekly_plans_timestamp
    BEFORE UPDATE ON weekly_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_weekly_plans_timestamp();
