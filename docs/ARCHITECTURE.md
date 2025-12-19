# Architecture Overview - Autonomous Nutritional Control Plane

## North Star: Complete Automation of Nutritional Management

The meal-planner system is an autonomous nutritional control plane that eliminates manual tracking through intelligent automation. Users provide high-level constraints (dietary preferences, macro targets, travel dates) and the system handles everything else: weekly meal planning, recipe selection, FatSecret sync, daily recommendations, and continuous optimization based on historical trends.

## System Philosophy

- **Autonomous First**: The system operates without user intervention. Once configured, it runs continuously.
- **Constraint-Driven**: Users express intent through constraints (macros, preferences, locked meals), not micromanagement.
- **Feedback-Integrated**: Email commands provide lightweight adjustments without breaking automation.
- **FatSecret-Backed**: All nutritional tracking syncs to FatSecret Platform API for centralized data.
- **Database-Persisted**: Schedules, executions, and state survive service restarts.

## High-Level Data Flow

```
┌─────────────────────┐
│ Constraint Input    │
│ (UI/Email/API)      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Generation Engine   │ ← Tandoor (recipes)
│ (weekly.gleam)      │ ← User profile (macros)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Scheduler Executor  │
│ (executor.gleam)    │ ← Job queue (DB)
└──────────┬──────────┘
           │
           ├──────────────────┐
           │                  │
           ▼                  ▼
┌──────────────────┐  ┌──────────────────┐
│ FatSecret Sync   │  │ Email Feedback   │
│ (meal_sync.gleam)│  │ (parser.gleam)   │
└──────────────────┘  └──────────────────┘
           │                  │
           ▼                  ▼
┌─────────────────────────────────────────┐
│ Daily Advisor (daily_recommendations)   │
│ Weekly Trends (weekly_trends)           │
└─────────────────────────────────────────┘
```

## System Components

### 1. Weekly Generation Engine (`generator/weekly.gleam`)

**Purpose**: Generate complete 7-day meal plans with balanced macros.

**Inputs**:
- Available recipes (from Tandoor)
- Target macros (protein, carbs, fat, calories)
- Constraints (locked meals, travel dates)
- Rotation history (avoid repeating recent recipes)

**Algorithm**:
1. **ABABA Pattern**:
   - Breakfasts: 7 unique recipes (no repeats)
   - Lunches: Alternate between 2 recipes (ABABABA)
   - Dinners: Alternate between 2 recipes (ABABABA)
2. **Macro Balancing**: Validate each day within ±10% of target macros
3. **Constraint Application**: Override default selections with locked meals
4. **Rotation Filtering**: Exclude recipes used within rotation window (default: 14 days)

**Outputs**:
- `WeeklyMealPlan`: 7 days × 3 meals = 21 total meals
- Daily macro summaries (protein, carbs, fat, calories)
- Grocery list (aggregated ingredients)

**Key Functions**:
- `generate_meal_plan()`: Main generation with constraints
- `filter_by_rotation()`: Remove recently used recipes
- `analyze_plan()`: Daily macro comparison vs targets
- `is_plan_balanced()`: Validation (all days within ±10%)

### 2. Scheduler Executor (`scheduler/executor.gleam`)

**Purpose**: Route scheduled jobs to appropriate handlers with retry logic.

**Job Types**:
- `WeeklyGeneration`: Generate meal plan (Friday 6 AM)
- `AutoSync`: Sync meals to FatSecret (every 2-4 hours)
- `DailyAdvisor`: Send daily recommendations (8 PM)
- `WeeklyTrends`: Analyze weekly patterns (Thursday 8 PM)

**Execution Flow**:
1. Fetch job from database (pending status)
2. Mark job as "running"
3. Pattern match on `JobType`
4. Call handler (weekly_plan, meal_sync, daily_recommendations, weekly_trends)
5. Capture output/error
6. Update job status (completed/failed)
7. Record execution history

**Retry Logic**:
- Transient errors (API failures, timeouts): Exponential backoff (60s × 2^attempt)
- Permanent errors (invalid config, database): No retry
- Max retries: 3 attempts (configurable)

**Database Schema**:
- `scheduled_jobs`: Job definitions (type, frequency, status, retry_policy)
- `job_executions`: Execution history (output, errors, duration)

