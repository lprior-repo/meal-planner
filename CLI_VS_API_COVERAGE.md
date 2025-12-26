# CLI vs API Coverage Analysis

## Summary
This document compares the Web API endpoints with the CLI commands to identify coverage gaps.

---

## Web API Routes

### 1. **FatSecret API** (`/api/fatsecret/*`)

#### Foods (2-legged OAuth)
- `GET /api/fatsecret/foods/autocomplete` - Autocomplete food search
- `GET /api/fatsecret/foods/search` - Search foods
- `GET /api/fatsecret/foods/<food_id>` - Get food details
- `GET /api/fatsecret/brands` - Get food brands

#### Recipes (2-legged OAuth)
- `GET /api/fatsecret/recipes/autocomplete` - Autocomplete recipe search
- `GET /api/fatsecret/recipes/types` - Get recipe types
- `GET /api/fatsecret/recipes/search` - Search recipes
- `GET /api/fatsecret/recipes/search/type/<type_id>` - Search by type
- `GET /api/fatsecret/recipes/<recipe_id>` - Get recipe details

#### Favorites (3-legged OAuth)
- `GET /api/fatsecret/favorites/foods/most-eaten` - Get most eaten foods
- `GET /api/fatsecret/favorites/foods/recently-eaten` - Get recently eaten foods
- `GET /api/fatsecret/favorites/foods/<food_id>` - Check if food is favorite
- `POST /api/fatsecret/favorites/foods/<food_id>` - Add food to favorites
- `DELETE /api/fatsecret/favorites/foods/<food_id>` - Remove food from favorites
- `GET /api/fatsecret/favorites/recipes` - Get favorite recipes
- `GET /api/fatsecret/favorites/recipes/<recipe_id>` - Check if recipe is favorite
- `POST /api/fatsecret/favorites/recipes/<recipe_id>` - Add recipe to favorites
- `DELETE /api/fatsecret/favorites/recipes/<recipe_id>` - Remove recipe from favorites

#### Saved Meals (3-legged OAuth)
- (Routes via saved_meals handlers)

#### Diary (3-legged OAuth)
- Routes handled by `diary/handlers.handle_diary_routes()`
- Diary CRUD operations (create, get, update, delete)
- Copy/template operations
- Daily/monthly summaries

#### Exercise (3-legged OAuth)
- Routes handled by `exercise/handlers.handle_exercise_routes()`
- Exercise logging and retrieval

#### Weight (3-legged OAuth)
- `GET /api/fatsecret/weight` - Get weight by date
- `POST /api/fatsecret/weight` - Update weight
- `GET /api/fatsecret/weight/month/<year>/<month>` - Get weight month summary

#### Profile (3-legged OAuth)
- `GET /api/fatsecret/profile` - Get user profile
- `POST /api/fatsecret/profile` - Create user profile
- `GET /api/fatsecret/profile/auth/<user_id>` - Get profile auth details

---

### 2. **Nutrition API** (`/api/nutrition/*`)

- `GET /api/nutrition/daily-status` - Get daily nutrition status vs goals
- `GET /api/nutrition/recommend-dinner` - Get dinner recommendations

---

### 3. **Meal Planning API** (`/api/meal-planning/*`)

- `GET /api/meal-planning/recipes` - List available MVP recipes
- `POST /api/meal-planning/generate` - Generate a complete meal plan
- `POST /api/meal-planning/sync` - Sync meals to FatSecret diary

---

### 4. **Advisor API** (`/api/advisor/*`)

- `GET /api/advisor/daily` - Daily recommendations for today
- `GET /api/advisor/daily/:date` - Daily recommendations for specific date
- `GET /api/advisor/trends` - Weekly trends for past 7 days
- `GET /api/advisor/trends/:end_date` - Weekly trends ending on specific date
- `GET /api/advisor/suggestions` - Meal adjustment suggestions
- `GET /api/advisor/compliance` - Weekly compliance score

---

### 5. **Tandoor API** (`/api/tandoor/*`)

