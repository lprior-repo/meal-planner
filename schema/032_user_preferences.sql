-- ============================================================================
-- Schema change 032: User Preferences - Profile Configuration
-- ============================================================================
--
-- Creates table for storing user preferences and profile configuration:
-- - Dietary restrictions (vegetarian, vegan, kosher, halal, etc.)
-- - Cuisine preferences (Italian, Chinese, Mexican, etc.)
-- - Cooking difficulty level preferences (beginner, intermediate, advanced)
-- - Allergies and food sensitivities
-- - Meal planning preferences
--
-- Features:
-- - Flexible JSON storage for extensible preference types
-- - Individual enable/disable toggles per preference category
-- - Singleton pattern (one profile per user in single-user app)
-- - Timestamp tracking for preference updates
-- ============================================================================

-- ============================================================================
-- 1. User Preferences Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_preferences (
    -- Single-row configuration (enforced by CHECK constraint)
    id INTEGER PRIMARY KEY CHECK (id = 1),

    -- Dietary restrictions (array of restriction types)
    dietary_restrictions JSONB NOT NULL DEFAULT '[]'::JSONB,
    dietary_restrictions_enabled BOOLEAN NOT NULL DEFAULT true,

    -- Cuisine preferences (array of preferred cuisines)
    cuisine_preferences JSONB NOT NULL DEFAULT '[]'::JSONB,
    cuisine_preferences_enabled BOOLEAN NOT NULL DEFAULT true,

    -- Difficulty level preference (beginner, intermediate, advanced, any)
    difficulty_level TEXT NOT NULL DEFAULT 'any' CHECK (
        difficulty_level IN ('beginner', 'intermediate', 'advanced', 'any')
    ),
    difficulty_level_enabled BOOLEAN NOT NULL DEFAULT true,

    -- Allergies (array of allergen types)
    allergies JSONB NOT NULL DEFAULT '[]'::JSONB,
    allergies_enabled BOOLEAN NOT NULL DEFAULT true,

    -- Additional preferences (extensible JSON object)
    additional_preferences JSONB NOT NULL DEFAULT '{}'::JSONB,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Insert default preferences
INSERT INTO user_preferences (
    id,
    dietary_restrictions,
    cuisine_preferences,
    difficulty_level,
    allergies
)
VALUES (
    1,
    '[]'::JSONB,
    '[]'::JSONB,
    'any',
    '[]'::JSONB
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 2. Indexes for Performance
-- ============================================================================

-- GIN indexes for JSONB columns to support containment queries
CREATE INDEX IF NOT EXISTS idx_user_preferences_dietary_restrictions
ON user_preferences USING GIN (dietary_restrictions);

CREATE INDEX IF NOT EXISTS idx_user_preferences_cuisine_preferences
ON user_preferences USING GIN (cuisine_preferences);

CREATE INDEX IF NOT EXISTS idx_user_preferences_allergies
ON user_preferences USING GIN (allergies);

CREATE INDEX IF NOT EXISTS idx_user_preferences_additional
ON user_preferences USING GIN (additional_preferences);

-- ============================================================================
-- 3. Triggers for Timestamp Management
-- ============================================================================

-- Update updated_at on user_preferences
DROP TRIGGER IF EXISTS update_user_preferences_timestamp ON user_preferences;
CREATE TRIGGER update_user_preferences_timestamp
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 4. Helper Functions
-- ============================================================================

-- Function to check if a dietary restriction is enabled
CREATE OR REPLACE FUNCTION has_dietary_restriction(restriction TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    restrictions JSONB;
    is_enabled BOOLEAN;
BEGIN
    SELECT dietary_restrictions, dietary_restrictions_enabled
    INTO restrictions, is_enabled
    FROM user_preferences
    WHERE id = 1;

    IF NOT is_enabled THEN
        RETURN false;
    END IF;

    RETURN restrictions @> to_jsonb(restriction);
END;
$$ LANGUAGE plpgsql;

-- Function to check if a cuisine is preferred
CREATE OR REPLACE FUNCTION prefers_cuisine(cuisine TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    cuisines JSONB;
    is_enabled BOOLEAN;
BEGIN
    SELECT cuisine_preferences, cuisine_preferences_enabled
    INTO cuisines, is_enabled
    FROM user_preferences
    WHERE id = 1;

    IF NOT is_enabled THEN
        RETURN true; -- If preferences disabled, all cuisines are acceptable
    END IF;

    -- If no preferences set, accept all cuisines
    IF jsonb_array_length(cuisines) = 0 THEN
        RETURN true;
    END IF;

    RETURN cuisines @> to_jsonb(cuisine);
END;
$$ LANGUAGE plpgsql;

-- Function to check if an allergen is present
CREATE OR REPLACE FUNCTION has_allergen(allergen TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_allergies JSONB;
    is_enabled BOOLEAN;
BEGIN
    SELECT allergies, allergies_enabled
    INTO user_allergies, is_enabled
    FROM user_preferences
    WHERE id = 1;

    IF NOT is_enabled THEN
        RETURN false;
    END IF;

    RETURN user_allergies @> to_jsonb(allergen);
END;
$$ LANGUAGE plpgsql;

-- Function to check if difficulty level matches preference
CREATE OR REPLACE FUNCTION matches_difficulty(recipe_difficulty TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    preferred_difficulty TEXT;
    is_enabled BOOLEAN;
BEGIN
    SELECT difficulty_level, difficulty_level_enabled
    INTO preferred_difficulty, is_enabled
    FROM user_preferences
    WHERE id = 1;

    IF NOT is_enabled THEN
        RETURN true;
    END IF;

    -- 'any' accepts all difficulty levels
    IF preferred_difficulty = 'any' THEN
        RETURN true;
    END IF;

    RETURN recipe_difficulty = preferred_difficulty;
END;
$$ LANGUAGE plpgsql;

-- Function to get all active preferences as JSON
CREATE OR REPLACE FUNCTION get_active_preferences()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'dietary_restrictions', CASE
            WHEN dietary_restrictions_enabled THEN dietary_restrictions
            ELSE '[]'::JSONB
        END,
        'cuisine_preferences', CASE
            WHEN cuisine_preferences_enabled THEN cuisine_preferences
            ELSE '[]'::JSONB
        END,
        'difficulty_level', CASE
            WHEN difficulty_level_enabled THEN to_jsonb(difficulty_level)
            ELSE to_jsonb('any')
        END,
        'allergies', CASE
            WHEN allergies_enabled THEN allergies
            ELSE '[]'::JSONB
        END,
        'additional_preferences', additional_preferences
    )
    INTO result
    FROM user_preferences
    WHERE id = 1;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 5. Comments on Tables and Columns
-- ============================================================================

COMMENT ON TABLE user_preferences IS 'User profile configuration and preferences for meal planning';
COMMENT ON COLUMN user_preferences.id IS 'Singleton ID (always 1 for single-user app)';
COMMENT ON COLUMN user_preferences.dietary_restrictions IS 'Array of dietary restrictions (e.g., ["vegetarian", "gluten_free", "dairy_free"])';
COMMENT ON COLUMN user_preferences.dietary_restrictions_enabled IS 'Whether dietary restrictions filtering is active';
COMMENT ON COLUMN user_preferences.cuisine_preferences IS 'Array of preferred cuisines (e.g., ["italian", "mexican", "thai"])';
COMMENT ON COLUMN user_preferences.cuisine_preferences_enabled IS 'Whether cuisine preference filtering is active';
COMMENT ON COLUMN user_preferences.difficulty_level IS 'Preferred cooking difficulty: beginner, intermediate, advanced, or any';
COMMENT ON COLUMN user_preferences.difficulty_level_enabled IS 'Whether difficulty filtering is active';
COMMENT ON COLUMN user_preferences.allergies IS 'Array of allergens to avoid (e.g., ["peanuts", "shellfish", "eggs"])';
COMMENT ON COLUMN user_preferences.allergies_enabled IS 'Whether allergy filtering is active';
COMMENT ON COLUMN user_preferences.additional_preferences IS 'Extensible JSON object for future preference types';

-- ============================================================================
-- Data Model Examples
-- ============================================================================
--
-- Example dietary_restrictions JSON:
-- [
--   "vegetarian",
--   "gluten_free",
--   "dairy_free",
--   "low_fodmap",
--   "paleo",
--   "keto"
-- ]
--
-- Example cuisine_preferences JSON:
-- [
--   "italian",
--   "mexican",
--   "thai",
--   "chinese",
--   "indian",
--   "mediterranean"
-- ]
--
-- Example allergies JSON:
-- [
--   "peanuts",
--   "tree_nuts",
--   "shellfish",
--   "eggs",
--   "soy",
--   "wheat",
--   "fish",
--   "dairy"
-- ]
--
-- Example additional_preferences JSON:
-- {
--   "max_prep_time_minutes": 30,
--   "avoid_ingredients": ["cilantro", "olives"],
--   "preferred_proteins": ["chicken", "tofu", "beans"],
--   "meal_planning": {
--     "variety_score": 0.8,
--     "batch_cooking_enabled": true,
--     "leftovers_days": 3
--   }
-- }
--
-- ============================================================================
-- Usage Examples
-- ============================================================================
--
-- Check if user is vegetarian:
-- SELECT has_dietary_restriction('vegetarian');
--
-- Check if user prefers Italian cuisine:
-- SELECT prefers_cuisine('italian');
--
-- Check if user is allergic to peanuts:
-- SELECT has_allergen('peanuts');
--
-- Check if recipe difficulty matches user preference:
-- SELECT matches_difficulty('intermediate');
--
-- Get all active preferences:
-- SELECT get_active_preferences();
--
-- Update dietary restrictions:
-- UPDATE user_preferences
-- SET dietary_restrictions = '["vegetarian", "gluten_free"]'::JSONB
-- WHERE id = 1;
--
-- Disable cuisine filtering:
-- UPDATE user_preferences
-- SET cuisine_preferences_enabled = false
-- WHERE id = 1;
--
-- ============================================================================
-- Performance Notes
-- ============================================================================
--
-- Index Strategy:
-- 1. GIN indexes on JSONB arrays support containment queries (@>)
--    - Fast lookups: dietary_restrictions @> '["vegetarian"]'
--    - Fast existence checks: allergies ? 'peanuts'
--
-- 2. Helper functions provide clean API for preference checks
--    - Encapsulate enable/disable logic
--    - Consistent null handling
--    - Reusable across application
--
-- Extensibility:
-- - additional_preferences allows adding new preference types without schema changes
-- - Each preference category has independent enable/disable toggle
-- - JSON arrays allow unlimited values per category
--
-- ============================================================================
