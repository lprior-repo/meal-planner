-- Migration: Create search analytics tracking table
-- Date: 2025-12-08
-- Purpose: Track search quality metrics for optimization

-- Create search_analytics table to track search behavior
CREATE TABLE IF NOT EXISTS search_analytics (
    id SERIAL PRIMARY KEY,

    -- Search context
    user_id TEXT NOT NULL,
    search_term TEXT NOT NULL,
    search_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Search filters applied
    filters JSONB DEFAULT '{}'::jsonb,

    -- Result metadata
    result_count INTEGER NOT NULL DEFAULT 0,
    custom_count INTEGER NOT NULL DEFAULT 0,
    usda_count INTEGER NOT NULL DEFAULT 0,

    -- User interaction tracking
    selected_food_id INTEGER,  -- NULL if abandoned
    selected_position INTEGER, -- Position in results (0-based)
    selection_timestamp TIMESTAMP WITH TIME ZONE,
    time_to_selection_ms INTEGER,

    -- Session tracking
    session_id TEXT,

    -- Analytics flags
    zero_results BOOLEAN GENERATED ALWAYS AS (result_count = 0) STORED,
    abandoned BOOLEAN GENERATED ALWAYS AS (selected_food_id IS NULL AND result_count > 0) STORED,

    CONSTRAINT search_analytics_valid_position
        CHECK (selected_position IS NULL OR selected_position >= 0),
    CONSTRAINT search_analytics_valid_time
        CHECK (time_to_selection_ms IS NULL OR time_to_selection_ms >= 0)
);

-- Index for user-based queries
CREATE INDEX idx_search_analytics_user_id
    ON search_analytics(user_id);

-- Index for timestamp-based queries (analytics dashboard)
CREATE INDEX idx_search_analytics_timestamp
    ON search_analytics(search_timestamp DESC);

-- Index for term-based queries (popular searches)
CREATE INDEX idx_search_analytics_term
    ON search_analytics(search_term);

-- Index for zero-result searches (optimization opportunities)
CREATE INDEX idx_search_analytics_zero_results
    ON search_analytics(zero_results)
    WHERE zero_results = TRUE;

-- Index for abandoned searches (UX optimization)
CREATE INDEX idx_search_analytics_abandoned
    ON search_analytics(abandoned)
    WHERE abandoned = TRUE;

-- Composite index for click-through rate analysis
CREATE INDEX idx_search_analytics_ctr
    ON search_analytics(search_term, selected_food_id, selected_position)
    WHERE selected_food_id IS NOT NULL;

-- GIN index for filter analysis
CREATE INDEX idx_search_analytics_filters
    ON search_analytics USING GIN(filters);

-- Comments for documentation
COMMENT ON TABLE search_analytics IS
    'Tracks search behavior for quality metrics and optimization';

COMMENT ON COLUMN search_analytics.search_term IS
    'User search query (trimmed and validated)';

COMMENT ON COLUMN search_analytics.filters IS
    'JSON object containing applied filters (verified_only, branded_only, category)';

COMMENT ON COLUMN search_analytics.selected_position IS
    'Position in results list where user clicked (0-based index)';

COMMENT ON COLUMN search_analytics.time_to_selection_ms IS
    'Milliseconds from search to selection (NULL if abandoned)';

COMMENT ON COLUMN search_analytics.zero_results IS
    'Generated column: TRUE when search returned no results';

COMMENT ON COLUMN search_analytics.abandoned IS
    'Generated column: TRUE when search had results but user did not select any';