- `GET /tandoor/status` - Get Tandoor connection status
- `GET /api/tandoor/recipes` - List recipes
- `GET /api/tandoor/recipes/<recipe_id>` - Get recipe details
- `GET /api/tandoor/cuisines` - List cuisines
- `GET /api/tandoor/cuisines/<cuisine_id>` - Get cuisine details
- `GET /api/tandoor/units` - List measurement units
- `GET /api/tandoor/keywords` - List keywords
- `GET /api/tandoor/meal-plans` - List meal plans
- `GET /api/tandoor/meal-plans/<entry_id>` - Get meal plan entry
- `GET /api/tandoor/steps` - List recipe steps
- `GET /api/tandoor/steps/<step_id>` - Get step details
- `GET /api/tandoor/shopping-list-entries` - List shopping list entries
- `GET /api/tandoor/shopping-list-entries/<entry_id>` - Get shopping list entry
- `GET /api/tandoor/shopping-list-recipe` - Get shopping list by recipe
- `GET /api/tandoor/supermarkets` - List supermarkets
- `GET /api/tandoor/supermarkets/<supermarket_id>` - Get supermarket details
- `GET /api/tandoor/supermarket-categories` - List supermarket categories
- `GET /api/tandoor/import-logs` - List import logs
- `GET /api/tandoor/import-logs/<log_id>` - Get import log details
- `GET /api/tandoor/export-logs` - List export logs
- `GET /api/tandoor/export-logs/<log_id>` - Get export log details
- `GET /api/tandoor/preferences` - Get user preferences

---

### 6. **Scheduler API** (`/api/scheduler/*`)

- Routes handled by scheduler handlers
- Job listing, status, triggering

---

### 7. **Auth API** (`/api/auth/*`)

- OAuth flow endpoints
- Token management

---

### 8. **Health API**

- `GET /health` - Health check endpoint

---

## CLI Commands (via `mp <domain> <command>`)

### 1. **FatSecret Domain** (`mp fatsecret <command>`)

- `mp fatsecret search <query>` - Search foods ✅
- `mp fatsecret detail <id>` - Get food details ✅
- `mp fatsecret ingredients <id>` - Get food ingredients ❌ (No CLI command)

### 2. **Diary Domain** (`mp diary <command>`)

- `mp diary add` - Add food entry ✅
- `mp diary delete` - Delete food entry ✅
- `mp diary view` - View diary entries ✅
- `mp diary sync` - Sync diary ✅

### 3. **Recipe Domain** (`mp recipe <command>`)

- `mp recipe search <query>` - Search recipes ✅
- `mp recipe detail <id>` - Get recipe details ❌ (No CLI command)
- `mp recipe list` - List recipes ❌ (No CLI command)

### 4. **Tandoor Domain** (`mp tandoor <command>`)

- `mp tandoor sync` - Full sync ✅
- `mp tandoor categories` - List categories ✅
- `mp tandoor update` - Update recipe ✅
- `mp tandoor create` - Create recipe ❌ (Not implemented in CLI)
- `mp tandoor delete` - Delete recipe ❌ (Not implemented in CLI)

### 5. **Plan Domain** (`mp plan <command>`)

- `mp plan list` - List meal plans ✅
- `mp plan view --id <id>` - View meal plan details ✅
- `mp plan sync` - Sync with FatSecret diary ✅
- `mp plan types` - List meal types ✅
- `mp plan generate` - Generate meal plan ❌ (No CLI command)

### 6. **Nutrition Domain** (`mp nutrition <command>`)

- `mp nutrition goals` - Get nutrition goals ✅
- `mp nutrition report --date <date>` - Get nutrition report ✅
- `mp nutrition trends --days <n>` - Get nutrition trends ✅
- `mp nutrition compliance --date <date> --tolerance <t>` - Check compliance ✅

### 7. **Scheduler Domain** (`mp scheduler <command>`)

- `mp scheduler list` - List scheduled jobs ✅
- `mp scheduler status --id <job_id>` - Get job status ✅
- `mp scheduler trigger --id <job_id>` - Trigger job ✅
- `mp scheduler create` - Create scheduled job ✅

### 8. **Advisor Domain** (`mp advisor <command>`)

- `mp advisor daily [--date <date>]` - Daily analysis ✅
- `mp advisor trends --days <n>` - Weekly trends ✅
- `mp advisor suggestions` - Personalized suggestions ✅
- `mp advisor patterns` - Pattern analysis ✅

### 9. **Preferences Domain** (`mp preferences <command>`)

- `mp preferences list` - List preferences ✅
- `mp preferences set` - Set preference ✅
- `mp preferences get` - Get preference ✅

### 10. **Web Domain** (`mp web <command>`)

- `mp web start` - Start web server ✅
- `mp web stop` - Stop web server ❌ (Not implemented)

---

## Coverage Gaps

### Missing CLI Commands