**Key Functions**:
- `execute_scheduled_job()`: Main executor (routes by JobType)
- `execute_weekly_generation()`: Generate meal plan
- `execute_auto_sync()`: Sync to FatSecret
- `execute_daily_advisor()`: Send daily email
- `execute_weekly_trends()`: Analyze trends

### 3. Email Feedback Loop (`email/parser.gleam`)

**Purpose**: Parse email commands from users to adjust meal plans.

**Supported Commands**:
- `@Claude adjust Friday dinner to pasta` → Change specific meal
- `@Claude regenerate week with high protein` → Re-run generation
- `@Claude I hate Brussels sprouts` → Add to dislike list
- `@Claude add more vegetables` → Update preferences
- `@Claude skip breakfast Monday` → Mark meal as skipped

**Pattern Matching**:
1. Validate `@Claude` mention
2. Extract command keywords (`adjust`, `regenerate`, `hate`, `add`, `skip`)
3. Parse arguments (day, meal_type, recipe, constraints)
4. Return `EmailCommand` for executor

**Extensibility**: Add new commands by implementing `CommandPattern`:
```gleam
CommandPattern(
  keywords: ["new_command"],
  parser: parse_new_command
)
```

**Key Functions**:
- `parse_email_command()`: Entry point with @Claude validation
- `parse_adjust_command()`: Extract day/meal/recipe
- `parse_regenerate_command()`: Extract scope (day/week/meal) + constraints

### 4. FatSecret Sync (`meal_sync.gleam`)

**Purpose**: Sync planned meals to FatSecret diary.

**Sync Flow**:
1. Fetch recipe details from Tandoor (nutrition info)
2. Calculate serving-adjusted macros
3. Convert to FatSecret diary entry format
4. Create entry via FatSecret API (OAuth 1.0a)
5. Return sync status (success/failed)

**Nutrition Aggregation**:
- Recipe base macros (per serving)
- User servings multiplier
- Final macros = base × (user_servings / recipe_servings)

**Sync Scheduler**:
- Frequency: Every 2-4 hours (configurable)
- Target: Log meals for current/next day
- Idempotency: Check for existing entries before creating

**Error Handling**:
- Invalid recipe: Skip meal, log error
- API rate limit: Retry with exponential backoff
- Invalid date: Fail immediately (no retry)

**Key Functions**:
- `sync_meals()`: Batch sync (list of MealSelection)
- `sync_single_meal()`: Individual meal sync
- `get_meal_nutrition()`: Fetch + aggregate nutrition
- `format_sync_report()`: Success/failure summary

### 5. Daily Advisor (`advisor/daily_recommendations.gleam`)

**Purpose**: Generate daily nutrition recommendations (sent at 8 PM).

**Analysis**:
1. Fetch today's FatSecret diary entries
2. Calculate actual macros (sum of all entries)
3. Fetch user's target macros (profile goals)
4. Compare actual vs target (±10% tolerance)
5. Generate insights (under/on-track/over)
6. Calculate 7-day rolling average trend

**Insight Generation**:
- **Under**: "Protein is 25g under target - add more protein"
- **Over**: "Calories are 200cal over target - you're over budget"
- **OnTrack**: "Great job! All macros are on track."

**Trend Analysis**:
- Fetch past 7 days of entries
- Calculate average macros
- Identify patterns (protein deficiency, carb spikes)

**Email Format**:
```
📊 Daily Nutrition Advisor - 2025-01-15

Actual: 1850 cal, 120g protein, 50g fat, 180g carbs
Target: 2000 cal, 150g protein, 55g fat, 200g carbs

📈 Insights:
- Protein is 30g under target - add more protein
- Calories are 150cal under target - consider a snack

📅 7-Day Trend:
Avg: 1900 cal, 125g protein, 52g fat, 190g carbs
```

**Key Functions**:
- `generate_daily_advisor_email()`: Main entry point
- `calculate_total_macros()`: Sum FatSecret entries
- `extract_target_macros()`: Profile → target macros
- `calculate_macro_status()`: Under/OnTrack/Over
- `generate_insight_messages()`: Actionable recommendations

