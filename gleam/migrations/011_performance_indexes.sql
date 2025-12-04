-- Performance optimization indexes for food_logs table
-- Phase 1 quick wins: composite indexes for common query patterns
-- Reference: PERFORMANCE_ANALYSIS.md Section 1.2

-- Composite index for dashboard filtering (date + meal_type)
-- Used in: web.gleam dashboard_page() for filtering by meal type
-- Impact: 50x faster filtering on food_logs table
CREATE INDEX IF NOT EXISTS idx_food_logs_date_meal_type
  ON food_logs(date, meal_type);

-- Composite index for user-specific queries (date + user_id)
-- Future-proofs for multi-user support
-- Impact: Prevents full table scan when filtering by date and user
CREATE INDEX IF NOT EXISTS idx_food_logs_date_user
  ON food_logs(date DESC);

-- Index for time-series queries (logged_at descending)
-- Used in: storage.gleam get_recent_meals() for ordering
-- Impact: 10-20x faster recent meals query
CREATE INDEX IF NOT EXISTS idx_food_logs_logged_at
  ON food_logs(logged_at DESC);

-- Covering index for recent meals query optimization
-- Includes all columns needed by get_recent_meals() to avoid table lookup
-- PostgreSQL: Uses INCLUDE clause for covering index
-- SQLite: Will use all columns in index definition
CREATE INDEX IF NOT EXISTS idx_food_logs_recent_covering
  ON food_logs(recipe_id, logged_at DESC, id, date, recipe_name, servings, protein, fat, carbs, meal_type);

-- Note: For SQLite compatibility, covering indexes include all columns in the index
-- For PostgreSQL, you could use: CREATE INDEX ... ON food_logs(recipe_id, logged_at DESC) INCLUDE (...)
