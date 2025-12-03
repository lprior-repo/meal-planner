# Architecture

## System Overview

Meal Planner is a Gleam application running on the BEAM VM with:
- **Backend**: Wisp web framework
- **Database**: PostgreSQL
- **Frontend**: Lustre (SSR)
- **API**: RESTful JSON

## Project Structure

```
meal-planner/
├── gleam/          # Main CLI application
├── src/            # Source code (to be moved from gleam/src)
├── test/           # Tests (to be moved from gleam/test)
├── priv/           # Static assets, migrations
├── recipes/        # Recipe data files (YAML)
└── docs/           # Documentation
```

## Core Modules

### Storage Layer (`storage.gleam`)
- PostgreSQL database operations
- Recipe CRUD, food logs, user profiles
- Micronutrient tracking (21 fields)

### Web Layer (`web.gleam`)
- HTTP routing with Wisp
- Server-side rendering
- API endpoints

### Types (`shared/types.gleam`)
- Core domain types
- JSON encoders/decoders
- Micronutrients type system

### UI Components (`ui/components/`)
- Button, Card, Progress, Typography, Layout
- Server-side HTML generation
- Accessible, responsive design

## Database Schema

See `gleam/migrations/` for SQL migrations:
- 001: Schema migrations table
- 002: Nutrition tables
- 003: USDA foods
- 004: App tables (recipes, logs, profiles)
- 005: Micronutrients (21 columns)
- 006: Auto meal planner
- 007: Vertical diet recipes

## Data Flow

1. User request → Wisp router
2. Handler loads data from PostgreSQL
3. Lustre renders HTML (SSR)
4. HTML returned to client
5. Minimal client-side JS

## Key Design Decisions

- **Functional**: Pure functions, immutable data
- **Type-safe**: Gleam's type system prevents runtime errors
- **SSR-first**: Server-side rendering, not SPA
- **BEAM**: Fault-tolerant OTP supervision