### 6. Weekly Trends (`advisor/weekly_trends.gleam`)

**Purpose**: Analyze 7-day patterns and feed insights into next week's generation.

**Analysis**:
1. Fetch past 7 days of FatSecret diary summaries
2. Calculate macro averages (protein, carbs, fat, calories)
3. Identify patterns (deficiencies, overages, consistency)
4. Find best/worst days (closest/furthest from targets)
5. Generate recommendations for next week

**Pattern Examples**:
- `protein_deficiency`: Avg protein < 90% of target for 5+ days
- `carb_overage`: Avg carbs > 110% of target for 5+ days
- `inconsistent_calories`: Daily variance > 20% of target

**Recommendation Logic**:
- Protein deficiency → "Add high-protein breakfast options"
- Carb overage → "Reduce dinner carbs, increase lunch protein"
- Best day pattern → "Friday's meals were optimal - repeat this pattern"

**Email Format**:
```
📊 Weekly Nutrition Trends - Jan 8-14, 2025

📈 Averages:
Protein: 125g (target: 150g) ❌
Carbs: 210g (target: 200g) ✅
Fat: 50g (target: 55g) ✅
Calories: 1900 (target: 2000) ❌

🔍 Patterns:
- Protein deficiency detected (5/7 days under target)
- Carbs consistently on track

🏆 Best Day: Friday (98% of targets)
⚠️ Worst Day: Tuesday (75% of targets)

💡 Recommendations:
1. Add high-protein breakfast options (Greek yogurt, eggs)
2. Increase lunch protein by 20g
3. Friday's meal pattern is optimal - use as template
```

**Key Functions**:
- `analyze_weekly_trends()`: Main analysis entry point
- `calculate_macro_averages()`: 7-day averages
- `identify_nutrition_patterns()`: Pattern detection
- `find_best_worst_days()`: Best/worst day analysis
- `generate_pattern_recommendations()`: Actionable insights

## Key Algorithms

### Algorithm 1: Weekly Generation (One-Time, All-In-One)

**Decision**: Generate entire week in one call (not incremental).

**Rationale**:
- Simpler to reason about (all constraints applied at once)
- Easier to balance macros across 7 days
- Batch efficiency (one API call for recipes)
- Atomic operation (all-or-nothing)

**Steps**:
1. Fetch available recipes from Tandoor
2. Filter by rotation history (exclude recent recipes)
3. Separate into breakfast/lunch/dinner pools
4. Select 7 breakfasts (unique)
5. Select lunches (ABABA pattern, 2 recipes)
6. Select dinners (ABABA pattern, 2 recipes)
7. Apply locked meal overrides
8. Validate macro balance (±10% per day)
9. Return complete WeeklyMealPlan

**Constraints**:
- Minimum recipes: 7 breakfasts, 2 lunches, 2 dinners
- Macro tolerance: ±10% per day
- Rotation window: 14 days (configurable)

### Algorithm 2: Auto Sync (Every 2-4 Hours)

**Decision**: Job queue + database persistence (not cron).

**Rationale**:
- Survives service restarts (jobs recorded in DB)
- Retry logic built-in (exponential backoff)
- Audit trail (execution history)
- Priority ordering (high-priority jobs first)

**Steps**:
1. Scheduler checks database for pending jobs
2. Fetch jobs due for execution (scheduled_for <= now)
3. Sort by priority (Critical > High > Medium > Low)
4. Execute top job (mark as "running")
5. Fetch today's + tomorrow's meals from meal_plan table
6. For each meal:
   - Fetch recipe nutrition from Tandoor
   - Calculate serving-adjusted macros
   - Create FatSecret diary entry
   - Record sync status
7. Update job status (completed/failed)
8. Record execution result (output JSON)

**Error Handling**:
- API rate limit → Retry with exponential backoff (60s, 120s, 240s)
- Invalid recipe → Skip meal, log error, continue
- Invalid date → Fail immediately (no retry)

### Algorithm 3: Email Parsing (Pattern Matching, Extensible)

**Decision**: Simple pattern matching (not full NLP).

**Rationale**:
- Enough for MVP ("adjust Friday dinner to pasta")
- Extensible (add new command types easily)
- Gleam pattern matching (exhaustive, type-safe)
- No external dependencies (no ML models)

