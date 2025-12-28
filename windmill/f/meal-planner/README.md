# FatSecret Integration for Meal Planner - Windmill Scripts

This directory contains Windmill scripts for the FatSecret integration in the meal planner application.

## Overview

The FatSecret integration provides functionality to:
1. Sync food diary entries from FatSecret to Tandoor meal plans
2. Fetch food diary entries for specific dates
3. Search the FatSecret food database
4. Process an upload queue for batching changes to FatSecret

## Architecture

### Components

```
windmill/f/meal-planner/
├── scripts/
│   ├── fatsecret/
│   │   ├── sync/               # Synchronization logic
│   │   │   ├── sync_diary_to_plan.rs      # Match diary to meal plans
│   │   │   └── process_upload_queue.rs    # Process pending uploads
│   │   ├── diary/              # Diary operations
│   │   │   └── fetch_diary.rs             # Fetch diary entries
│   │   └── foods/              # Food search
│   │       └── search_foods.rs            # Search food database
│   └── shared/                 # Shared utilities (future)
└── wmill.yaml                  # Windmill configuration
```

## Scripts

### 1. Sync Diary to Meal Plans
**Path:** `f/meal-planner/scripts/fatsecret/sync/sync_diary_to_plan`

Matches FatSecret diary entries to Tandoor meal plans based on:
- Food name similarity
- Meal type (breakfast, lunch, dinner, snack)
- Nutrition profile (calories, macros)

**Inputs:**
- `diary_entries`: Array of FatSecret food entries
- `meal_plans`: Array of Tandoor meal plans
- `calorie_tolerance`: Tolerance for calorie matching (0.0-1.0, default: 0.15)
- `macro_tolerance`: Tolerance for macro matching (0.0-1.0, default: 0.20)

**Outputs:**
- `matched_count`: Number of successful matches
- `unmatched_diary_count`: Diary entries without matches
- `unmatched_plans_count`: Meal plans without matches
- `average_confidence`: Average confidence score of matches
- `message`: Summary message

**Example:**
```bash
wmill run f/meal-planner/scripts/fatsecret/sync/sync_diary_to_plan \
  --json '{
    "diary_entries": [...],
    "meal_plans": [...],
    "calorie_tolerance": 0.15,
    "macro_tolerance": 0.20
  }'
```

### 2. Fetch Diary Entries
**Path:** `f/meal-planner/scripts/fatsecret/diary/fetch_diary`

Retrieves all food diary entries for a specific date from FatSecret.

**Inputs:**
- `date`: Date in YYYY-MM-DD format
- `oauth_token`: FatSecret OAuth access token
- `oauth_secret`: FatSecret OAuth token secret

**Outputs:**
- `date`: The requested date
- `entries`: Array of food entries
- `entry_count`: Number of entries
- `total_calories`: Total calories for the day
- `total_protein`, `total_carbs`, `total_fat`: Daily macros

**Example:**
```bash
wmill run f/meal-planner/scripts/fatsecret/diary/fetch_diary \
  --json '{
    "date": "2025-12-28",
    "oauth_token": "...",
    "oauth_secret": "..."
  }'
```

### 3. Search Foods
**Path:** `f/meal-planner/scripts/fatsecret/foods/search_foods`

Searches the FatSecret food database for foods matching a query.

**Inputs:**
- `query`: Food name or partial name
- `max_results`: Maximum results to return (1-100, default: 20)
- `api_key`: FatSecret API consumer key
- `api_secret`: FatSecret API consumer secret

**Outputs:**
- `query`: The search query
- `foods`: Array of matching foods with IDs and nutrition
- `total_found`: Total number of matching foods
- `returned_count`: Number of results in this response
- `search_time_ms`: Time taken to search

**Example:**
```bash
wmill run f/meal-planner/scripts/fatsecret/foods/search_foods \
  --json '{
    "query": "chicken breast",
    "max_results": 20,
    "api_key": "...",
    "api_secret": "..."
  }'
```

### 4. Process Upload Queue
**Path:** `f/meal-planner/scripts/fatsecret/sync/process_upload_queue`

