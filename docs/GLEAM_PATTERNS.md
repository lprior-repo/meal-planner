# Gleam Patterns - Reusable Idioms in Meal Planner

## Overview

This document captures Gleam programming patterns used throughout the meal-planner codebase. These patterns demonstrate idiomatic Gleam code and serve as examples for new contributors.

## Pattern 1: Railway-Oriented Programming (Result Chaining)

### Purpose
Chain multiple operations that can fail, short-circuiting on first error.

### Problem
Nested error handling becomes unreadable:
```gleam
// ❌ BAD: Nested case statements
pub fn execute_job(job: ScheduledJob) -> Result(JobExecution, Error) {
  case get_db_connection() {
    Ok(db) ->
      case mark_job_running(job.id) {
        Ok(execution) ->
          case execute_handler(job) {
            Ok(output) -> Ok(execution)
            Error(e) -> Error(e)
          }
        Error(e) -> Error(e)
      }
    Error(e) -> Error(e)
  }
}
```

### Solution
Use `result.try` (via `use` expression) for flat chaining:
```gleam
// ✅ GOOD: Railway-oriented pipeline
pub fn execute_scheduled_job(
  job: ScheduledJob
) -> Result(JobExecution, SchedulerError) {
  use db <- result.try(get_db_connection())
  use execution <- result.try(job_manager.mark_job_running(job.id))
  use output <- result.try(execute_handler(job))
  Ok(execution)
}
```

### Benefits
- **Flat Control Flow**: No nesting, reads top-to-bottom
- **Early Exit**: First error short-circuits (no wasted computation)
- **Type Safety**: Compiler enforces error handling

### Real-World Example (from `advisor/daily_recommendations.gleam`)
```gleam
pub fn generate_daily_advisor_email(
  conn: pog.Connection,
  date_int: Int,
) -> Result(AdvisorEmail, String) {
  // Fetch today's diary entries
  use entries <- result.try(
    diary_service.get_day_entries(conn, date_int)
    |> result.map_error(fn(e) {
      "Failed to fetch diary entries: " <> diary_service.error_to_message(e)
    }),
  )

  // Fetch user's profile goals
  use profile <- result.try(
    profile_service.get_profile(conn)
    |> result.map_error(fn(e) {
      "Failed to fetch profile: " <> profile_service.error_to_message(e)
    }),
  )

  // Calculate actual macros from entries
  let actual_macros = calculate_total_macros(entries)

  // Extract target macros from profile
  let target_macros = extract_target_macros(profile)

  // Generate insights
  let insights = generate_insight_messages(actual_macros, target_macros)

  Ok(AdvisorEmail(
    date: diary_types.int_to_date(date_int),
    actual_macros: actual_macros,
    target_macros: target_macros,
    insights: insights,
    seven_day_trend: calculate_seven_day_trend(conn, date_int),
  ))
}
```

---

## Pattern 2: Opaque Types with Validation

### Purpose
Prevent invalid data from entering the system by validating at construction time.

### Problem
No enforcement of invariants:
```gleam
// ❌ BAD: No validation
pub type Email = String

pub fn send_email(email: Email) {
  // What if email is "invalid" or ""?
}
```

### Solution
Use opaque types with smart constructors:
```gleam
// ✅ GOOD: Validated opaque type
pub opaque type Email {
  Email(value: String)
}

pub fn new(email: String) -> Result(Email, ValidationError) {
  case string.contains(email, "@") && string.contains(email, ".") {
    True -> Ok(Email(email))
    False -> Error(InvalidEmail(email))
  }
}

pub fn to_string(email: Email) -> String {
  email.value
}
```

### Benefits
- **Invariant Enforcement**: Invalid data can't be constructed
- **Type Safety**: `Email` is distinct from `String` (compiler enforces)
- **Encapsulation**: Internal representation hidden from clients

### Real-World Example (from `id.gleam`)
```gleam
pub opaque type RecipeId {
  RecipeId(value: String)
}

pub fn recipe_id(value: String) -> RecipeId {
  RecipeId(value)
}

pub fn recipe_id_to_string(id: RecipeId) -> String {
  id.value
}

pub fn recipe_id_to_json(id: RecipeId) -> json.Json {
  json.string(id.value)
}
```

### Usage
```gleam
let recipe_id = id.recipe_id("recipe-123")
// recipe_id is guaranteed to be a valid RecipeId
// Cannot accidentally pass String where RecipeId expected
```

