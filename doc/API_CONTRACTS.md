# API Contracts Documentation

## Overview

This document provides OpenAPI-style contract documentation for the meal-planner Phase 3 autonomous nutritional control plane. It covers:

1. **Generation Engine** - Weekly meal plan generation with constraints and macro targeting
2. **Scheduler Executor** - Automated job scheduling and execution (Friday 6 AM generation, auto-sync, daily advisor, weekly trends)
3. **Email Feedback** - Natural language command parsing for meal plan adjustments

All APIs use JSON for request/response payloads and follow REST conventions.

---

## Generation Engine

### Generate Weekly Meal Plan

**Endpoint:** `POST /generation/generate-weekly-plan`

**Description:** Generate a complete 7-day meal plan based on user constraints, macro profile, and dietary preferences. Uses Tandoor recipes and applies Vertical Diet + Tim Ferriss principles.

#### Request

```json
{
  "week_of": "2025-12-22",
  "user_id": "user-12345",
  "constraints": {
    "locked_meals": [
      {
        "day": "Monday",
        "meal_type": "breakfast",
        "recipe": {
          "id": "recipe-101",
          "name": "Protein Pancakes",
          "ingredients": [
            {
              "name": "Oats",
              "quantity": "1 cup"
            },
            {
              "name": "Eggs",
              "quantity": "2 large"
            }
          ],
          "instructions": ["Blend oats into flour", "Mix with eggs", "Cook on griddle"],
          "macros": {
            "protein": 25.0,
            "fat": 9.0,
            "carbs": 32.0,
            "calories": 305.0
          },
          "servings": 2,
          "category": "Breakfast",
          "fodmap_level": "low",
          "vertical_compliant": true
        }
      }
    ],
    "travel_dates": ["Friday", "Saturday"]
  },
  "macro_profile": {
    "goal_weight_kg": 75.0,
    "last_weight_kg": 78.5,
    "last_weight_date_int": 20251215,
    "last_weight_comment": "Holiday weight gain",
    "height_cm": 175.0,
    "calorie_goal": 2400,
    "weight_measure": "Kg",
    "height_measure": "Cm"
  }
}
```

**Request Fields:**

| Field | Type | Required | Description | Validation |
|-------|------|----------|-------------|------------|
| `week_of` | string | Yes | ISO 8601 date (YYYY-MM-DD) for start of week (Monday) | Must be future date or current week |
| `user_id` | string | Yes | User identifier | Must exist in database |
| `constraints.locked_meals` | array | No | Pre-selected meals that must be included | Each meal must have valid day/meal_type |
| `constraints.travel_dates` | array | No | Days where meals should be skipped | Valid day names (Monday-Sunday) |
| `macro_profile.goal_weight_kg` | number | Yes | Target weight in kilograms | > 0 |
| `macro_profile.calorie_goal` | number | Yes | Daily calorie target | 1200-5000 |
| `macro_profile.height_cm` | number | Yes | Height in centimeters | 100-250 |

#### Response (200 OK)