**Steps**:
1. Validate email body contains "@Claude" mention
2. Extract command keywords (adjust, regenerate, hate, add, skip)
3. Pattern match on keyword (priority order)
4. Parse command-specific arguments:
   - `adjust`: Extract day, meal_type, recipe
   - `regenerate`: Extract scope (week/day/meal) + constraints
   - `hate`: Extract food name
   - `add`: Extract preference text
   - `skip`: Extract day, meal_type
5. Validate parsed arguments (day exists, meal_type valid)
6. Return `EmailCommand` or `InvalidCommand(reason)`

**Extensibility**:
```gleam
// Add new command by adding to pattern list
CommandPattern(
  keywords: ["swap"],
  parser: parse_swap_command
)
```

## Type System Overview

### Core Domain Types

**Recipe** (`types.gleam`):
```gleam
pub type Recipe {
  Recipe(
    id: Int,
    name: String,
    macros: Macros,
    servings: Int
  )
}

pub type Macros {
  Macros(
    protein: Float,
    carbs: Float,
    fat: Float
  )
}
```

**MealPlan** (`generator/weekly.gleam`):
```gleam
pub type WeeklyMealPlan {
  WeeklyMealPlan(
    week_of: String,          // "2025-01-06"
    days: List(DayMeals),     // 7 days
    target_macros: Macros
  )
}

pub type DayMeals {
  DayMeals(
    day: String,              // "Monday"
    breakfast: Recipe,
    lunch: Recipe,
    dinner: Recipe
  )
}
```

**ScheduledJob** (`scheduler/types.gleam`):
```gleam
pub type ScheduledJob {
  ScheduledJob(
    id: JobId,
    job_type: JobType,        // WeeklyGeneration | AutoSync | DailyAdvisor | WeeklyTrends
    frequency: JobFrequency,  // Weekly | Daily | EveryNHours | Once
    status: JobStatus,        // Pending | Running | Completed | Failed
    retry_policy: RetryPolicy,
    parameters: Option(Json),
    scheduled_for: Option(String),
    // ...
  )
}
```

**EmailCommand** (`types.gleam`):
```gleam
pub type EmailCommand {
  AdjustMeal(day: DayOfWeek, meal_type: MealType, recipe_id: RecipeId)
  RegeneratePlan(scope: RegenerationScope, constraints: Option(String))
  RemoveDislike(food_name: String)
  AddPreference(preference: String)
  SkipMeal(day: DayOfWeek, meal_type: MealType)
}
```

### FatSecret Integration Types

**FoodEntry** (`fatsecret/diary/types.gleam`):
```gleam
pub type FoodEntry {
  FoodEntry(
    food_entry_id: FoodEntryId,
    food_entry_name: String,
    serving_description: String,
    number_of_units: Float,
    meal: MealType,           // Breakfast | Lunch | Dinner | Snack
    calories: Float,
    carbohydrate: Float,
    protein: Float,
    fat: Float
  )
}
```

**DaySummary** (`fatsecret/diary/types.gleam`):
```gleam
pub type DaySummary {
  DaySummary(
    date_int: Int,            // Days since epoch
    calories: Float,
    carbohydrate: Float,
    protein: Float,
    fat: Float
  )
}
```

## Database Schema

### Core Tables

**scheduled_jobs**:
```sql
CREATE TABLE scheduled_jobs (
  id TEXT PRIMARY KEY,
  job_type TEXT NOT NULL,         -- 'weekly_generation' | 'auto_sync' | 'daily_advisor' | 'weekly_trends'
  frequency JSONB NOT NULL,       -- { type: 'weekly', day: 5, hour: 6, minute: 0 }
  status TEXT NOT NULL,           -- 'pending' | 'running' | 'completed' | 'failed'
  priority TEXT NOT NULL,         -- 'low' | 'medium' | 'high' | 'critical'
  retry_policy JSONB NOT NULL,    -- { max_attempts: 3, backoff_seconds: 60, retry_on_failure: true }
  parameters JSONB,               -- Job-specific params
  scheduled_for TIMESTAMPTZ,      -- When to execute
  started_at TIMESTAMPTZ,         -- When execution started
  completed_at TIMESTAMPTZ,       -- When execution finished
  last_error TEXT,                -- Last error message
  error_count INTEGER DEFAULT 0,  -- Retry attempt counter
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by TEXT,                -- User ID (NULL for system jobs)
  enabled BOOLEAN DEFAULT TRUE
);
```