---

## Pattern 3: Labeled Arguments for Clarity

### Purpose
Make function calls self-documenting, especially with multiple arguments of the same type.

### Problem
Ambiguous function calls:
```gleam
// ❌ BAD: What do these parameters mean?
generate_plan(recipes, macros, constraints, "2025-01-01")
```

### Solution
Use labeled arguments:
```gleam
// ✅ GOOD: Clear intent
pub fn generate_meal_plan(
  available_breakfasts available_breakfasts: List(Recipe),
  available_lunches available_lunches: List(Recipe),
  available_dinners available_dinners: List(Recipe),
  target_macros target_macros: Macros,
  constraints constraints: Constraints,
  week_of week_of: String,
) -> Result(WeeklyMealPlan, GenerationError)
```

### Benefits
- **Self-Documenting**: Call site shows parameter names
- **Positional Flexibility**: Arguments can be reordered
- **Refactoring Safety**: Adding parameters doesn't break call sites

### Real-World Example (from `generator/weekly.gleam`)
```gleam
// Call site is clear
let plan = generate_meal_plan(
  available_breakfasts: breakfast_recipes,
  available_lunches: lunch_recipes,
  available_dinners: dinner_recipes,
  target_macros: Macros(protein: 150.0, carbs: 200.0, fat: 65.0),
  constraints: Constraints(locked_meals: [], travel_dates: []),
  week_of: "2025-01-06",
)
```

### When to Use
- **3+ Parameters**: Always use labels
- **Same Type**: Use labels (e.g., multiple `String` args)
- **Optional Context**: Use labels (e.g., `Option(T)` params)

---

## Pattern 4: Pipe Operator for Data Transformations

### Purpose
Transform data through multiple steps in a readable, top-to-bottom flow.

### Problem
Nested function calls are hard to read:
```gleam
// ❌ BAD: Read inside-out
let result =
  encode_response(
    build_pagination_params(
      filter_by_status(recipes, Active)
    )
  )
```

### Solution
Use pipe operator (`|>`):
```gleam
// ✅ GOOD: Read top-to-bottom
let result =
  recipes
  |> filter_by_status(Active)
  |> build_pagination_params
  |> encode_response
```

### Benefits
- **Readability**: Top-to-bottom data flow (natural reading order)
- **Composability**: Easy to add/remove steps
- **Debugging**: Comment out steps to isolate issues

### Real-World Example (from `generator/weekly.gleam`)
```gleam
pub fn total_weekly_macros(plan: WeeklyMealPlan) -> Macros {
  plan.days
  |> list.map(sum_day_macros)
  |> list.fold(macros_zero(), macros_add)
}

pub fn filter_by_rotation(
  recipes: List(Recipe),
  history: List(RotationEntry),
  rotation_days: Int,
) -> List(Recipe) {
  recipes
  |> list.filter(fn(recipe) {
    let recent_use =
      history
      |> list.find(fn(entry) {
        entry.recipe_name == recipe.name && entry.days_ago < rotation_days
      })
    case recent_use {
      Ok(_) -> False
      Error(_) -> True
    }
  })
}
```

### Advanced: Capture Operator
When piped value is not the first argument:
```gleam
// ❌ BAD: Can't pipe directly
let result = int.add(5, value)

// ✅ GOOD: Use capture operator (_)
let result =
  value
  |> int.add(5, _)
```

---

## Pattern 5: Exhaustive Pattern Matching

### Purpose
Ensure all cases are handled at compile time, preventing runtime errors.

### Problem
Non-exhaustive matching:
```gleam
// ❌ BAD: What if status is Failed?
case job.status {
  Pending -> "pending"
  Running -> "running"
  Completed -> "completed"
  // Missing Failed case!
}
```

### Solution
Match all cases explicitly:
```gleam
// ✅ GOOD: All cases covered
pub fn job_status_to_string(js: JobStatus) -> String {
  case js {
    Pending -> "pending"
    Running -> "running"
    Completed -> "completed"
    Failed -> "failed"
  }
}
```

### Benefits
- **Compile-Time Safety**: Compiler enforces completeness
- **Refactoring Safety**: Adding new variants requires updating all matches
- **No Runtime Errors**: Can't forget a case