```json
{
  "meal_plan": {
    "week_of": "2025-12-22",
    "target_macros": {
      "protein": 180.0,
      "fat": 60.0,
      "carbs": 200.0,
      "calories": 2060.0
    },
    "days": [
      {
        "day": "Monday",
        "breakfast": {
          "id": "recipe-101",
          "name": "Protein Pancakes",
          "ingredients": [
            {"name": "Oats", "quantity": "1 cup"},
            {"name": "Eggs", "quantity": "2 large"}
          ],
          "instructions": ["Blend oats", "Mix with eggs", "Cook on griddle"],
          "macros": {
            "protein": 50.0,
            "fat": 18.0,
            "carbs": 65.0,
            "calories": 618.0
          },
          "servings": 2,
          "category": "Breakfast",
          "fodmap_level": "low",
          "vertical_compliant": true
        },
        "lunch": { ... },
        "dinner": { ... }
      },
      { ... }
    ]
  },
  "grocery_list": {
    "items": [
      {
        "name": "Chicken breast",
        "quantity": 600.0,
        "unit": "g",
        "category": "Meat & Seafood"
      }
    ],
    "total_items": 5
  },
  "prep_instructions": [
    {
      "recipe_id": 101,
      "recipe_name": "Protein Pancakes",
      "steps": [
        {
          "sequence": 1,
          "description": "Blend oats into flour consistency",
          "ingredients": ["Oats"],
          "time_minutes": 2
        }
      ],
      "total_time_minutes": 15,
      "batch_size": 6
    }
  ],
  "macro_summary": {
    "weekly_total": {
      "protein": 1260.0,
      "fat": 420.0,
      "carbs": 1400.0,
      "calories": 14420.0
    },
    "daily_average": {
      "protein": 180.0,
      "fat": 60.0,
      "carbs": 200.0,
      "calories": 2060.0
    },
    "daily_breakdowns": [
      {
        "day": "Monday",
        "actual": {"protein": 180.0, "fat": 60.0, "carbs": 200.0, "calories": 2060.0},
        "target": {"protein": 180.0, "fat": 60.0, "carbs": 200.0, "calories": 2060.0},
        "deviation": {"protein": 0.0, "fat": 0.0, "carbs": 0.0, "calories": 0.0},
        "calories": 2060.0
      }
    ]
  }
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `meal_plan.week_of` | string | ISO 8601 date for week start |
| `meal_plan.target_macros` | object | Daily macro targets (protein/fat/carbs in grams, calories) |
| `meal_plan.days` | array | 7 days of meals (Monday-Sunday) |
| `meal_plan.days[].day` | string | Day name (Monday-Sunday) |
| `meal_plan.days[].breakfast/lunch/dinner` | object | Recipe with macros, ingredients, instructions |
| `grocery_list.items` | array | Aggregated ingredients for the week |
| `grocery_list.total_items` | number | Total unique ingredient count |
| `prep_instructions` | array | Step-by-step meal prep instructions |
| `macro_summary.weekly_total` | object | Total macros for 7 days |
| `macro_summary.daily_average` | object | Average daily macros |
| `macro_summary.daily_breakdowns` | array | Daily actual vs target comparison |

#### Error Responses

**400 Bad Request**

```json
{
  "error": "InvalidConstraints",
  "message": "week_of date '2025-01-01' is in the past",
  "field": "week_of"
}
```

**Conditions:**
- `week_of` date is in the past
- `calorie_goal` outside valid range (1200-5000)
- Invalid day name in `travel_dates`
- Locked meal references non-existent recipe

**404 Not Found**

```json
{
  "error": "UserNotFound",
  "message": "user_id 'user-99999' does not exist",
  "user_id": "user-99999"
}
```

**503 Service Unavailable**

```json
{
  "error": "FatSecretUnavailable",
  "message": "FatSecret API connection timeout after 30s",
  "retry_after": 60
}
```

**Conditions:**
- FatSecret API unreachable
- Tandoor API unreachable
- Database connection lost

---

## Scheduler Executor

### Job Types

The scheduler supports 4 job types:

1. **WeeklyGeneration** - Friday 6 AM meal plan generation
2. **AutoSync** - Every 2-4 hours FatSecret sync
3. **DailyAdvisor** - Daily 8 PM nutrition advisor email
4. **WeeklyTrends** - Thursday 8 PM weekly trend analysis

### Create Scheduled Job

**Endpoint:** `POST /scheduler/jobs`

**Description:** Create a new scheduled job with frequency, priority, and retry configuration.

#### Request

```json
{
  "job_type": "weekly_generation",
  "frequency": {
    "type": "weekly",
    "day": 5,
    "hour": 6,
    "minute": 0
  },
  "priority": "high",
  "user_id": "user-005",
  "parameters": {
    "diet_principles": ["vertical_diet", "tim_ferriss"],
    "exclude_ingredients": ["peanuts", "shellfish"]
  },
  "retry_policy": {
    "max_attempts": 3,
    "backoff_seconds": 60,
    "retry_on_failure": true
  },
  "scheduled_for": "2025-12-27T06:00:00Z",
  "enabled": true
}
```

**Request Fields:**

| Field | Type | Required | Description | Validation |
|-------|------|----------|-------------|------------|
| `job_type` | string | Yes | Job type identifier | One of: weekly_generation, auto_sync, daily_advisor, weekly_trends |
| `frequency.type` | string | Yes | Frequency type | One of: weekly, daily, every_n_hours, once |
| `frequency.day` | number | Conditional | Day of week (0=Sunday, 6=Saturday) | Required for weekly, 0-6 |
| `frequency.hour` | number | Conditional | Hour of day (24h format) | Required for weekly/daily, 0-23 |
| `frequency.minute` | number | Conditional | Minute of hour | Required for weekly/daily, 0-59 |
| `frequency.hours` | number | Conditional | Hours between runs | Required for every_n_hours, > 0 |
| `priority` | string | Yes | Job priority | One of: low, medium, high, critical |
| `user_id` | string | No | User identifier (null for system jobs) | Must exist if provided |
| `parameters` | object | No | Job-specific configuration | JSON object |
| `retry_policy.max_attempts` | number | No | Max retry attempts (default: 3) | 0-10 |
| `retry_policy.backoff_seconds` | number | No | Base backoff delay (default: 60) | 0-3600 |
| `retry_policy.retry_on_failure` | boolean | No | Enable retries (default: true) | - |
| `scheduled_for` | string | No | Specific execution time (ISO 8601) | Future timestamp |
| `enabled` | boolean | No | Job enabled status (default: true) | - |

#### Response (201 Created)

```json
{
  "id": "job_weekly_gen_001",
  "job_type": "weekly_generation",
  "frequency": {
    "type": "weekly",
    "day": 5,
    "hour": 6,
    "minute": 0
  },
  "status": "pending",
  "priority": "high",
  "user_id": "user_001",
  "retry_policy": {
    "max_attempts": 3,
    "backoff_seconds": 60,
    "retry_on_failure": true
  },
  "parameters": {
    "include_preferences": true,
    "diet_principles": ["vertical_diet"]
  },
  "scheduled_for": "2025-12-20T06:00:00Z",
  "error_count": 0,
  "created_at": "2025-12-18T10:00:00Z",
  "updated_at": "2025-12-18T10:00:00Z",
  "created_by": "system",
  "enabled": true
}
```

### Get Job Status

**Endpoint:** `GET /scheduler/jobs/{job_id}`

**Description:** Retrieve current status and metadata for a scheduled job.

#### Response (200 OK)

```json
{
  "id": "job_auto_sync_001",
  "job_type": "auto_sync",
  "frequency": {
    "type": "every_n_hours",
    "hours": 3
  },
  "status": "running",
  "priority": "medium",
  "retry_policy": {
    "max_attempts": 5,
    "backoff_seconds": 120,
    "retry_on_failure": true
  },
  "parameters": {
    "sync_type": "fatsecret",
    "full_sync": false
  },
  "started_at": "2025-12-19T12:00:00Z",
  "error_count": 0,
  "created_at": "2025-12-18T10:00:00Z",
  "updated_at": "2025-12-19T12:00:00Z",
  "enabled": true
}
```

**Status Values:**

| Status | Description |
|--------|-------------|
| `pending` | Job scheduled but not yet running |
| `running` | Job currently executing |
| `completed` | Job finished successfully |
| `failed` | Job failed (may retry based on policy) |

### Get Job Execution History

**Endpoint:** `GET /scheduler/jobs/{job_id}/executions`

**Description:** Retrieve execution history for a job, including output and error details.

#### Response (200 OK)

```json
{
  "job_id": "job_daily_advisor_001",
  "executions": [
    {
      "id": 1,
      "job_id": "job_daily_advisor_001",
      "started_at": "2025-12-19T20:00:05Z",
      "completed_at": "2025-12-19T20:00:12Z",
      "status": "completed",
      "attempt_number": 1,
      "duration_ms": 7000,
      "output": {
        "email_sent": true,
        "recipient": "user@example.com",
        "subject": "Your Daily Nutrition Advisor"
      },
      "triggered_by": {
        "type": "scheduled"
      }
    },
    {
      "id": 2,
      "job_id": "job_failed_001",
      "started_at": "2025-12-19T10:00:05Z",
      "completed_at": "2025-12-19T10:00:15Z",
      "status": "failed",
      "error_message": "Connection timeout: tandoor.example.com:8080",
      "attempt_number": 2,
      "duration_ms": 10000,
      "triggered_by": {
        "type": "retry"
      }
    }
  ]
}
```

**Trigger Source Types:**

| Type | Description |
|------|-------------|
| `scheduled` | Triggered by scheduler (cron) |
| `manual` | Triggered manually via API |
| `retry` | Triggered by retry mechanism |
| `dependent` | Triggered by another job completion |

### Update Job

**Endpoint:** `PATCH /scheduler/jobs/{job_id}`

**Description:** Update job frequency, priority, parameters, or enabled status.

#### Request

```json
{
  "frequency": {
    "type": "weekly",
    "day": 6,
    "hour": 7,
    "minute": 30
  },
  "priority": "medium",
  "parameters": {
    "diet_principles": ["vertical_diet"],
    "exclude_ingredients": ["peanuts"]
  },
  "enabled": false
}
```

### Trigger Manual Job Execution

**Endpoint:** `POST /scheduler/jobs/{job_id}/trigger`

**Description:** Manually trigger a job execution (bypasses scheduled time).

#### Request

```json
{
  "parameters": {
    "regenerate_scope": "full_week",
    "constraints": "vegetarian"
  }
}
```

#### Response (202 Accepted)

```json
{
  "job_id": "job_manual_001",
  "execution_id": 3,
  "status": "running",
  "triggered_by": {
    "type": "manual"
  },
  "started_at": "2025-12-19T14:30:00Z"
}
```

### Job Execution Output Schemas

#### Weekly Generation Output

```json
{
  "meal_plan_id": "plan_2025_w51",
  "recipes_generated": 28,
  "total_macros": {
    "protein": 2100.5,
    "fat": 700.2,
    "carbs": 2800.8
  }
}
```

#### Auto-Sync Output

```json
{
  "synced": 15,
  "skipped": 3,
  "failed": 0,
  "errors": []
}
```

#### Daily Advisor Output

```json
{
  "status": "success",
  "date": "2025-12-19",
  "actual_calories": 2150.0,
  "target_calories": 2060.0,
  "insights": [
    "Protein intake 5% above target - excellent!",
    "Carbs slightly high - consider reducing dinner portion"
  ]
}
```

#### Weekly Trends Output

```json
{
  "status": "success",
  "days_analyzed": 7,
  "avg_protein": 175.5,
  "avg_carbs": 205.2,
  "avg_fat": 62.8,
  "avg_calories": 2088.0,
  "patterns": [
    "Consistent protein intake throughout week",
    "Weekend carb intake higher than weekdays"
  ],
  "best_day": "Wednesday",
  "worst_day": "Saturday",
  "recommendations": [
    "Reduce weekend carb portions by 10%",
    "Add 200 calories on workout days"
  ]
}
```

### Error Responses

**400 Bad Request**

```json
{
  "error": "InvalidConfiguration",
  "message": "frequency.day must be 0-6 for weekly jobs",
  "field": "frequency.day"
}
```

**404 Not Found**

```json
{
  "error": "JobNotFound",
  "message": "job_id 'job-99999' does not exist",
  "job_id": "job-99999"
}
```

**409 Conflict**

```json
{
  "error": "JobAlreadyRunning",
  "message": "job_id 'job_auto_sync_001' is currently executing",
  "job_id": "job_auto_sync_001",
  "started_at": "2025-12-19T12:00:00Z"
}
```

**503 Service Unavailable**

```json
{
  "error": "SchedulerDisabled",
  "message": "Scheduler is currently disabled (maintenance mode)",
  "retry_after": 300
}
```

---

## Email Feedback

### Parse Email Command

**Endpoint:** `POST /email/parse-command`

**Description:** Parse natural language email commands from Lewis to adjust meal plans, preferences, and trigger regenerations. Commands must include `@Claude` mention.

#### Request

```json
{
  "from": "lewis@example.com",
  "subject": "Meal plan adjustment",
  "body": "I got tacos from a new place and want to try them on Friday dinner instead of the planned meal. @Claude adjust Friday dinner to tacos",
  "received_at": "2025-12-19T14:30:00Z"
}
```

**Request Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `from` | string | Yes | Sender email address |
| `subject` | string | Yes | Email subject line |
| `body` | string | Yes | Email body (must contain `@Claude` mention) |
| `received_at` | string | Yes | ISO 8601 timestamp |

#### Response (200 OK)

```json
{
  "command": {
    "type": "AdjustMeal",
    "day": "Friday",
    "meal_type": "Dinner",
    "recipe_id": "recipe-123"
  },
  "parsed_from": "I got tacos from a new place and want to try them on Friday dinner instead of the planned meal. @Claude adjust Friday dinner to tacos",
  "confidence": "high"
}
```

### Command Types

#### AdjustMeal

**Syntax:** `@Claude adjust {day} {meal} to {recipe_name}`

**Examples:**
- `@Claude adjust Friday dinner to pasta`
- `@Claude adjust Monday breakfast to oatmeal`

**Response:**

```json
{
  "type": "AdjustMeal",
  "day": "Friday",
  "meal_type": "Dinner",
  "recipe_id": "recipe-tacos-001"
}
```

**Fields:**

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `day` | string | Day of week | Monday-Sunday |
| `meal_type` | string | Meal identifier | Breakfast, Lunch, Dinner, Snack |
| `recipe_id` | string | Recipe identifier | Must exist in Tandoor |

#### RemoveDislike

**Syntax:** `@Claude I hate {food_name}` or `@Claude I don't like {food_name}`