**job_executions**:
```sql
CREATE TABLE job_executions (
  id SERIAL PRIMARY KEY,
  job_id TEXT REFERENCES scheduled_jobs(id),
  started_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  status TEXT NOT NULL,           -- 'running' | 'completed' | 'failed'
  error_message TEXT,
  attempt_number INTEGER NOT NULL,
  duration_ms INTEGER,            -- Execution time
  output JSONB,                   -- Result data (GenerationResult, SyncResult, etc.)
  triggered_by JSONB NOT NULL     -- { type: 'scheduled' | 'manual' | 'retry' | 'dependent' }
);
```

## Integration Points

### Tandoor API
- **Endpoint**: `/api/recipe/{id}/`
- **Auth**: Token-based (X-API-KEY header)
- **Usage**: Fetch recipe details (nutrition, ingredients, steps)
- **Rate Limit**: None (self-hosted)

### FatSecret Platform API
- **Auth**: OAuth 1.0a (HMAC-SHA1 signatures)
- **Endpoints**:
  - `food_entry.create`: Create diary entry
  - `food_entries.get`: Fetch day's entries
  - `food_entry.get_month`: Fetch monthly summary
  - `profile.get`: Fetch user goals
- **Rate Limit**: 5000 requests/day (tier 2)

### Database
- **Type**: PostgreSQL 14+
- **Connection**: Pog (Gleam PostgreSQL client)
- **Pooling**: Built-in connection pooling
- **Migrations**: SQL files in `schema/`

## Deployment Architecture

### Production Setup
```
┌─────────────────────┐
│ Docker Container    │
│ - Gleam runtime     │
│ - PostgreSQL client │
│ - Cron scheduler    │
└──────────┬──────────┘
           │
           ├──────────────────┐
           │                  │
           ▼                  ▼
┌──────────────────┐  ┌──────────────────┐
│ PostgreSQL DB    │  │ External APIs    │
│ (jobs, history)  │  │ - Tandoor        │
└──────────────────┘  │ - FatSecret      │
                      └──────────────────┘
```

### Environment Variables
- `DATABASE_URL`: PostgreSQL connection string
- `TANDOOR_URL`: Tandoor API base URL
- `TANDOOR_API_KEY`: Tandoor authentication token
- `FATSECRET_CLIENT_ID`: FatSecret OAuth client ID
- `FATSECRET_CLIENT_SECRET`: FatSecret OAuth secret

## Error Handling Strategy

### Transient Errors (Retry)
- API rate limits → Exponential backoff
- Network timeouts → Exponential backoff
- Temporary database locks → Exponential backoff

### Permanent Errors (No Retry)
- Invalid job configuration → Log + alert
- Missing required data → Log + alert
- Authentication failures → Log + alert

### Error Propagation
- Use `Result(T, E)` everywhere (no exceptions)
- Map errors to domain types before chaining
- Railway-oriented programming (use `result.try`)

## Monitoring & Observability

### Metrics
- Job execution count (by type, status)
- Job duration (p50, p95, p99)
- Retry attempts (by job type)
- API call latency (Tandoor, FatSecret)

### Logging
- Job execution start/end (INFO)
- API call failures (WARN)
- Unrecoverable errors (ERROR)
- Debug: SQL queries, API requests (DEBUG)

### Alerting
- Job failure rate > 10% → Alert
- No jobs executed in 24h → Alert
- Database connection failures → Alert

## Future Enhancements

### Short-Term
1. **Grocery List Generation**: Aggregate ingredients from weekly plan
2. **Recipe Swapping**: Allow mid-week recipe substitutions
3. **Macro Adjustment**: Auto-adjust recipes to hit macro targets

### Long-Term
1. **ML-Based Recommendations**: Learn user preferences over time
2. **Multi-User Support**: Family meal planning with individual macros
3. **Mobile App**: Push notifications for daily advisor
4. **Integration**: MyFitnessPal, Lose It, other nutrition trackers