### Real-World Example (from `scheduler/types.gleam`)
```gleam
pub fn job_type_to_string(jt: JobType) -> String {
  case jt {
    WeeklyGeneration -> "weekly_generation"
    AutoSync -> "auto_sync"
    DailyAdvisor -> "daily_advisor"
    WeeklyTrends -> "weekly_trends"
  }
}

pub fn calculate_backoff(job: ScheduledJob) -> Int {
  let base = job.retry_policy.backoff_seconds
  base * power_of_2(job.error_count)
}

fn power_of_2(n: Int) -> Int {
  case n {
    0 -> 1
    1 -> 2
    2 -> 4
    3 -> 8
    4 -> 16
    _ -> 32  // Catch-all for 5+ (capped)
  }
}
```

### When to Avoid Catch-All (`_`)
Only use `_` when:
1. The pattern is infinite (e.g., `Int`, `String`)
2. You're explicitly capping values (e.g., max retry count)

Never use `_` for enums (defeats exhaustiveness checking).

---

## Pattern 6: Immutable Data Structures with Folding

### Purpose
Transform collections without mutating state, using functional patterns.

### Problem
Imperative accumulation:
```gleam
// ❌ BAD: Gleam has no mutable variables
var total = 0.0
for entry in entries {
  total = total + entry.calories  // Error: no 'var' in Gleam
}
```

### Solution
Use `list.fold` with immutable accumulator:
```gleam
// ✅ GOOD: Immutable fold
fn calculate_total_macros(entries: List(FoodEntry)) -> Macros {
  list.fold(
    entries,
    Macros(calories: 0.0, protein: 0.0, fat: 0.0, carbs: 0.0),
    fn(acc, entry) {
      Macros(
        calories: acc.calories +. entry.calories,
        protein: acc.protein +. entry.protein,
        fat: acc.fat +. entry.fat,
        carbs: acc.carbs +. entry.carbohydrate,
      )
    },
  )
}
```

### Benefits
- **No Mutation**: Values never change (easier to reason about)
- **Parallelizable**: Pure functions can run in parallel
- **Testable**: No hidden state, deterministic output

### Real-World Example (from `advisor/daily_recommendations.gleam`)
```gleam
fn calculate_total_macros(entries: List(FoodEntry)) -> Macros {
  list.fold(
    entries,
    Macros(calories: 0.0, protein: 0.0, fat: 0.0, carbs: 0.0),
    fn(acc, entry) {
      Macros(
        calories: acc.calories +. entry.calories,
        protein: acc.protein +. entry.protein,
        fat: acc.fat +. entry.fat,
        carbs: acc.carbs +. entry.carbohydrate,
      )
    },
  )
}
```

### Common Fold Patterns
```gleam
// Sum
let total = list.fold(numbers, 0, fn(acc, n) { acc + n })

// Concatenate
let combined = list.fold(strings, "", fn(acc, s) { acc <> s })

// Filter + Transform
let filtered = list.fold(items, [], fn(acc, item) {
  case item.status {
    Active -> [transform(item), ..acc]
    _ -> acc
  }
})
```

---

## Pattern 7: Option for Nullable Values

### Purpose
Explicitly represent optional values, eliminating null pointer errors.

### Problem
Null values are implicit:
```gleam
// ❌ BAD: What if scheduled_for is NULL?
let time = job.scheduled_for  // Crash if NULL
```

### Solution
Use `Option(T)`:
```gleam
// ✅ GOOD: Explicit optionality
pub type ScheduledJob {
  ScheduledJob(
    scheduled_for: Option(String),
    // ...
  )
}

// Pattern match to handle both cases
case job.scheduled_for {
  Some(time) -> "Scheduled for " <> time
  None -> "Not scheduled"
}
```

### Benefits
- **No Null Errors**: Compiler enforces handling both cases
- **Type Safety**: Can't forget to check for None
- **Explicit Intent**: Clear when value may be absent

### Real-World Example (from `scheduler/types.gleam`)
```gleam
pub type ScheduledJob {
  ScheduledJob(
    id: JobId,
    user_id: Option(UserId),          // None for system-wide jobs
    parameters: Option(Json),         // None if no params
    scheduled_for: Option(String),    // None for immediate execution
    started_at: Option(String),       // None if not yet started
    completed_at: Option(String),     // None if not yet completed
    last_error: Option(String),       // None if no errors
    created_by: Option(UserId),       // None for system jobs
    // ...
  )
}

// Usage: Safely unwrap with default
let time = option.unwrap(job.scheduled_for, "now")

// Usage: Map over Option
let formatted = option.map(job.scheduled_for, fn(time) {
  "Scheduled for " <> time
})
```

