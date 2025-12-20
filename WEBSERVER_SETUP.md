# Web Server Setup & Running Guide

## Quick Start

### Prerequisites
The web server requires dynamic libraries that may not be in standard paths:
- libstdc++.so.6 (C++ Standard Library)
- libgcc_s.so.1 (GCC Support Library)

These are extracted to `/tmp/usr/lib` by the quick-revert script.

### Starting the Server

```bash
# Method 1: Using the provided wrapper script (RECOMMENDED)
./run-web.sh

# Method 2: Manual setup with environment variables
export LD_PRELOAD=/tmp/usr/lib/libstdc++.so.6.0.34
export LD_LIBRARY_PATH=/tmp/usr/lib:/usr/lib:/lib:$LD_LIBRARY_PATH
gleam run -- web

# Method 3: In a bash subprocess
bash -c 'export LD_PRELOAD=/tmp/usr/lib/libstdc++.so.6.0.34 LD_LIBRARY_PATH=/tmp/usr/lib:$LD_LIBRARY_PATH && gleam run -- web'
```

### Default Configuration
- **Server Port**: 8080 (configured in .env)
- **Database**: PostgreSQL on localhost:5432
- **Tandoor API**: http://localhost:8100

## API Endpoints

### Health & Status
- `GET /` - Root health check
- `GET /health` - Simple health check
- `GET /health/detailed` - Detailed health with component status

### Meal Planning
- `GET /api/meal-planning/recipes` - List all available recipes
- `GET /api/meal-planning/recipes?limit=N` - Limit results
- `POST /api/meal-planning/generate` - Generate new meal plan
- `POST /api/meal-planning/sync` - Sync with external services

### FatSecret Integration
- `GET /fatsecret/status` - Check OAuth connection status
- `GET /fatsecret/connect` - Initiate OAuth flow (redirects)
- `GET /fatsecret/foods/search?query=...` - Search foods
- `GET /fatsecret/recipes/search?query=...` - Search recipes
- `GET /fatsecret/diary` - View user diary entries
- `GET /fatsecret/profile` - Get user profile

### Tandoor Integration
- `GET /tandoor/recipes` - List Tandoor recipes
- `GET /tandoor/cuisines` - List cuisines
- `GET /tandoor/units` - List measurement units
- `GET /tandoor/keywords` - List recipe keywords

### Nutrition
- `GET /api/nutrition/daily-status?meals=N` - Daily nutrition status
- `GET /api/macro-calculator` - Calculate macros

## Technical Stack

- **Language**: Gleam (targeting Erlang)
- **Web Framework**: Wisp + Mist
- **Database**: PostgreSQL (via pog)
- **FFI**: Custom Erlang module for AES-256-GCM encryption

## Compilation Notes

The project uses a custom Erlang FFI module (`meal_planner_crypto_ffi.erl`) for AES-GCM encryption/decryption. This must be compiled to `.beam` format:

```bash
erlc -o build/dev/erlang/meal_planner/ebin src/meal_planner_crypto_ffi.erl
```

Due to system library issues, compilation requires:
```bash
export LD_PRELOAD=/tmp/usr/lib/libstdc++.so.6.0.34
export LD_LIBRARY_PATH=/tmp/usr/lib:/usr/lib:/lib:$LD_LIBRARY_PATH
erlc -o build/dev/erlang/meal_planner/ebin src/meal_planner_crypto_ffi.erl
```

## Testing Endpoints

Use curl to test the API:
```bash
# Health check
curl http://localhost:8080/health

# Get recipes
curl http://localhost:8080/api/meal-planning/recipes

# Check detailed health
curl http://localhost:8080/health/detailed
```

## Known Issues & Status

- ✓ Build succeeds with no compilation errors
- ✓ Web server starts and responds to requests
- ✓ Health check endpoints operational
- ✓ Recipe retrieval working
- ⚠️ ~20 endpoints not yet implemented (return 404/501)
- ⚠️ FatSecret OAuth token storage requires proper encryption setup
- ⚠️ Database schema may need initialization for some features

## Environment Setup

Required environment variables (see `.env`):
- `DATABASE_URL` - PostgreSQL connection
- `SERVER_PORT` - Port for web server
- `TANDOOR_API_URL` - Tandoor API base URL
- `FATSECRET_CONSUMER_KEY` - OAuth credentials
- `FATSECRET_CONSUMER_SECRET` - OAuth credentials
- `OAUTH_ENCRYPTION_KEY` - 32-byte hex string for token encryption
