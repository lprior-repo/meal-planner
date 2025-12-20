# Meal Planner

A modern web application for meal planning and nutrition tracking built with Gleam, Lustre SSR, and PostgreSQL. Integrates USDA FoodData Central database for comprehensive food and nutrition information.

## Features

### Web Application
- **Server-Side Rendered UI**: Fast, accessible web interface with Lustre SSR
- **HTMX Interactivity**: Dynamic updates without JavaScript - filter chips, search, forms
- **Food Search**: Search 380,000+ foods with real-time filtering (verified, branded, category)
- **Recipe Management**: Create, edit, and organize recipes with nutritional analysis
- **Food Logging**: Track daily food intake with meal categorization
- **Macro Tracking**: Real-time macronutrient tracking (protein, fat, carbs, calories)
- **Dashboard**: Visual overview of nutrition goals and daily progress
- **User Profiles**: Customizable profiles with activity level and dietary goals

### Core Features
- **USDA Food Database**: 380,000+ foods with complete nutritional information
- **PostgreSQL Storage**: High-performance concurrent database with connection pooling
- **FODMAP Analysis**: Analyze recipes for FODMAP content (Vertical Diet support)
- **Diet Compliance**: Validate recipes against Vertical Diet and Tim Ferriss 4-Hour Body principles
- **Nutrition Control Plane (NCP)**: Track nutrition state, set goals, reconcile deviations
- **Portion Sizing**: Automatically calculate portion sizes to meet macro targets
- **Weekly Meal Planning**: Generate meal plans based on user goals and preferences

## Tech Stack

- **Language**: Gleam (functional programming on BEAM VM)
- **Database**: PostgreSQL with pog connection pooling
- **Web Framework**: Wisp + Mist (HTTP server)
- **Frontend**: Lustre SSR (server-side rendered components) + HTMX for interactivity
- **OTP**: Supervision trees for fault tolerance
- **Testing**: Gleeunit + qcheck (property-based testing)

**Note**: This project uses HTMX for all client-side interactivity. No custom JavaScript is allowed - all dynamic behavior is handled through HTMX attributes (`hx-get`, `hx-post`, `hx-target`, etc.) with server-side responses.

## Prerequisites

- **Erlang/OTP**: Version 26 or later
- **Gleam**: Version 1.0.0 or later
- **PostgreSQL**: Version 14 or later
- **Git**: For version control

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/lprior-repo/meal-planner
cd meal-planner
```

### 2. Install Dependencies

```bash
gleam deps download
```

### 3. Setup PostgreSQL Database

Create the database and run schema files:

```bash
# Create database
createdb meal_planner

# Run schema files (in order from schema/)
psql -d meal_planner -f schema/001_schema_migrations.sql
psql -d meal_planner -f schema/002_usda_tables.sql
psql -d meal_planner -f schema/003_app_tables.sql
psql -d meal_planner -f schema/005_add_micronutrients_to_food_logs.sql
psql -d meal_planner -f schema/006_add_source_tracking.sql
psql -d meal_planner -f schema/009_auto_meal_planner.sql
psql -d meal_planner -f schema/010_optimize_search_performance.sql
```

### 4. Setup Tandoor (Recipe Management)

Tandoor is the integrated recipe management system that works with the meal planner. Use the automated startup which handles this, or see below for manual setup:

```bash
# Using automated startup (RECOMMENDED)
./run.sh start

# OR manually start Tandoor container (requires Docker)
docker run -d \
  --name tandoor \
  -p 8000:8000 \
  -e DB_ENGINE=django.db.backends.postgresql \
  -e POSTGRES_HOST=localhost \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_DB=tandoor \
  -e POSTGRES_USER=postgres \
  -e SECRET_KEY=your-secret-key \
  vabene1111/recipes:latest

# Create Tandoor database (if not using automated startup)
createdb tandoor