**Examples:**
- `@Claude I hate Brussels sprouts`
- `@Claude I don't like mushrooms`

**Response:**

```json
{
  "type": "RemoveDislike",
  "food_name": "Brussels sprouts"
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `food_name` | string | Food to avoid in future plans |

#### AddPreference

**Syntax:** `@Claude add {preference}`

**Examples:**
- `@Claude add more vegetables`
- `@Claude add high protein meals`

**Response:**

```json
{
  "type": "AddPreference",
  "preference": "more vegetables"
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `preference` | string | Preference description (free text) |

#### RegeneratePlan

**Syntax:** `@Claude regenerate {scope} [with {constraint}]`

**Examples:**
- `@Claude regenerate week with high protein`
- `@Claude regenerate day with low carb`
- `@Claude regenerate meal`

**Response:**

```json
{
  "type": "RegeneratePlan",
  "scope": "FullWeek",
  "constraints": "high_protein"
}
```

**Fields:**

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `scope` | string | Regeneration scope | SingleMeal, SingleDay, FullWeek |
| `constraints` | string (optional) | Constraint description | high_protein, low_carb, variety |

#### SkipMeal

**Syntax:** `@Claude skip {meal} {day}`

**Examples:**
- `@Claude skip breakfast Tuesday`
- `@Claude skip lunch Friday`

**Response:**

```json
{
  "type": "SkipMeal",
  "day": "Tuesday",
  "meal_type": "Breakfast"
}
```

**Fields:**

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `day` | string | Day of week | Monday-Sunday |
| `meal_type` | string | Meal identifier | Breakfast, Lunch, Dinner, Snack |

### Execute Email Command

**Endpoint:** `POST /email/execute-command`

**Description:** Execute a parsed email command and update meal plan/preferences.

#### Request

```json
{
  "command": {
    "type": "AdjustMeal",
    "day": "Friday",
    "meal_type": "Dinner",
    "recipe_id": "recipe-123"
  },
  "user_id": "user-001"
}
```

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Updated Dinner for Friday",
  "command": {
    "type": "AdjustMeal",
    "day": "Friday",
    "meal_type": "Dinner",
    "recipe_id": "recipe-123"
  }
}
```

### Error Responses

**400 Bad Request - No @Claude Mention**

```json
{
  "error": "InvalidCommand",
  "message": "No @Claude mention found",
  "body": "Hey, just wanted to let you know I enjoyed the salmon this week!"
}
```

**400 Bad Request - Unrecognized Command**

```json
{
  "error": "InvalidCommand",
  "message": "Command not recognized",
  "body": "@Claude please do something vague"
}
```

**400 Bad Request - Invalid Day/Meal**

```json
{
  "error": "InvalidCommand",
  "message": "Could not parse day or meal type",
  "field": "day"
}
```

**404 Not Found - Recipe Not Found**

```json
{
  "error": "RecipeNotFound",
  "message": "Recipe 'tacos' not found in Tandoor",
  "recipe_name": "tacos"
}
```

---

## Data Types

### Common Types

#### Macros

```json
{
  "protein": 180.0,
  "fat": 60.0,
  "carbs": 200.0,
  "calories": 2060.0
}
```

**Fields:**
- `protein` (number): Grams of protein
- `fat` (number): Grams of fat
- `carbs` (number): Grams of carbohydrates
- `calories` (number): Total calories (calculated: protein*4 + fat*9 + carbs*4)

#### Recipe

```json
{
  "id": "recipe-101",
  "name": "Protein Pancakes",
  "ingredients": [
    {"name": "Oats", "quantity": "1 cup"},
    {"name": "Eggs", "quantity": "2 large"}
  ],
  "instructions": ["Blend oats", "Mix with eggs", "Cook on griddle"],
  "macros": {
    "protein": 50.0,
    "fat": 18.0,
    "carbs": 65.0,
    "calories": 618.0
  },
  "servings": 2,
  "category": "Breakfast",
  "fodmap_level": "low",
  "vertical_compliant": true
}
```

**Fields:**
- `id` (string): Unique recipe identifier
- `name` (string): Recipe name
- `ingredients` (array): List of ingredients with quantities
- `instructions` (array): Step-by-step cooking instructions
- `macros` (object): Nutritional information
- `servings` (number): Number of servings recipe yields
- `category` (string): Meal category (Breakfast, Lunch, Dinner, Snack)
- `fodmap_level` (string): FODMAP classification (low, medium, high)
- `vertical_compliant` (boolean): Vertical Diet compliance

#### DayOfWeek

**Enum:** `Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`, `Saturday`, `Sunday`

#### MealType

**Enum:** `Breakfast`, `Lunch`, `Dinner`, `Snack`

#### JobType

**Enum:** `weekly_generation`, `auto_sync`, `daily_advisor`, `weekly_trends`

#### JobStatus

**Enum:** `pending`, `running`, `completed`, `failed`

#### JobPriority

**Enum:** `low`, `medium`, `high`, `critical`

---

## Validation Rules

### Field Validation

| Field | Rule | Error Message |
|-------|------|---------------|
| `week_of` | ISO 8601 date, not in past | "week_of date must not be in the past" |
| `calorie_goal` | 1200-5000 | "calorie_goal must be between 1200 and 5000" |
| `day` | Monday-Sunday | "day must be a valid day of week" |
| `meal_type` | Breakfast/Lunch/Dinner/Snack | "meal_type must be Breakfast, Lunch, Dinner, or Snack" |
| `recipe_id` | Must exist in Tandoor | "recipe_id not found in Tandoor" |
| `job_type` | Valid job type enum | "job_type must be one of: weekly_generation, auto_sync, daily_advisor, weekly_trends" |
| `frequency.day` | 0-6 (0=Sunday) | "frequency.day must be 0-6 for weekly jobs" |
| `frequency.hour` | 0-23 | "frequency.hour must be 0-23" |
| `frequency.minute` | 0-59 | "frequency.minute must be 0-59" |
| `retry_policy.max_attempts` | 0-10 | "retry_policy.max_attempts must be 0-10" |

### Encoder/Decoder Symmetry

All type definitions support bidirectional JSON conversion:

**Encoding:** Gleam type → JSON
```gleam
scheduled_job_to_json(job: ScheduledJob) -> Json
job_execution_to_json(exec: JobExecution) -> Json
generation_result_to_json(result: GenerationResult) -> Json
```

**Decoding:** JSON → Gleam type
```gleam
job_type_decoder() -> Decoder(JobType)
job_status_decoder() -> Decoder(JobStatus)
retry_policy_decoder() -> Decoder(RetryPolicy)
```

**Roundtrip Test:**
```gleam
// Given a ScheduledJob
let original = ScheduledJob(...)
let json = scheduled_job_to_json(original)
let decoded = json.decode(json, scheduled_job_decoder())

