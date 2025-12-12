# Project Context

## Purpose
Weekly meal planning and nutrition tracking application that integrates USDA FoodData Central (380,000+ foods) with Mealie recipe management. Focus on diet compliance (Vertical Diet, 4-Hour Body), FODMAP analysis, and automated meal plan generation.

## Tech Stack
- **Language**: Gleam (functional programming on BEAM/OTP)
- **Database**: PostgreSQL with pog connection pooling
- **Web Framework**: Wisp + Mist (HTTP server)
- **Frontend**: Lustre SSR (server-side rendering) + HTMX (no custom JavaScript allowed)
- **External Integration**: Mealie (recipe management via REST API, port 9000)
- **Testing**: Gleeunit + qcheck (property-based testing)

## Project Conventions

### Code Style
- Use Gleam's official formatter: `gleam format`
- Keep functions small and focused (< 50 lines)
- Prefer pattern matching over if/else chains
- Result types for error handling, no exceptions
- Pure functions with isolated side effects
- Document public functions with doc comments

### Architecture Patterns
- **OTP Supervision**: Fault-tolerant process trees
- **PostgreSQL Connection Pool**: pog library (default: 10 connections)
- **Server-Side Rendering**: Lustre components for fast initial loads
- **Type Safety**: Leverage Gleam's type system for compile-time guarantees
- **Functional Core, Imperative Shell**: Pure logic, side effects at boundaries

### Testing Strategy
- **TDD Approach**: Write tests before implementation
- **Unit Tests**: Core logic, types, macros, FODMAP analysis
- **Integration Tests**: PostgreSQL storage, web handlers, SSR rendering
- **Property Tests**: Macro calculations, portion sizing (qcheck)
- **E2E Tests**: Food logging workflows, recipe creation
- **Pre-commit Hook**: Format check, type check, test suite (bypass: `SKIP_HOOKS=1`)

### Git Workflow
- **Branching**: Feature branches from main (`feature/amazing-feature`)
- **Commits**: Descriptive messages, link to Beads IDs (`[meal-planner-abc123]`)
- **Beads Integration**: `bd sync` before/after git operations
- **Pre-commit**: Automatic format + build + test checks
- **No JavaScript**: HTMX only for interactivity (see constraints below)

## Domain Context

### Core Concepts
- **USDA Food Database**: 380K+ foods, 150+ nutrients, 5.8M+ food-nutrient relationships
- **Mealie Integration**: External recipe manager (separate PostgreSQL DB), REST API
- **Nutrition Control Plane (NCP)**: Track nutrition state, set goals, reconcile deviations
- **FODMAP Analysis**: Vertical Diet compliance, Tim Ferriss 4-Hour Body principles
- **Auto Planner**: AI-driven meal plan generation based on macro targets
- **Recipe Sources**: Historical tracking of recipe origins (under review for removal)

### Key Workflows
1. **Food Search**: Filter 380K+ foods → HTMX updates → SSR rendering
2. **Recipe Creation**: Mealie UI → Sync to meal-planner → Nutrition analysis
3. **Meal Planning**: User goals → Auto planner → Weekly schedule → Portion sizing
4. **Food Logging**: Daily intake → Macro tracking → NCP reconciliation

## Important Constraints

### Critical: No JavaScript Files
- **FORBIDDEN**: Creating `.js` files or custom JavaScript code
- **ONLY EXCEPTION**: HTMX library (already included in base template)
- **ALL interactivity** MUST use HTMX attributes:
  - `hx-get`, `hx-post` - HTTP requests
  - `hx-target` - Response insertion point
  - `hx-swap` - Content swap strategy (innerHTML, outerHTML, etc)
  - `hx-trigger` - Event triggers (change, click, etc)
  - `hx-push-url` - Browser URL updates

### Database Separation
- `meal_planner` database = Gleam app data (USDA foods, user recipes, logs)
- `mealie` database = Mealie container (completely separate, not accessed directly)

### File Organization
- `/gleam/src` - Gleam source code
- `/gleam/test` - Test files
- `/gleam/migrations_pg` - PostgreSQL migrations
- **NEVER** save files to project root
- **NEVER** create JavaScript files

## External Dependencies

### Mealie (port 9000)
- **Purpose**: Recipe management UI and API
- **Connection**: REST API via `mealie/client.gleam`
- **Data Flow**: Mealie → meal-planner (one-way sync)
- **API Endpoints**:
  - `GET /api/recipes` - List recipes
  - `GET /api/recipes/:slug` - Recipe details
  - `POST /api/recipes` - Create recipe (programmatic)

### PostgreSQL (port 5432)
- **Databases**: `meal_planner` (app), `mealie` (Mealie container)
- **Connection Pooling**: pog library, 10 connections default
- **Performance**: Strategic indexes for 56% faster food searches

### USDA FoodData Central
- **Data Source**: Static import (not live API)
- **Update Frequency**: Manual re-import when database updates
- **Import Script**: `gleam run -m scripts/init_pg` (32 concurrent workers)

## Key Architectural Decisions

### 1. Mealie Integration Strategy
- **Decision**: Read-only sync from Mealie → meal-planner
- **Rationale**: Mealie owns recipes, meal-planner adds nutrition analysis
- **Trade-off**: Recipe edits must happen in Mealie UI

### 2. HTMX for Interactivity
- **Decision**: No custom JavaScript, HTMX only
- **Rationale**: Simplicity, server-side rendering, maintainability
- **Trade-off**: Limited client-side validation, more server round-trips

### 3. PostgreSQL over SQLite
- **Decision**: PostgreSQL for production
- **Rationale**: Concurrency, connection pooling, USDA data scale (5.8M+ rows)
- **Trade-off**: Requires running PostgreSQL service

### 4. Functional + OTP
- **Decision**: Gleam on BEAM/OTP
- **Rationale**: Fault tolerance, concurrency, type safety
- **Trade-off**: Learning curve for BEAM ecosystem

## Performance Targets

- **Food Search**: < 100ms for filtered queries (achieved via indexes)
- **Recipe Analysis**: < 500ms for full nutritional breakdown
- **Meal Plan Generation**: < 2s for 7-day plan with 21 meals
- **Database Import**: < 10 minutes for full USDA dataset (380K foods)

## Testing Philosophy

- **Coverage**: Aim for 80%+ on core logic
- **Property Testing**: Use qcheck for macro calculations, portion sizing
- **Integration Tests**: Real PostgreSQL, no mocks for storage layer
- **Pre-commit Safety**: All tests must pass before commit