### Option Combinators
```gleam
// Map: Transform inner value (if present)
option.map(Some(5), fn(x) { x * 2 })  // Some(10)
option.map(None, fn(x) { x * 2 })     // None

// Then: Chain optional operations
option.then(Some(5), fn(x) { Some(x + 1) })  // Some(6)
option.then(None, fn(x) { Some(x + 1) })     // None

// Unwrap: Extract value or use default
option.unwrap(Some(5), 0)  // 5
option.unwrap(None, 0)     // 0
```

---

## Pattern 8: Custom Types for Domain Modeling

### Purpose
Model domain concepts with type-safe enums, making impossible states unrepresentable.

### Problem
Boolean blindness:
```gleam
// ❌ BAD: What does True mean?
pub type Job {
  Job(
    id: String,
    completed: Bool,
    failed: Bool,
    // What if both are True? Or both False?
  )
}
```

### Solution
Use custom types (sum types):
```gleam
// ✅ GOOD: Impossible states eliminated
pub type JobStatus {
  Pending
  Running
  Completed
  Failed
}

pub type ScheduledJob {
  ScheduledJob(
    id: JobId,
    status: JobStatus,
    // Only one status, always valid
    // ...
  )
}
```

### Benefits
- **Impossible States Eliminated**: Can't have conflicting flags
- **Self-Documenting**: Status values are clear (not True/False)
- **Exhaustive Matching**: Compiler ensures all cases handled

### Real-World Example (from `scheduler/types.gleam`)
```gleam
pub type JobStatus {
  Pending
  Running
  Completed
  Failed
}

pub type JobType {
  WeeklyGeneration
  AutoSync
  DailyAdvisor
  WeeklyTrends
}

pub type JobFrequency {
  Weekly(day: Int, hour: Int, minute: Int)
  Daily(hour: Int, minute: Int)
  EveryNHours(hours: Int)
  Once
}
```

### Anti-Pattern: Primitive Obsession
```gleam
// ❌ BAD: Using primitives for domain concepts
pub fn process_job(
  job_id: String,
  job_type: String,
  status: String,
) -> Result(String, String)

// ✅ GOOD: Use domain types
pub fn process_job(
  job_id: JobId,
  job_type: JobType,
  status: JobStatus,
) -> Result(JobExecution, SchedulerError)
```

---

## Pattern 9: Builder Pattern with Labeled Arguments

### Purpose
Construct complex types with many optional fields in a readable way.

### Problem
Too many arguments:
```gleam
// ❌ BAD: Hard to remember order
create_job(
  "weekly_generation",
  "weekly",
  "medium",
  Some(user_id),
  Some(params),
  Some(retry_policy),
  Some("2025-01-06T06:00:00Z"),
  True,
)
```

### Solution
Use labeled arguments with record syntax:
```gleam
// ✅ GOOD: Clear and flexible
pub type CreateJobRequest {
  CreateJobRequest(
    job_type: JobType,
    frequency: JobFrequency,
    priority: JobPriority,
    user_id: Option(UserId),
    parameters: Option(Json),
    retry_policy: Option(RetryPolicy),
    scheduled_for: Option(String),
    enabled: Bool,
  )
}

// Usage
let request = CreateJobRequest(
  job_type: WeeklyGeneration,
  frequency: Weekly(day: 5, hour: 6, minute: 0),
  priority: High,
  user_id: Some(user_id),
  parameters: None,
  retry_policy: None,  // Use default
  scheduled_for: Some("2025-01-06T06:00:00Z"),
  enabled: True,
)
```

### Benefits
- **Self-Documenting**: Field names clear at call site
- **Flexible**: Can omit optional fields (use None)
- **Refactoring Safety**: Adding fields doesn't break callers

### Real-World Example (from `scheduler/types.gleam`)
```gleam
pub type CreateJobRequest {
  CreateJobRequest(
    job_type: JobType,
    frequency: JobFrequency,
    priority: JobPriority,
    user_id: Option(UserId),
    parameters: Option(Json),
    retry_policy: Option(RetryPolicy),
    scheduled_for: Option(String),
    enabled: Bool,
  )
}

pub type UpdateJobRequest {
  UpdateJobRequest(
    frequency: Option(JobFrequency),
    priority: Option(JobPriority),
    parameters: Option(Json),
    retry_policy: Option(RetryPolicy),
    scheduled_for: Option(String),
    enabled: Option(Bool),
  )
}
```