# Access Tandoor UI
open http://localhost:8000
```

**Environment Variables for Tandoor Integration:**
```bash
TANDOOR_BASE_URL=http://localhost:8000  # Tandoor API endpoint
TANDOOR_API_TOKEN=your-api-token        # Get from Tandoor settings > API
```

**Note**: Tandoor uses a separate `tandoor` database - do not mix with the `meal_planner` database.

### 5. Import USDA Food Database (Optional)

The USDA FoodData Central database can be imported for comprehensive food data:

```bash
# Download USDA data (placed in local cache directory)
# Run the import script with maximum concurrency
gleam run -m scripts/init_pg
```

This will import:
- 150+ nutrients with units and rankings
- 380,000+ foods from USDA FoodData Central
- 5.8M+ food-nutrient relationships

**Performance**: Uses 32 concurrent workers for parallel imports (completes in minutes on modern hardware).

### 6. Build the Project

```bash
gleam build
```

### 7. Start the Web Server

```bash
# Start on port 8080
gleam run -m meal_planner/web

# Or specify a different port
PORT=3000 gleam run -m meal_planner/web
```

**Access Points:**
- **Meal Planner**: `http://localhost:8080`
- **Tandoor UI**: `http://localhost:8000`

## Configuration

Environment variables:

```bash
# Database configuration
DATABASE_HOST=localhost          # Default: localhost
DATABASE_PORT=5432              # Default: 5432
DATABASE_NAME=meal_planner      # Default: meal_planner
DATABASE_USER=postgres          # Default: postgres
DATABASE_PASSWORD=postgres      # Optional
DATABASE_POOL_SIZE=10          # Default: 10

# Web server
PORT=8080                       # Default: 8080

# Tandoor integration
TANDOOR_BASE_URL=http://localhost:8000  # Tandoor API endpoint
TANDOOR_API_TOKEN=your-api-token        # Get from Tandoor settings > API
```

## CLI Usage

The `mp` command-line interface provides two modes:

1. **Interactive TUI Mode** - Run `mp` with no arguments to launch the interactive terminal UI
2. **Non-Interactive CLI Mode** - Run `mp <command>` for direct command execution

### CLI Commands

#### Recipe Commands

Search, list, and view recipe details from Tandoor:

| Command | Description | Flags | Example |
|---------|-------------|-------|---------|
| `mp recipe search <QUERY>` | Search recipes by name/description | `--limit N` (default: 20) | `mp recipe search "chicken pasta" --limit 10` |
| `mp recipe list` | List all recipes with pagination | `--limit N`, `--offset N` | `mp recipe list --limit 50 --offset 100` |
| `mp recipe detail <ID>` | Show full recipe details (ingredients, steps, nutrition) | None | `mp recipe detail 42` |

**Example Output:**
```bash
$ mp recipe search chicken --limit 5

Found 3 recipe(s) matching 'chicken':

[123] Grilled Chicken Salad
  Fresh greens with herb-marinated grilled chicken breast...

[456] Thai Basil Chicken
  Spicy stir-fried chicken with holy basil and vegetables...

[789] Chicken Tikka Masala
  Creamy tomato curry with tender chicken pieces...
```

#### Plan Commands

Generate, view, and manage weekly meal plans:

| Command | Description | Flags | Example |
|---------|-------------|-------|---------|
| `mp plan list` | List all meal plans | `--start-date YYYY-MM-DD`, `--end-date YYYY-MM-DD` | `mp plan list --start-date 2025-12-19 --end-date 2025-12-25` |
| `mp plan show <DATE>` | Show meal plan for specific date | None | `mp plan show 2025-12-19` |
| `mp plan generate` | Generate new meal plan | `--days N` (default: 7) | `mp plan generate --days 14` |
| `mp plan regenerate` | Regenerate meal plan for date range | `--date YYYY-MM-DD`, `--days N` (default: 7) | `mp plan regenerate --date 2025-12-19 --days 7` |
| `mp plan delete <DATE>` | Delete meal plan for specific date | `--confirm` (required) | `mp plan delete 2025-12-19 --confirm` |
| `mp plan sync` | Sync meal plan with Tandoor | None | `mp plan sync` |

**Example Output:**
```bash
$ mp plan show 2025-12-19

Meal Plan for 2025-12-19

Breakfast
  Scrambled Eggs (2 servings)

Lunch
  Chicken Salad (1 serving)

Dinner
  Grilled Salmon (1 serving)
```

#### Nutrition Commands

Track nutrition goals and daily intake:

| Command | Description | Flags | Example |
|---------|-------------|-------|---------|
| `mp nutrition goals` | View current nutrition goals | None | `mp nutrition goals` |
| `mp nutrition log <DATE>` | View food log for specific date | None | `mp nutrition log 2025-12-19` |
| `mp nutrition track` | Start interactive nutrition tracking | None | `mp nutrition track` |
| `mp nutrition macros` | View current macro totals | None | `mp nutrition macros` |

#### Scheduler Commands

View and manage scheduled jobs (meal plan generation, sync, advisors):

| Command | Description | Flags | Example |
|---------|-------------|-------|---------|
| `mp scheduler list` | List all scheduled jobs | None | `mp scheduler list` |
| `mp scheduler status` | View job execution status | `--id <job-id>` | `mp scheduler status --id weekly-gen` |
| `mp scheduler trigger` | Manually trigger a job | `--id <job-id>` | `mp scheduler trigger --id daily-advisor` |
| `mp scheduler executions` | View job execution history | `--id <job-id>` | `mp scheduler executions --id auto-sync` |

**Example Output:**
```bash
$ mp scheduler list

Scheduled jobs:
  Weekly Generation (Mon 09:00)
  Auto Sync (Daily 12:00)
  Daily Advisor (Daily 07:00)
```

#### FatSecret Commands

Search foods and track nutrition from FatSecret database:

| Command | Description | Flags | Example |
|---------|-------------|-------|---------|
| `mp fatsecret search <QUERY>` | Search FatSecret food database | `--limit N` | `mp fatsecret search "brown rice" --limit 10` |
| `mp fatsecret food <ID>` | Get detailed food information | None | `mp fatsecret food 12345` |
| `mp fatsecret diary <DATE>` | View food diary for date | None | `mp fatsecret diary 2025-12-19` |

#### Tandoor Commands

Manage recipe synchronization and categories:

| Command | Description | Flags | Example |
|---------|-------------|-------|---------|
| `mp tandoor sync` | Sync all recipes from Tandoor | None | `mp tandoor sync` |
| `mp tandoor categories` | List recipe categories | `--limit N` (default: 50) | `mp tandoor categories --limit 100` |
| `mp tandoor update` | Update recipe metadata | None | `mp tandoor update` |
| `mp tandoor delete` | Delete a recipe from Tandoor | `--id <recipe_id>` | `mp tandoor delete --id 123` |

#### Web Server Commands

Start and manage the web application server:

| Command | Description | Flags | Example |
|---------|-------------|-------|---------|
| `mp web` | Start the web server | None | `mp web` |

**Example Output:**
```bash
$ mp web

🍽️  Meal Planner Backend
========================

✓ Configuration loaded
  - Database: localhost:5432
  - Server port: 8080
  - Tandoor: http://localhost:8000

Starting web server...
```

### Common Workflows

**Weekly Meal Planning:**
```bash
# Generate a fresh meal plan for the week
mp plan generate --days 7

# View today's meals
mp plan show 2025-12-19

# Regenerate if you don't like the plan
mp plan regenerate --date 2025-12-19 --days 7
```

**Recipe Discovery:**
```bash
# Search for recipes
mp recipe search "pasta" --limit 10

# View full details
mp recipe detail 456

# Add to meal plan (through TUI or web interface)
```

**Nutrition Tracking:**
```bash
# View today's nutrition goals
mp nutrition goals

# Check current macro totals
mp nutrition macros

# View food log for a specific date
mp nutrition log 2025-12-19
```

**Recipe Management:**
```bash
# Sync latest recipes from Tandoor
mp tandoor sync

# List all recipes
mp recipe list --limit 100

# Delete a recipe
mp tandoor delete --id 123
```

## Testing

The project has comprehensive test coverage with unit, integration, and property-based tests:

```bash
# Run all tests
gleam test

# Run with coverage report
gleam test --target erlang

# Run specific test module
gleam test --target erlang --module postgres_test
```

### Test Categories

- **Unit Tests**: Core logic, types, macros, FODMAP analysis
- **Integration Tests**: PostgreSQL storage, web handlers, SSR rendering
- **Property Tests**: Macro calculations, portion sizing (qcheck)
- **E2E Tests**: Food logging workflows, recipe creation

## Project Structure