// Assert: decoded == Ok(original)
```

---

## Error Handling

### Error Response Format

All errors follow consistent structure:

```json
{
  "error": "ErrorType",
  "message": "Human-readable error description",
  "field": "field_name",
  "details": { ... }
}
```

### HTTP Status Codes

| Code | Usage |
|------|-------|
| 200 OK | Successful request |
| 201 Created | Resource created (job, plan) |
| 202 Accepted | Request accepted (async processing) |
| 400 Bad Request | Invalid input (validation errors) |
| 404 Not Found | Resource not found (job, recipe, user) |
| 409 Conflict | Resource conflict (job already running) |
| 503 Service Unavailable | External service unavailable (FatSecret, Tandoor) |

### Retry Strategy

**Transient Errors (Retry):**
- 503 Service Unavailable
- Network timeouts
- API rate limits

**Permanent Errors (No Retry):**
- 400 Bad Request (validation)
- 404 Not Found (missing resource)
- 409 Conflict (state conflict)

**Exponential Backoff:**
```
Attempt 1: 60s
Attempt 2: 120s
Attempt 3: 240s
Attempt 4: 480s
Attempt 5: 960s (max)
```

---

## State Transitions

### Job State Machine

```
pending → running → completed
              ↓
            failed → pending (retry)
```

**Allowed Transitions:**

| From | To | Trigger |
|------|-----|---------|
| pending | running | Scheduler/manual trigger |
| running | completed | Successful execution |
| running | failed | Execution error |
| failed | pending | Retry logic (if policy allows) |
| * | pending | Manual reset |

**Forbidden Transitions:**

- completed → running (immutable)
- completed → failed (immutable)
- pending → completed (must go through running)

---

## Appendix: Test Fixtures

### Test Fixture Locations

- Generation: `test/fixtures/generation/request_balanced.json`, `test/fixtures/generation/result_complete.json`
- Scheduler: `test/fixtures/scheduler_job.json`
- Email: `test/fixtures/email_commands.json`

### Example Test: Encoder/Decoder Roundtrip

```gleam
import gleam/json
import meal_planner/scheduler/types

