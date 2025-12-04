# Meal Planner

A modern web application for meal planning and nutrition tracking built with Gleam, Lustre SSR, and PostgreSQL. Integrates USDA FoodData Central database for comprehensive food and nutrition information.

## Features

### Web Application
- **Server-Side Rendered UI**: Fast, accessible web interface with Lustre SSR
- **Food Search**: Search 380,000+ foods from USDA FoodData Central database
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
- **Frontend**: Lustre SSR (server-side rendered components)
- **OTP**: Supervision trees for fault tolerance
- **Testing**: Gleeunit + qcheck (property-based testing)

## Prerequisites

- **Erlang/OTP**: Version 26 or later
- **Gleam**: Version 1.0.0 or later
- **PostgreSQL**: Version 14 or later
- **Git**: For version control

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/lprior-repo/meal-planner
cd meal-planner/gleam
```

### 2. Install Dependencies

```bash
gleam deps download
```

### 3. Setup PostgreSQL Database

Create the database and run migrations:

```bash
# Create database
createdb meal_planner

# Run migrations (in order)
psql -d meal_planner -f migrations/001_schema_migrations.sql
psql -d meal_planner -f migrations/002_usda_tables.sql
psql -d meal_planner -f migrations/003_app_tables.sql
psql -d meal_planner -f migrations/004_diet_compliance.sql
# ... continue with remaining migrations
```

### 4. Import USDA Food Database (Optional)

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

### 5. Build the Project

```bash
gleam build
```

### 6. Start the Web Server

```bash
# Start on port 8080
gleam run -m meal_planner/web

# Or specify a different port
PORT=3000 gleam run -m meal_planner/web
```

Access the application at `http://localhost:8080`

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
gleam/
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
├── migrations/                    # PostgreSQL migrations
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

- **Database Indexes**: Optimized for food search and nutrient lookups
- **Connection Pooling**: Concurrent request handling with pog
- **Caching**: In-memory cache for frequently accessed foods
- **Parallel Imports**: 32 concurrent workers for USDA data import
- **Batch Operations**: Bulk inserts for recipe ingredients

## Scripts

Located in `src/scripts/`:

- `init_pg.gleam` - Initialize PostgreSQL database and import USDA data
- `import_recipes.gleam` - Import recipes from YAML files (legacy)
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

## Legacy Code

The original Go implementation has been archived in `_archive/go/`. The project has been fully rewritten in Gleam with modern web technologies.

---

**Built with ❤️ using Gleam, PostgreSQL, and Lustre SSR**