```
.
├── src/
│   └── meal_planner/
│       ├── web.gleam              # Wisp web server & routes
│       ├── postgres.gleam         # PostgreSQL connection pooling
│       ├── storage.gleam          # Database operations
│       ├── types.gleam            # Core types (Recipe, Macros, etc.)
│       ├── food_search.gleam      # USDA food search
│       ├── ncp.gleam              # Nutrition Control Plane
│       ├── fodmap.gleam           # FODMAP analysis
│       ├── validation.gleam       # Recipe & diet validation
│       ├── ui/
│       │   ├── pages/             # SSR page components
│       │   │   ├── dashboard.gleam
│       │   │   ├── recipes.gleam
│       │   │   └── foods.gleam
│       │   └── components/        # Reusable UI components
│       │       ├── macro_progress.gleam
│       │       ├── search_filters.gleam
│       │       └── food_log.gleam
│       └── auto_planner/          # AI meal planning
├── test/
│   ├── meal_planner/              # Unit & integration tests
│   ├── scripts/                   # Script tests
│   └── fixtures/                  # Test data
├── priv/
│   └── static/                    # CSS, JS, images
├── schema/                        # PostgreSQL schema definitions
└── gleam.toml                     # Project configuration
```

## Web Application Routes

### Pages (SSR)
- `GET /` - Home page with navigation
- `GET /dashboard` - Nutrition dashboard with macro progress
- `GET /recipes` - Recipe list with search/filter
- `GET /recipes/:id` - Recipe details with nutrition info
- `GET /foods` - USDA food search interface
- `GET /foods/:id` - Food details with nutrients
- `GET /log` - Food logging interface
- `GET /profile` - User profile and settings

### API Routes (JSON)
- `POST /api/recipes` - Create new recipe
- `PUT /api/recipes/:id` - Update recipe
- `DELETE /api/recipes/:id` - Delete recipe
- `GET /api/foods/search?q=...` - Search USDA foods
- `POST /api/log` - Log food entry
- `GET /api/log/:date` - Get daily log
- `GET /api/macros` - Get current macro totals

## Architecture

The application follows functional programming principles with OTP supervision:

### Key Design Decisions

- **PostgreSQL Connection Pool**: pog library with configurable pool size (default: 10)
- **Server-Side Rendering**: Lustre components rendered on server for fast initial loads
- **Pure Functions**: Core logic is pure, side effects isolated to storage/web layers
- **Type Safety**: Gleam's type system prevents runtime errors
- **Pattern Matching**: Extensive use for control flow and error handling
- **Result Types**: Errors handled with Result types, no exceptions
- **OTP Supervision**: Fault-tolerant process supervision
- **Performance Monitoring**: Prometheus metrics for Tandoor API, NCP calculations, and storage queries

### Database Schema

**USDA Tables:**
- `nutrients` - Nutrient definitions (protein, vitamins, etc.)
- `foods` - USDA FoodData Central foods (380,000+)
- `food_nutrients` - Food-to-nutrient mappings (5.8M+)

**Application Tables:**
- `recipes` - User-created recipes with ingredients
- `food_logs` - Daily food intake tracking
- `user_profiles` - User settings and goals
- `nutrition_state` - Daily macro tracking
- `recipe_diet_compliance` - Diet validation results

### Performance Optimizations

- **Database Indexes**: Strategic indexes for 56% faster food search queries
  - Composite index on data_type + category for filtered searches
  - Partial indexes for verified-only and branded-only queries
  - Covering index for index-only scans reducing I/O by ~15%
- **Connection Pooling**: Concurrent request handling with pog
- **Caching**: In-memory cache for frequently accessed foods
- **Parallel Imports**: 32 concurrent workers for USDA data import
- **Batch Operations**: Bulk inserts for recipe ingredients

### Performance Monitoring

The application includes comprehensive Prometheus metrics for monitoring critical operations:

**Metrics Categories**:
1. **Tandoor API Monitoring** (`src/meal_planner/metrics/tandoor_monitoring.gleam`)
   - API call duration and latency (p95, p99 percentiles)
   - Error rates by endpoint
   - Retry attempt tracking
   - Request/response payload sizes