pub fn scheduled_job_roundtrip_test() {
  let job = ScheduledJob(
    id: job_id("test-job"),
    job_type: WeeklyGeneration,
    frequency: Weekly(day: 5, hour: 6, minute: 0),
    status: Pending,
    priority: High,
    // ... full job fields
  )

  // Encode to JSON
  let json_string =
    job
    |> types.scheduled_job_to_json()
    |> json.to_string()

  // Decode from JSON
  let decoded =
    json_string
    |> json.decode(types.scheduled_job_decoder())

  // Assert roundtrip succeeds
  decoded
  |> should.equal(Ok(job))
}
```

### Example Test: Command Parser

```gleam
import meal_planner/email/parser
import meal_planner/types

pub fn parse_adjust_command_test() {
  let email = EmailRequest(
    from: "lewis@example.com",
    subject: "Adjustment",
    body: "@Claude adjust Friday dinner to tacos",
    received_at: "2025-12-19T14:30:00Z"
  )

  let result = parser.parse_email_command(email)

  result
  |> should.equal(Ok(AdjustMeal(
    day: Friday,
    meal_type: Dinner,
    recipe_id: recipe_id("tacos")
  )))
}
```

---

## Notes

- All timestamps are ISO 8601 format with timezone (Z for UTC)
- All macros are in grams except calories (kcal)
- Recipe IDs reference Tandoor API objects
- User IDs reference FatSecret profile IDs
- Job IDs are system-generated UUIDs
- Command parsing is case-insensitive for keywords (@claude, @Claude, @CLAUDE all work)
- Scheduler uses UTC timezone for all job scheduling
- Retry policies use exponential backoff with jitter to prevent thundering herd