Processes pending entries in the FatSecret upload queue, batching uploads and handling retries.

**Inputs:**
- `batch_size`: Number of entries to process (1-100, default: 10)
- `max_retries`: Maximum retry attempts (default: 3)
- `database_url`: PostgreSQL connection string
- `oauth_token`: FatSecret OAuth access token

**Outputs:**
- `processed`: Total entries processed
- `successful`: Successful uploads
- `failed`: Failed uploads
- `retry_scheduled`: Entries scheduled for retry
- `summary`: Summary message

**Example:**
```bash
wmill run f/meal-planner/scripts/fatsecret/sync/process_upload_queue \
  --json '{
    "batch_size": 50,
    "max_retries": 3,
    "database_url": "postgresql://...",
    "oauth_token": "..."
  }'
```

## Resources

The scripts use these resource types (must be created in Windmill):

### PostgreSQL Database
- **Type:** `postgresql`
- **Path:** `f/meal-planner/database`
- **Description:** Connection to meal planner database

### FatSecret API Credentials
- **Type:** `custom`
- **Path:** `f/meal-planner/external_apis/fatsecret`
- **Description:** FatSecret OAuth consumer key and secret

### FatSecret OAuth Tokens
- **Type:** `custom`
- **Path:** `f/meal-planner/fatsecret_oauth`
- **Description:** User-specific OAuth tokens (retrieved from encrypted database storage)

## Deployment

### Setup

1. **Create resources in Windmill:**
```bash
wmill workspace switch <workspace-name>

# Create PostgreSQL resource
wmill resource create postgresql \
  --name "meal-planner-db" \
  --path "f/meal-planner/database" \
  --dbname "meal_planner" \
  --host "localhost" \
  --port "5432" \
  --user "postgres" \
  --password "$DB_PASSWORD"

# Create FatSecret API resource
wmill resource create custom \
  --name "fatsecret-api" \
  --path "f/meal-planner/external_apis/fatsecret" \
  --schema '{
    "consumer_key": "",
    "consumer_secret": ""
  }'
```

2. **Generate metadata:**
```bash
cd windmill/f/meal-planner
wmill script generate-metadata
```

3. **Push scripts:**
```bash
wmill sync push
```

### Testing

```bash
# Test sync script
wmill run f/meal-planner/scripts/fatsecret/sync/sync_diary_to_plan \
  --json '{...}'

# Test diary fetch
wmill run f/meal-planner/scripts/fatsecret/diary/fetch_diary \
  --json '{...}'

# Test search
wmill run f/meal-planner/scripts/fatsecret/foods/search_foods \
  --json '{...}'

# Test upload queue
wmill run f/meal-planner/scripts/fatsecret/sync/process_upload_queue \
  --json '{...}'
```

## Integration with Gleam

The Windmill scripts complement the Gleam backend implementation:

- **Gleam:** Handles OAuth flows, token encryption/storage, full API implementation
- **Windmill:** Provides scheduled execution, batch processing, and workflow orchestration

### Flow

1. **User logs in** → Gleam OAuth handler (3-legged flow) → Token stored encrypted in DB
2. **Manual sync request** → Gleam API route → Calls Gleam sync service
3. **Scheduled sync** → Windmill workflow trigger → Calls Rust sync script → Updates database

## Error Handling

Scripts implement graceful error handling:
- Invalid inputs return validation errors
- Missing resources raise anyhow errors
- Failed uploads are retried with exponential backoff
- After max retries, entries are marked as dead-letter for manual review

## Future Enhancements

- [ ] Implement actual FatSecret API calls (currently returns mock responses)
- [ ] Add webhook support for real-time sync
- [ ] Create workflow templates for common use cases
- [ ] Add monitoring and alerting
- [ ] Implement Redis caching for frequent searches
- [ ] Add batch operation support

## See Also

- `/src/meal_planner/fatsecret/` - Gleam implementation (main)
- `/src/meal_planner/automation/fatsecret_sync.rs` - Rust sync logic
- `/schema/030_fatsecret_oauth.sql` - OAuth token storage schema
- `/schema/034_fatsecret_upload_queue.sql` - Upload queue schema