2. **NCP Calculations** (`src/meal_planner/metrics/ncp_monitoring.gleam`)
   - Deviation calculation timing
   - Reconciliation duration
   - Recipe scoring performance
   - Nutrition consistency rates

3. **Storage Queries** (`src/meal_planner/metrics/storage_monitoring.gleam`)
   - Query execution time by type (SELECT, INSERT, UPDATE, DELETE)
   - Cache hit/miss rates
   - Rows processed and returned
   - Query efficiency metrics

**Metrics Endpoint**: Access Prometheus-formatted metrics at `/metrics` (when enabled)

**Performance SLOs**:
- Dashboard load: < 20ms
- Search latency: < 5ms
- Cache hit rate: > 80%
- NCP reconciliation: < 100ms

See `METRICS_INTEGRATION_GUIDE.md` for detailed integration instructions.

## Scripts

Located in `src/scripts/`:

- `init_pg.gleam` - Initialize PostgreSQL database and import USDA data
- `import_recipes.gleam` - Import recipes from YAML files
- `restore_db.gleam` - Database backup/restore utilities

Run scripts with:
```bash
gleam run -m scripts/<script_name>
```

## Development

### Adding New Features

1. **Define Types**: Add types to `types.gleam`
2. **Write Tests First**: TDD approach in `test/`
3. **Implement Core Logic**: Pure functions in `src/meal_planner/`
4. **Add Storage Layer**: Database operations in `storage.gleam`
5. **Create UI Components**: Lustre components in `ui/components/`
6. **Add Routes**: Web handlers in `web.gleam`
7. **Run Tests**: `gleam test` to verify

### Code Style

- Use Gleam's official formatter: `gleam format`
- Keep functions small and focused (< 50 lines)
- Use descriptive variable names
- Document public functions with doc comments
- Prefer pattern matching over if/else chains

## Development Workflow

### Quality Assurance

This project uses the **Fractal Quality Loop** for systematic code quality validation. See `FRACTAL_QUALITY_LOOP.md` for the complete 4-pass workflow (Unit → Integration → E2E → Review). All code changes should achieve a truth score >= 0.95 before merging.

### Pre-commit Hooks

This project uses pre-commit hooks to maintain code quality before commits. The hooks run automatically on every `git commit`.

#### What the Hook Does

The pre-commit hook enforces:
- **Code Formatting**: `gleam format --check` - Ensures consistent code style
- **Type Checking**: `gleam build` - Verifies type safety and compilation
- **Test Suite**: `gleam test` - Runs all unit and integration tests

#### Bypass for Emergencies

Only use this in emergencies when you need to commit without running checks:

```bash
SKIP_HOOKS=1 git commit -m "Emergency hotfix: description"
```

**Important**: The `SKIP_HOOKS=1` variable bypasses all pre-commit checks. Only use this for true emergencies, then run the full check suite immediately after:

```bash
./scripts/pre-commit.sh
```

#### Manual Check

Run the same checks manually without committing:

```bash
./scripts/pre-commit.sh
```

This will format-check code, compile the project, and run tests. Fix any issues and try again.

#### Best Practices

1. **Before committing**: Run `./scripts/pre-commit.sh` locally to catch issues early
2. **For quick commits**: Use `gleam format` then commit (formatting fixes common issues)
3. **Never disable the hook**: Pre-commit checks prevent broken code from being committed
4. **Emergency bypass only**: Use `SKIP_HOOKS=1` only for critical hotfixes, then verify with `./scripts/pre-commit.sh`

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests first (TDD)
4. Implement your changes
5. Ensure all tests pass: `gleam test`
6. Format code: `gleam format`
7. Commit changes (`git commit -m 'Add amazing feature'`)
8. Push to branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- **USDA FoodData Central** - Comprehensive food and nutrition database
- **Vertical Diet** - Stan Efferding's diet principles for performance
- **Gleam Community** - Excellent functional programming language and ecosystem
- **BEAM/OTP** - Rock-solid foundation for concurrent applications

## Deprecated Code

The original Go implementation has been archived in `_archive/go/`. The project has been fully rewritten in Gleam with modern web technologies.

---

**Built with ❤️ using Gleam, PostgreSQL, and Lustre SSR**
# Test commit from pool workflow
