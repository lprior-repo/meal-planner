-- Migration 026: Update recipe_sources table for Tandoor configuration
-- Ensures recipe source configuration supports Tandoor instead of Mealie
-- Updates CHECK constraint on type column to use api/scraper/manual values
-- Adds tandoor_api_key column for Tandoor-specific configuration

-- First, check if any existing data uses old type values and update them
UPDATE recipe_sources SET type = 'api' WHERE type = 'database';
UPDATE recipe_sources SET type = 'scraper' WHERE type = 'user_provided';

-- Add new column for Tandoor API key (if not exists)
ALTER TABLE recipe_sources
ADD COLUMN IF NOT EXISTS tandoor_api_key TEXT,
ADD COLUMN IF NOT EXISTS tandoor_instance_url TEXT;

-- Modify the CHECK constraint to reflect Tandoor-compatible types
-- Drop old constraint first
ALTER TABLE recipe_sources
DROP CONSTRAINT IF EXISTS "recipe_sources_type_check",
ADD CONSTRAINT recipe_sources_type_check
  CHECK (type IN ('api', 'scraper', 'manual'));

-- Update comment to reflect current purpose
COMMENT ON TABLE recipe_sources IS 'Configuration for recipe sources (Tandoor integration and local APIs)';
COMMENT ON COLUMN recipe_sources.type IS 'Type of recipe source: api (external APIs), scraper (web scraping), manual (user-provided)';
COMMENT ON COLUMN recipe_sources.config IS 'JSON configuration for source-specific settings (API endpoints, authentication, etc.)';
COMMENT ON COLUMN recipe_sources.tandoor_api_key IS 'Optional Tandoor API key for Tandoor recipe source';
COMMENT ON COLUMN recipe_sources.tandoor_instance_url IS 'Optional Tandoor instance URL for Tandoor recipe source';
