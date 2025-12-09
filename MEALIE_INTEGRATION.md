# Mealie Integration Architecture

## Overview

This document describes the integration between Mealie (recipe manager UI) and the Gleam backend (AI meal planning and macro calculations).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        User Interface                        │
│                     Mealie Vue.js Frontend                   │
│              (Recipe UI, Meal Planning, Shopping)            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ├─────────────────────────────────────┐
                         │                                     │
                         ▼                                     ▼
┌────────────────────────────────────┐    ┌──────────────────────────────┐
│      Mealie FastAPI Backend        │    │    Gleam Backend API         │
│  (Recipe CRUD, User Management)    │    │  (AI Planning, Macro Calc)   │
│                                    │    │                              │
│  - Recipe Management               │    │  - Auto Meal Planner         │
│  - Meal Plan Storage               │    │  - NCP Auto Planner          │
│  - Shopping Lists                  │    │  - Recipe Scorer             │
│  - Recipe Import/Scraping          │    │  - Macro Calculations        │
│  - User Authentication             │    │  - Vertical Diet Compliance  │
└─────────────┬──────────────────────┘    └──────────┬───────────────────┘
              │                                      │
              │    ┌─────────────────────────────┐  │
              └───►│   PostgreSQL Database       │◄─┘
                   │                             │
                   │  - mealie schema (Mealie)   │
                   │  - public schema (Gleam)    │
                   └─────────────────────────────┘
```

## Integration Strategy

### 1. Database Separation

**Mealie**: Uses `mealie` schema
- Recipe storage managed by Mealie
- User authentication and profiles
- Meal plans and shopping lists

**Gleam**: Uses `public` schema
- AI planning algorithms
- Macro calculations
- Recipe scoring metadata
- Vertical diet compliance data

**Benefits**:
- Clean separation of concerns
- No schema conflicts
- Each system manages its own data
- Can evolve independently

### 2. API Integration Points

#### Gleam → Mealie API Calls
The Gleam backend will call Mealie's REST API to:
- Fetch recipes for AI planning (`GET /api/recipes`)
- Read meal plans (`GET /api/groups/mealplans`)
- Get recipe details (`GET /api/recipes/{id}`)

#### Mealie → Gleam API Calls
Mealie will call Gleam's API for:
- AI-powered meal plan suggestions
- Recipe scoring based on macros
- Vertical diet compliance checking
- Advanced macro calculations

### 3. Where Mealie Takes Precedence

Per user requirements: **"where ever the 2 interact we will leverage mealie over whatever is in the codebase"**

Mealie will be the primary system for:
- **Recipe Management**: All recipe CRUD operations through Mealie
- **User Interface**: Mealie's Vue.js frontend for all user interactions
- **Meal Planning UI**: Mealie's meal planning interface
- **Recipe Storage**: Mealie's database schema for recipes
- **User Authentication**: Mealie's auth system

Gleam backend provides supplementary services:
- **AI Planning Algorithms**: Advanced meal planning using Gleam's auto_planner
- **Macro Optimization**: Sophisticated macro calculations via NCP
- **Diet Compliance**: Vertical diet validation and scoring
- **Recipe Scoring**: AI-based recipe recommendations

### 4. Workflow Example

**User Creates a Meal Plan with AI Assistance**:

1. User opens Mealie UI
2. User requests AI meal plan suggestions
3. Mealie frontend calls Gleam API: `POST /api/ai/meal-plan`
   - Sends: user preferences, macro targets, diet principles
4. Gleam backend:
   - Fetches recipes from Mealie API
   - Runs AI planning algorithms (auto_planner, ncp_auto_planner)
   - Scores recipes based on macros and compliance
   - Returns suggested meal plan
5. Mealie frontend displays suggestions
6. User accepts/modifies plan
7. Mealie saves the meal plan to its database

## Technical Details

### Mealie Configuration

**Environment Variables** (`.env` file):
```bash
# Database
DB_ENGINE=postgres
POSTGRES_SERVER=localhost
POSTGRES_PORT=5432
POSTGRES_USER=meal_planner
POSTGRES_PASSWORD=<password>
POSTGRES_DB=meal_planner

# API
BASE_URL=http://localhost:9000
API_PORT=9000

# Integration
GLEAM_BACKEND_URL=http://localhost:8080
```

### Gleam API Endpoints (To Be Created)

```
POST /api/ai/meal-plan
  Body: { macro_targets, diet_principles, recipe_count, variety_factor }
  Returns: { recipes: [...], total_macros: {...}, scores: [...] }

POST /api/ai/score-recipe
  Body: { recipe_id, macro_targets, diet_principles }
  Returns: { score: {...}, compliance: bool, violations: [...] }

GET /api/diet/vertical/compliance/{recipe_id}
  Returns: { compliant: bool, fodmap_level: "Low"|"Medium"|"High" }

POST /api/macros/calculate
  Body: { ingredients: [...], portions: [...] }
  Returns: { protein: float, fat: float, carbs: float, calories: float }
```

### Mealie API Endpoints (Used by Gleam)

```
GET /api/recipes
  Query: limit, offset, search
  Returns: { items: [...], total: int }

GET /api/recipes/{id}
  Returns: Recipe object with full details

GET /api/groups/mealplans
  Returns: Current meal plans
```

## Implementation Phases

### Phase 1: Basic Setup
- [x] Clone Mealie repository
- [ ] Configure Mealie to use PostgreSQL (mealie schema)
- [ ] Create Docker Compose setup for both services
- [ ] Set up environment configuration

### Phase 2: API Bridge
- [ ] Create Gleam HTTP server using Wisp or Mist
- [ ] Implement Gleam → Mealie API client
- [ ] Create Gleam AI endpoint for meal planning
- [ ] Add recipe scoring endpoint

### Phase 3: Integration Testing
- [ ] Test end-to-end meal plan generation
- [ ] Verify database separation works correctly
- [ ] Test recipe scoring via API
- [ ] Performance optimization

### Phase 4: Production Ready
- [ ] Docker containerization
- [ ] Environment variable management
- [ ] Health checks and monitoring
- [ ] Documentation and deployment guide

## Technology Stack Summary

**Frontend**: Mealie Vue.js (port 9000)
**Mealie Backend**: Python 3.12 + FastAPI (port 9000)
**Gleam Backend**: Gleam + Wisp/Mist (port 8080)
**Database**: PostgreSQL 15+ (port 5432)
  - Schema: `mealie` (Mealie tables)
  - Schema: `public` (Gleam tables)

## Development URLs

- Mealie UI: http://localhost:9000
- Mealie API Docs: http://localhost:9000/docs
- Gleam API: http://localhost:8080
- PostgreSQL: localhost:5432

## Migration Notes

- Existing Gleam migrations remain in `gleam/migrations_pg/`
- Mealie migrations managed by Alembic in `mealie-app/mealie/alembic/`
- No schema conflicts as they use separate schemas
- Both can run migrations independently

## Sources

- [Mealie GitHub Repository](https://github.com/mealie-recipes/mealie)
- [Mealie Documentation](https://docs.mealie.io)
