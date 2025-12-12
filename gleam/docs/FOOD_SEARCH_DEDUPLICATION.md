# Food Search Deduplication

## Problem

When searching for foods in the USDA database, the same food could appear multiple times in search results because the SQL query used two matching strategies:
1. Full-text search: `to_tsvector('english', description) @@ plainto_tsquery('english', $1)`
2. Pattern matching: `description ILIKE $2`

If a food description matched both the full-text search AND the ILIKE pattern, it would appear twice in the results.

## Solution

The deduplication logic uses PostgreSQL's `DISTINCT ON (fdc_id)` clause to ensure each food appears only once in search results, even if it matches both search criteria.

### Implementation

All food search functions in `src/meal_planner/storage/foods.gleam` now use `DISTINCT ON (fdc_id)`:

```gleam
let sql =
  "SELECT DISTINCT ON (fdc_id) fdc_id, description, data_type, COALESCE(food_category, ''), '100g'
   FROM foods
   WHERE to_tsvector('english', description) @@ plainto_tsquery('english', $1)
      OR description ILIKE $2
   ORDER BY
     fdc_id,
     CASE data_type
       WHEN 'foundation_food' THEN 100
       WHEN 'sr_legacy_food' THEN 95
       WHEN 'survey_fndds_food' THEN 90
       WHEN 'sub_sample_food' THEN 50
       WHEN 'agricultural_acquisition' THEN 40
       WHEN 'market_acquisition' THEN 35
       WHEN 'branded_food' THEN 30
       ELSE 10
     END DESC,
     array_length(string_to_array(description, ' '), 1),
     description
   LIMIT $3"
```

### How DISTINCT ON Works

`DISTINCT ON (fdc_id)` tells PostgreSQL to return only one row for each unique `fdc_id` value. When multiple rows have the same `fdc_id`, PostgreSQL keeps the FIRST row according to the ORDER BY clause.

The ORDER BY clause ensures that for duplicate `fdc_id` values:
1. They are grouped together (ORDER BY fdc_id)
2. The highest priority data_type is kept
3. Shorter descriptions are preferred
4. Alphabetically first descriptions break ties

### Affected Functions

1. **search_foods** - Basic search with query and limit
2. **search_foods_filtered** - Search with category/brand filters
3. **search_foods_filtered_with_offset** - Paginated search with filters

### Testing

Comprehensive deduplication tests are in `test/meal_planner/storage/foods_test.gleam`:

- `search_foods_no_duplicates_test` - Verifies search_foods returns unique FDC IDs
- `search_foods_filtered_no_duplicates_test` - Verifies filtered search returns unique FDC IDs
- `search_foods_filtered_with_offset_no_duplicates_test` - Verifies paginated search returns unique FDC IDs
- `search_custom_foods_no_duplicates_test` - Verifies custom food search returns unique IDs

Each test:
1. Executes a search query
2. Collects all returned food IDs
3. Uses `list.unique()` to get unique IDs
4. Asserts that the count of unique IDs equals the total count (no duplicates)

### Related Tasks

- gleam-0ye: Write test exposing duplicate food results (CLOSED)
- gleam-2yd: Add DISTINCT to food search SQL query (CLOSED)
- gleam-xht: Add deduplication logic to search results (CLOSED)

### Historical Context

Implemented in commit 8f5a8e4 on 2025-12-09:
- Added DISTINCT ON (fdc_id) to SQL queries
- Created initial deduplication tests
- All 174 tests passing

Re-verified and documented in 2025-12-12:
- Recreated comprehensive test suite
- Added this documentation
- Verified deduplication works across all search functions