---

## Pattern 10: Recursive Functions with Tail-Call Optimization

### Purpose
Process lists efficiently without stack overflow.

### Problem
Non-tail-recursive functions consume stack:
```gleam
// ❌ BAD: Not tail-recursive (stack grows)
fn sum(list: List(Int)) -> Int {
  case list {
    [] -> 0
    [x, ..xs] -> x + sum(xs)  // Stack frame kept
  }
}
```

### Solution
Use accumulator for tail-call optimization:
```gleam
// ✅ GOOD: Tail-recursive (constant stack)
pub fn sum(list: List(Int)) -> Int {
  sum_helper(list, 0)
}

fn sum_helper(list: List(Int), acc: Int) -> Int {
  case list {
    [] -> acc
    [x, ..xs] -> sum_helper(xs, acc + x)  // Tail call
  }
}
```

### Benefits
- **Constant Stack**: No stack overflow on large lists
- **Performance**: Compiler optimizes to loop
- **Functional Style**: No mutation, pure recursion

### Real-World Example (from `email/parser.gleam`)
```gleam
fn find_word_index(words: List(String), target: String) -> Option(Int) {
  let target_lower = string.lowercase(target)
  find_word_index_helper(words, target_lower, 0)
}

fn find_word_index_helper(
  words: List(String),
  target: String,
  idx: Int,
) -> Option(Int) {
  case words {
    [] -> None
    [word, ..rest] -> {
      case string.lowercase(word) == target {
        True -> Some(idx)
        False -> find_word_index_helper(rest, target, idx + 1)  // Tail call
      }
    }
  }
}
```

### When to Use Standard Library
Prefer `list.fold`, `list.map`, `list.filter` over manual recursion:
```gleam
// ❌ VERBOSE: Manual recursion
fn filter_active(items: List(Item)) -> List(Item) {
  filter_active_helper(items, [])
}

fn filter_active_helper(items: List(Item), acc: List(Item)) -> List(Item) {
  case items {
    [] -> acc
    [item, ..rest] ->
      case item.status {
        Active -> filter_active_helper(rest, [item, ..acc])
        _ -> filter_active_helper(rest, acc)
      }
  }
}

// ✅ CONCISE: Use standard library
fn filter_active(items: List(Item)) -> List(Item) {
  list.filter(items, fn(item) { item.status == Active })
}
```

---

## Pattern Summary

| Pattern                     | Use When                                      | Benefit                          |
|-----------------------------|-----------------------------------------------|----------------------------------|
| Railway-Oriented Programming | Chaining fallible operations                  | Flat control flow, early exit    |
| Opaque Types                | Enforcing invariants                          | Type safety, encapsulation       |
| Labeled Arguments           | 3+ params or same-type params                 | Self-documenting, flexible       |
| Pipe Operator               | Multi-step data transformations               | Readable, top-to-bottom flow     |
| Exhaustive Matching         | Handling all enum cases                       | Compile-time safety              |
| Immutable Folding           | Accumulating values from lists                | No mutation, parallelizable      |
| Option for Nullability      | Optional values                               | No null errors, explicit intent  |
| Custom Types                | Modeling domain concepts                      | Impossible states eliminated     |
| Builder Pattern             | Constructing complex types                    | Clear, flexible, refactor-safe   |
| Tail-Call Recursion         | Processing lists recursively                  | Constant stack, no overflow      |

---

## Anti-Patterns to Avoid

### 1. Boolean Blindness
```gleam
// ❌ BAD
pub type Job {
  Job(is_completed: Bool, is_failed: Bool)
}

// ✅ GOOD
pub type JobStatus {
  Pending | Running | Completed | Failed
}
```

### 2. Stringly-Typed
```gleam
// ❌ BAD
pub fn process_job(job_type: String) -> Result(String, String)

// ✅ GOOD
pub fn process_job(job_type: JobType) -> Result(JobExecution, SchedulerError)
```

### 3. Index Iteration
```gleam
// ❌ BAD: Lists are linked lists (O(n) access)
for i in range(0, list.length(items)) {
  let item = list.at(items, i)  // O(n) per access!
}

// ✅ GOOD: Use list.map, list.fold, or pattern matching
list.map(items, fn(item) { transform(item) })
```

