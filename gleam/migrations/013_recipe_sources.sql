-- Migration 013: Recipe Sources Table
-- Stores external recipe APIs and scrapers configuration for importing recipes

CREATE TABLE IF NOT EXISTS recipe_sources (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    source_type TEXT NOT NULL CHECK (source_type IN ('api', 'scraper')),
    base_url TEXT NOT NULL,
    api_key_required BOOLEAN NOT NULL DEFAULT FALSE,
    rate_limit_per_hour INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- JSONB for flexible API-specific configuration
    -- Examples:
    -- For APIs: {"auth_type": "header", "header_name": "X-API-Key", "endpoints": {...}}
    -- For scrapers: {"selectors": {...}, "pagination": {...}}
    config JSONB,

    -- Metadata
    description TEXT,
    documentation_url TEXT,

    -- Timestamps
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT valid_rate_limit CHECK (rate_limit_per_hour IS NULL OR rate_limit_per_hour > 0),
    CONSTRAINT valid_base_url CHECK (base_url LIKE 'http%')
);

-- Index for finding active sources
CREATE INDEX IF NOT EXISTS idx_recipe_sources_active
    ON recipe_sources(is_active)
    WHERE is_active = TRUE;

-- Index for filtering by source type
CREATE INDEX IF NOT EXISTS idx_recipe_sources_type
    ON recipe_sources(source_type);

-- Compound index for active sources by type
CREATE INDEX IF NOT EXISTS idx_recipe_sources_active_type
    ON recipe_sources(source_type, is_active)
    WHERE is_active = TRUE;

-- Index for name lookups (unique constraint already provides this, but explicit for clarity)
CREATE INDEX IF NOT EXISTS idx_recipe_sources_name
    ON recipe_sources(name);

-- Insert common recipe sources as seed data
INSERT INTO recipe_sources (name, source_type, base_url, api_key_required, rate_limit_per_hour, description, documentation_url, config)
VALUES
    (
        'Spoonacular API',
        'api',
        'https://api.spoonacular.com',
        TRUE,
        150,
        'Comprehensive recipe and nutrition API with 365,000+ recipes',
        'https://spoonacular.com/food-api/docs',
        '{"auth_type": "query_param", "param_name": "apiKey", "endpoints": {"search": "/recipes/complexSearch", "details": "/recipes/{id}/information", "nutrition": "/recipes/{id}/nutritionWidget.json"}}'::jsonb
    ),
    (
        'Edamam Recipe API',
        'api',
        'https://api.edamam.com',
        TRUE,
        100,
        'Recipe search API with nutrition analysis and dietary filters',
        'https://developer.edamam.com/edamam-docs-recipe-api',
        '{"auth_type": "query_param", "param_name": "app_key", "additional_params": ["app_id"], "endpoints": {"search": "/api/recipes/v2"}}'::jsonb
    ),
    (
        'AllRecipes Scraper',
        'scraper',
        'https://www.allrecipes.com',
        FALSE,
        60,
        'Community-driven recipe website with user ratings and reviews',
        NULL,
        '{"selectors": {"title": "h1.heading-content", "ingredients": ".ingredients-item-name", "instructions": ".instructions-section-item", "nutrition": ".nutrition-info"}, "rate_limit_delay_ms": 1000}'::jsonb
    ),
    (
        'Serious Eats Scraper',
        'scraper',
        'https://www.seriouseats.com',
        FALSE,
        30,
        'Professional recipes with detailed testing and techniques',
        NULL,
        '{"selectors": {"title": "h1.heading__title", "ingredients": ".structured-ingredients__list-item", "instructions": ".project-steps li"}, "rate_limit_delay_ms": 2000}'::jsonb
    )
ON CONFLICT (name) DO NOTHING;

-- Create a table to track recipe imports from sources
CREATE TABLE IF NOT EXISTS recipe_imports (
    id SERIAL PRIMARY KEY,
    recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    source_id INTEGER NOT NULL REFERENCES recipe_sources(id) ON DELETE CASCADE,
    external_id TEXT NOT NULL, -- The ID used by the external source
    external_url TEXT, -- Direct link to recipe on source
    imported_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    import_metadata JSONB, -- Additional import data (author, rating, etc.)

    -- Unique constraint: one recipe can only be imported once from each source
    CONSTRAINT unique_recipe_source_import UNIQUE (recipe_id, source_id),
    CONSTRAINT unique_external_id_per_source UNIQUE (source_id, external_id)
);

-- Index for finding all recipes from a specific source
CREATE INDEX IF NOT EXISTS idx_recipe_imports_source
    ON recipe_imports(source_id);

-- Index for finding the source of a specific recipe
CREATE INDEX IF NOT EXISTS idx_recipe_imports_recipe
    ON recipe_imports(recipe_id);

-- Index for lookup by external ID
CREATE INDEX IF NOT EXISTS idx_recipe_imports_external_id
    ON recipe_imports(source_id, external_id);

-- Index for recent imports
CREATE INDEX IF NOT EXISTS idx_recipe_imports_imported_at
    ON recipe_imports(imported_at DESC);

-- Common source types we'll support:
-- API sources:
--   - 'api': RESTful API endpoints requiring authentication
--
-- Scraper sources:
--   - 'scraper': HTML scraping from recipe websites
--
-- Rate limits are per hour to prevent overwhelming external services
-- config JSONB allows flexible configuration per source type