| Domain | API Endpoint | Missing CLI Command | Priority |
|---------|---------------|-------------------|----------|
| FatSecret | Food ingredients | `mp fatsecret ingredients <id>` | Medium |
| Recipe | Get recipe details | `mp recipe detail <id>` | High |
| Recipe | List recipes | `mp recipe list` | High |
| Tandoor | Create recipe | `mp tandoor create` | High |
| Tandoor | Delete recipe | `mp tandoor delete` | Medium |
| Tandoor | List cuisines | `mp tandoor cuisines` | Low |
| Tandoor | List units | `mp tandoor units` | Low |
| Tandoor | List keywords | `mp tandoor keywords` | Low |
| Tandoor | List recipes | `mp tandoor recipes` | High |
| Tandoor | Get recipe details | `mp tandoor detail <id>` | High |
| Meal Planning | Generate meal plan | `mp plan generate` | High |
| Nutrition | Daily status | `mp nutrition daily-status` | Medium |
| Nutrition | Dinner recommendations | `mp nutrition recommend-dinner` | Medium |
| Advisor | Weekly compliance score | `mp advisor compliance` | Low |
| Scheduler | List job executions | `mp scheduler executions --id <id>` | Medium |
| Preferences | Get user preferences | `mp preferences get` | Low |

### Missing API Endpoints

| Domain | CLI Command | Missing API Endpoint | Priority |
|---------|---------------|---------------------|----------|
| Nutrition | Report generation | None (CLI uses internal NCP) | N/A |
| Scheduler | Create job | ✅ `POST /api/scheduler/jobs` (in handler) | N/A |

---

## Implementation Priority

### High Priority (Core User Workflows)

1. **Recipe Domain**
   - `mp recipe list` - List all recipes from Tandoor
   - `mp recipe detail <id>` - Get full recipe details
   - `mp recipe create <args>` - Create new recipe in Tandoor

2. **Meal Planning**
   - `mp plan generate <args>` - Generate meal plan via constraint solver
   - Map to API: `POST /api/meal-planning/generate`

3. **Tandoor Domain**
   - `mp tandoor recipes` - List recipes (separate from recipe search)
   - `mp tandoor detail <id>` - Get recipe details
   - `mp tandoor create <args>` - Create new recipe
   - `mp tandoor delete <id>` - Delete recipe

### Medium Priority (Enhanced Functionality)

1. **FatSecret**
   - `mp fatsecret ingredients <id>` - Get food ingredients/variants

2. **Nutrition**
   - `mp nutrition daily-status` - Daily nutrition status
   - `mp nutrition recommend-dinner` - Get dinner recommendations

3. **Scheduler**
   - `mp scheduler executions --id <id>` - View job execution history

### Low Priority (Auxiliary Features)

1. **Tandoor**
   - `mp tandoor cuisines` - List available cuisines
   - `mp tandoor units` - List measurement units
   - `mp tandoor keywords` - List keywords

2. **Preferences**
   - `mp preferences get <key>` - Get specific preference

3. **Web**
   - `mp web stop` - Stop web server

---

## Next Steps

### 1. Create CLI Commands for High Priority Items

#### Recipe Domain (src/meal_planner/cli/domains/recipe.gleam)
- Add `list` command - List recipes with pagination
- Add `detail` command - Show full recipe details
- Add `create` command - Create new recipe
- Add `delete` command - Delete recipe
- Map to Tandoor API handlers

#### Meal Planning Domain (src/meal_planner/cli/domains/plan.gleam)
- Add `generate` command - Generate meal plan via constraint solver
- Integrate with `automation/plan_generator/generator.gleam`
- Accept constraints (calories, meal type preferences, etc.)

#### Tandoor Domain (src/meal_planner/cli/domains/tandoor.gleam)
- Add `recipes` command - List recipes from Tandoor
- Add `detail` command - Get recipe details
- Add `create` command - Create new recipe
- Add `delete` command - Delete recipe
- Map to Tandoor API handlers

### 2. Add Missing API Routes (if any)

Review web handlers to ensure all needed endpoints exist:
- Recipe CRUD operations
- Meal plan generation via CLI
- Dinner recommendations via CLI

### 3. Update CLI Routing

Update `src/meal_planner/cli/glint_commands.gleam` to register new commands.

---

## Notes

- CLI commands in `cli/domains/*/` map to subcommands: `mp <domain> <command>`
- API routes follow RESTful patterns: `/api/<domain>/<resource>[/<id>]`
- Web handlers reuse same service layers as CLI commands
- Some CLI commands use internal NCP (Nutrition Control Plane) directly
- Scheduler commands need database connection for status queries

---

## Status

### Current Coverage: ~70%
- Core CRUD operations: ✅ Complete
- Search and listing: ✅ Mostly complete
- Meal planning: ⚠️  Missing `generate` command
- Recipe management: ⚠️  Missing `list`, `detail`, `create`, `delete`
- Nutrition reporting: ✅ Complete
- Advisor features: ⚠️  Missing `compliance` command
- Scheduler: ⚠️  Missing `executions` command

### Target Coverage: 100%
- Add remaining high and medium priority commands
- Ensure all API endpoints have corresponding CLI commands
- Test end-to-end workflows via CLI