### 4. Ignoring Result
```gleam
// ❌ BAD: Error is ignored
let _ = create_job(request)

// ✅ GOOD: Handle error explicitly
case create_job(request) {
  Ok(_) -> "Job created"
  Error(e) -> "Failed: " <> error_to_string(e)
}
```

### 5. Over-Using Catch-All (`_`)
```gleam
// ❌ BAD: Defeats exhaustiveness checking
case job_type {
  WeeklyGeneration -> handle_weekly()
  _ -> handle_other()  // What if new type added?
}

// ✅ GOOD: Explicit cases
case job_type {
  WeeklyGeneration -> handle_weekly()
  AutoSync -> handle_auto_sync()
  DailyAdvisor -> handle_daily_advisor()
  WeeklyTrends -> handle_weekly_trends()
}
```

---

## Code Style Guidelines

### Formatting
- Always run `gleam format` (enforced by CI)
- Max line length: 80 characters (soft limit, 100 hard)
- Indent: 2 spaces (no tabs)

### Naming
- **Types**: PascalCase (`WeeklyMealPlan`, `JobExecution`)
- **Functions**: snake_case (`generate_meal_plan`, `execute_job`)
- **Constants**: snake_case (`default_retry_policy`, `max_attempts`)
- **Modules**: snake_case (`meal_planner/scheduler/executor.gleam`)

### Documentation
- **Module docs**: `////` at top of file
- **Function docs**: `///` before public functions
- **Inline comments**: `//` for implementation notes

### Example
```gleam
//// Weekly meal plan generation engine
////
//// This module generates complete 7-day meal plans with macro balancing.

/// Generate a weekly meal plan from available recipes
///
/// ## Parameters
/// - available_breakfasts: Pool of breakfast recipes
/// - available_lunches: Pool of lunch recipes
/// - available_dinners: Pool of dinner recipes
/// - target_macros: Daily macro targets
/// - constraints: Locked meals and travel dates
/// - week_of: Week start date (YYYY-MM-DD)
///
/// ## Returns
/// - Ok(WeeklyMealPlan) with 7 days of meals
/// - Error(NotEnoughRecipes) if recipe pools too small
pub fn generate_meal_plan(
  available_breakfasts available_breakfasts: List(Recipe),
  available_lunches available_lunches: List(Recipe),
  available_dinners available_dinners: List(Recipe),
  target_macros target_macros: Macros,
  constraints constraints: Constraints,
  week_of week_of: String,
) -> Result(WeeklyMealPlan, GenerationError) {
  // Implementation...
}
```

---

## Testing Patterns

### 1. Property-Based Testing (Invariants)
```gleam
// Test invariant: Weekly plan has exactly 7 days
test generate_plan_has_7_days() {
  let recipes = [recipe_a, recipe_b, recipe_c]
  let assert Ok(plan) = generate_weekly_plan("2025-01-06", recipes, target, constraints)
  assert.equal(days_count(plan), 7)
}
```

### 2. Table-Driven Tests
```gleam
test macro_comparison_status() {
  let cases = [
    #(100.0, 100.0, OnTarget),  // Exact match
    #(95.0, 100.0, OnTarget),   // Within 10%
    #(85.0, 100.0, Under),      // Below 90%
    #(115.0, 100.0, Over),      // Above 110%
  ]

  list.each(cases, fn(case) {
    let #(actual, target, expected) = case
    assert.equal(compare_macro(actual, target), expected)
  })
}
```

### 3. Golden Tests (Snapshot Testing)
```gleam
test generate_plan_snapshot() {
  let recipes = load_test_fixtures()
  let assert Ok(plan) = generate_meal_plan(...)

  // Compare JSON output against golden file
  let actual = scheduled_job_to_json(plan) |> json.to_string
  let expected = read_golden_file("plan_snapshot.json")
  assert.equal(actual, expected)
}
```

---

## Conclusion

These patterns represent idiomatic Gleam code and are used consistently throughout the meal-planner codebase. When contributing, follow these patterns to maintain consistency and leverage Gleam's type system for maximum safety and clarity.

For more Gleam patterns, see:
- [Gleam Language Tour](https://tour.gleam.run/)
- [Gleam Standard Library Docs](https://hexdocs.pm/gleam_stdlib/)
- [Gleam Style Guide](https://gleam.run/writing-gleam/)
