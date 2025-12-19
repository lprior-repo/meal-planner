# Gleam 7 Commandments

## Introduction

These commandments are not suggestions—they are **immutable laws** for writing Gleam code in the meal-planner project. Violating them will cause TCR reverts, code review failures, and broken builds.

Each commandment addresses a specific class of bugs or architectural failures that plague imperative, null-laden, dynamically-typed languages.

---

## Commandment 1: IMMUTABILITY ABSOLUTE

### The Law
**All data structures are immutable. No `var`. Use recursion or folding instead of loops.**

### Why This Exists
Mutation causes:
- Race conditions (even in single-threaded code via callbacks)
- Temporal coupling (order of operations matters unpredictably)
- Difficult reasoning (state changes non-locally)

Gleam eliminates mutation at the language level: `let` bindings cannot be reassigned.

### The Right Way

```gleam
// ✅ CORRECT: Immutable transformation
pub fn add_ingredient(recipe: Recipe, ingredient: Ingredient) -> Recipe {
  Recipe(..recipe, ingredients: [ingredient, ..recipe.ingredients])
}

// ✅ CORRECT: Fold for accumulation
pub fn sum_calories(meals: List(Meal)) -> Int {
  list.fold(meals, 0, fn(acc, meal) { acc + meal.calories })
}

// ✅ CORRECT: Recursion with accumulator (TCO-safe)
pub fn sum_calories_recursive(meals: List(Meal), acc: Int) -> Int {
  case meals {
    [] -> acc
    [first, ..rest] -> sum_calories_recursive(rest, acc + first.calories)
  }
}
```

### The Wrong Way

```gleam
// ❌ WRONG: This won't even compile (no var in Gleam)
var total = 0
for meal in meals {
  total = total + meal.calories
}

// ❌ WRONG: Trying to mutate in functional style (doesn't work)
let total = 0
list.each(meals, fn(meal) {
  total = total + meal.calories  // Compile error: total is immutable
})
```

### Shadowing (The Right Kind of "Mutation")

Gleam allows **shadowing**: rebinding a name to a new value. This is NOT mutation—it's sequential transformation.

```gleam
// ✅ CORRECT: Shadowing for transformation pipeline
pub fn process_recipe(raw_data: String) -> Result(Recipe, String) {
  let recipe = parse_json(raw_data)
  let recipe = validate_recipe(recipe)
  let recipe = enrich_with_nutrition(recipe)
  Ok(recipe)
}
```

Each `let recipe` is a NEW binding, not a mutation of the original.

### Anti-Patterns

**❌ Index-based iteration:**
```gleam
// Don't do this (O(n²) on linked lists anyway)
pub fn process_by_index(items: List(a)) -> List(a) {
  // No equivalent to items[i] in Gleam
}
```

**Fix:** Use `list.map`, `list.filter`, `list.fold`.

---

## Commandment 2: NO NULLS EVER

### The Law
**Use `Option(T)` or `Result(T, E)`. Handle every `Error` explicitly. `null` does not exist.**

### Why This Exists
Null pointer exceptions are the #1 cause of production crashes in Java/JavaScript/Python. Tony Hoare called `null` his "billion-dollar mistake."

Gleam makes null **impossible** by design.

### The Right Way

```gleam
import gleam/option.{type Option, Some, None}
import gleam/result

// ✅ CORRECT: Option for maybe-absent values
pub type User {
  User(name: String, email: String, bio: Option(String))
}

pub fn display_bio(user: User) -> String {
  case user.bio {
    Some(text) -> text
    None -> "No bio provided"
  }
}

// ✅ CORRECT: Result for operations that can fail
pub fn divide(a: Float, b: Float) -> Result(Float, String) {
  case b {
    0.0 -> Error("Division by zero")
    _ -> Ok(a /. b)
  }
}

// ✅ CORRECT: Chaining Results (Railway-Oriented Programming)
pub fn calculate_bmi(weight: String, height: String) -> Result(Float, String) {
  use weight_kg <- result.try(parse_float(weight))
  use height_m <- result.try(parse_float(height))

  case height_m {
    0.0 -> Error("Height cannot be zero")
    _ -> Ok(weight_kg /. (height_m *. height_m))
  }
}
```

### The Wrong Way

```gleam
// ❌ WRONG: Doesn't compile (null doesn't exist)
pub fn get_user_bio(user: User) -> String {
  if user.bio == null {
    "No bio"
  } else {
    user.bio
  }
}

// ❌ WRONG: Using panic as control flow
pub fn divide(a: Float, b: Float) -> Float {
  case b {
    0.0 -> panic as "Cannot divide by zero"
    _ -> a /. b
  }
}
```

### When to Use Option vs Result

| Use Case | Type | Example |
|----------|------|---------|
| Value may be absent but that's OK | `Option(T)` | User profile picture |
| Operation can fail and we need details | `Result(T, E)` | Parse JSON, HTTP request |
| Value should never be absent | `T` (no wrapper) | User email (required field) |

### Anti-Patterns

**❌ Using `panic` instead of `Result`:**
```gleam
// Wrong
pub fn get_config(key: String) -> String {
  case dict.get(config, key) {
    Ok(val) -> val
    Error(_) -> panic as "Config key missing"
  }
}

// Right
pub fn get_config(key: String) -> Result(String, String) {
  dict.get(config, key)
  |> result.map_error(fn(_) { "Config key '" <> key <> "' not found" })
}
```

---

## Commandment 3: PIPE EVERYTHING

### The Law
**Use `|>` for all data transformations. Readability flows top-down.**

### Why This Exists
Nested function calls are hard to read:
```gleam
// Hard to parse
let result = encode(transform(filter(parse(data))))
```

Pipelines read like prose:
```gleam
// Easy to parse
let result =
  data
  |> parse
  |> filter
  |> transform
  |> encode
```

### The Right Way

```gleam
// ✅ CORRECT: Pipeline for sequential transformations
pub fn process_recipes(raw_data: String) -> List(Recipe) {
  raw_data
  |> json.decode(using: recipe_decoder)
  |> result.unwrap([])
  |> list.filter(fn(r) { r.calories > 0 })
  |> list.sort(by: fn(a, b) { int.compare(a.calories, b.calories) })
  |> list.take(10)
}

// ✅ CORRECT: Using function capture for non-first arguments
pub fn add_ten(x: Int) -> Int {
  x
  |> int.add(10, _)  // Passes x as 2nd argument to int.add
}

// ✅ CORRECT: Multi-argument capture
pub fn format_price(price: Float) -> String {
  price
  |> float.to_string
  |> string.append("$", _)  // "$" is first arg, piped value is second
}
```

### The Wrong Way

```gleam
// ❌ WRONG: Nested function calls (hard to read)
pub fn process_recipes(raw_data: String) -> List(Recipe) {
  list.take(
    list.sort(
      list.filter(
        result.unwrap(json.decode(raw_data, using: recipe_decoder), []),
        fn(r) { r.calories > 0 }
      ),
      by: fn(a, b) { int.compare(a.calories, b.calories) }
    ),
    10
  )
}
```

### Capture Syntax

When piped value should go to **non-first** position, use `_`:

```gleam
// Pipe to 2nd argument
5 |> int.add(10, _)  // Same as: int.add(10, 5) → 15

// Pipe to 3rd argument
"hello" |> string.replace(in: _, each: "l", with: "L")
// Same as: string.replace(in: "hello", each: "l", with: "L")
```

### Anti-Patterns

**❌ Breaking pipelines prematurely:**
```gleam
// Wrong
pub fn process(data: String) -> Int {
  let parsed = json.decode(data, decoder)
  let filtered = list.filter(parsed, predicate)
  let mapped = list.map(filtered, transform)
  list.length(mapped)
}

// Right
pub fn process(data: String) -> Int {
  data
  |> json.decode(decoder)
  |> list.filter(predicate)
  |> list.map(transform)
  |> list.length
}
```

---

## Commandment 4: EXHAUSTIVE MATCHING

### The Law
**Every `case` expression must cover ALL possibilities. No catch-all `_` if cases are verifiable.**

### Why This Exists
Catch-all patterns hide bugs. When you add a new variant to a type, the compiler should FORCE you to handle it everywhere.

### The Right Way

```gleam
// ✅ CORRECT: Exhaustive match on custom type
pub type Status {
  Pending
  InProgress
  Completed
  Failed
}

pub fn status_message(status: Status) -> String {
  case status {
    Pending -> "Waiting to start"
    InProgress -> "Currently running"
    Completed -> "Finished successfully"
    Failed -> "Encountered an error"
  }
}

// ✅ CORRECT: Exhaustive with guards
pub fn categorize_calories(meal: Meal) -> String {
  case meal.calories {
    c if c < 300 -> "Light"
    c if c < 600 -> "Medium"
    c if c < 900 -> "Heavy"
    _ -> "Very Heavy"  // OK here: Int is unbounded
  }
}

// ✅ CORRECT: Nested exhaustive matching
pub fn handle_result(result: Result(Int, String)) -> String {
  case result {
    Ok(val) -> case val {
      0 -> "Zero"
      n if n > 0 -> "Positive"
      _ -> "Negative"
    }
    Error(msg) -> "Error: " <> msg
  }
}
```

### The Wrong Way

```gleam
// ❌ WRONG: Non-exhaustive match (won't compile)
pub fn status_message(status: Status) -> String {
  case status {
    Pending -> "Waiting"
    InProgress -> "Running"
    // Missing: Completed, Failed
  }
}
// Compiler error: "Unmatched cases: Completed, Failed"

// ⚠️ DANGEROUS: Catch-all hides future bugs
pub type Status {
  Pending
  InProgress
  Completed
  Failed
  Cancelled  // New variant added later
}

pub fn status_message(status: Status) -> String {
  case status {
    Pending -> "Waiting"
    InProgress -> "Running"
    _ -> "Done"  // Hides Cancelled case!
  }
}
```

### When Catch-All Is OK

Use `_` only for:
1. **Unbounded types** (Int, String, Float)
2. **External data** you don't control
3. **Explicit "everything else" semantics**

```gleam
// ✅ OK: Unbounded type (Int)
case age {
  0 -> "Newborn"
  1 -> "One year old"
  _ -> "Older"
}

// ✅ OK: Handling unknown external data
case http_status {
  200 -> "OK"
  404 -> "Not Found"
  500 -> "Server Error"
  _ -> "Other status"
}
```

### Anti-Patterns

**❌ Using `_` to avoid typing:**
```gleam
// Wrong
pub type Animal {
  Dog(name: String)
  Cat(name: String)
  Bird(name: String)
  Fish(name: String)
}

pub fn speak(animal: Animal) -> String {
  case animal {
    Dog(name) -> name <> " barks"
    _ -> "Makes a sound"  // Lazy!
  }
}

// Right
pub fn speak(animal: Animal) -> String {
  case animal {
    Dog(name) -> name <> " barks"
    Cat(name) -> name <> " meows"
    Bird(name) -> name <> " chirps"
    Fish(name) -> name <> " bubbles"
  }
}
```

---

## Commandment 5: LABELED ARGUMENTS

### The Law
**Functions with >2 arguments MUST use labels for clarity.**

### Why This Exists
Positional arguments become unreadable and error-prone with many parameters.

```gleam
// What does this mean?
create_user("Alice", "alice@example.com", 25, True, False)
```

Labels make intent explicit:

```gleam
create_user(
  name: "Alice",
  email: "alice@example.com",
  age: 25,
  verified: True,
  admin: False
)
```

### The Right Way

```gleam
// ✅ CORRECT: Labeled arguments (>2 params)
pub fn create_recipe(
  name name: String,
  servings servings: Int,
  prep_time prep_time: Int,
  cook_time cook_time: Int,
) -> Recipe {
  Recipe(name:, servings:, prep_time:, cook_time:)
}

// Usage is self-documenting
let recipe = create_recipe(
  name: "Pasta Carbonara",
  servings: 4,
  prep_time: 10,
  cook_time: 20,
)

// ✅ CORRECT: Mix of labeled and unlabeled (up to 2 unlabeled)
pub fn calculate_macros(recipe: Recipe, servings servings: Int) -> Macros {
  // recipe is positional (clear from context)
  // servings is labeled (could be confused with recipe.servings)
}
```

### The Wrong Way

```gleam
// ❌ WRONG: Too many positional arguments
pub fn create_recipe(
  name: String,
  servings: Int,
  prep_time: Int,
  cook_time: Int,
  difficulty: String,
) -> Recipe {
  // What order do these go in? Hard to remember!
}

// Usage is cryptic
let recipe = create_recipe("Pasta", 4, 10, 20, "Easy")
//                         What is 4? What is 10? What is 20?
```

### Label Syntax

```gleam
// Define with label
pub fn greet(name name: String) -> String {
  "Hello, " <> name
}

// Call with label
greet(name: "Alice")

// Shorthand when variable name matches label
let name = "Alice"
greet(name:)  // Same as greet(name: name)
```

### Anti-Patterns

**❌ Skipping labels to save typing:**
```gleam
// Wrong
pub fn update_user(id, name, email, age, verified) { ... }
update_user(42, "Alice", "alice@example.com", 25, True)

// Right
pub fn update_user(
  id id: Int,
  name name: String,
  email email: String,
  age age: Int,
  verified verified: Bool,
) { ... }
update_user(id: 42, name: "Alice", email: "alice@example.com", age: 25, verified: True)
```

---

## Commandment 6: TYPE SAFETY FIRST

### The Law
**Avoid `dynamic`. Define custom types for domain concepts.**

### Why This Exists
`dynamic` is Gleam's escape hatch for untyped data (e.g., JSON from external APIs). Overusing it defeats the type system.

### The Right Way

```gleam
// ✅ CORRECT: Custom type for domain concept
pub opaque type Email {
  Email(String)
}

pub fn new_email(raw: String) -> Result(Email, String) {
  case string.contains(raw, "@") {
    True -> Ok(Email(raw))
    False -> Error("Invalid email: missing @")
  }
}

// ✅ CORRECT: Parse dynamic data immediately
import gleam/dynamic.{type Dynamic}

pub fn decode_user(data: Dynamic) -> Result(User, List(dynamic.DecodeError)) {
  dynamic.decode3(
    User,
    dynamic.field("name", dynamic.string),
    dynamic.field("email", dynamic.string),
    dynamic.field("age", dynamic.int),
  )(data)
}

// ✅ CORRECT: Sum type instead of string tags
pub type PaymentMethod {
  CreditCard(number: String, expiry: String)
  BankTransfer(account: String, routing: String)
  Cash
}
```

### The Wrong Way

```gleam
// ❌ WRONG: Using dynamic internally
pub fn process_user(user: Dynamic) -> String {
  // Loses all type safety!
}

// ❌ WRONG: Primitive obsession (String for everything)
pub type User {
  User(
    email: String,  // Could be any string!
    age: String,    // Should be Int!
    role: String,   // Should be custom type!
  )
}

// ❌ WRONG: Boolean flags instead of sum types
pub type PaymentMethod {
  PaymentMethod(
    is_credit_card: Bool,
    is_bank_transfer: Bool,
    is_cash: Bool,
    // What if all are False? Or multiple True?
  )
}
```

### Opaque Types for Validation

Use `pub opaque type` to enforce invariants at construction:

```gleam
// ✅ CORRECT: Age cannot be negative
pub opaque type Age {
  Age(Int)
}

pub fn new_age(years: Int) -> Result(Age, String) {
  case years >= 0 {
    True -> Ok(Age(years))
    False -> Error("Age cannot be negative")
  }
}

pub fn to_int(age: Age) -> Int {
  let Age(years) = age
  years
}
```

Now it's **impossible** to create an invalid `Age` outside this module.

### Anti-Patterns

**❌ Stringly-typed domains:**
```gleam
// Wrong
pub type Recipe {
  Recipe(difficulty: String)  // "easy" | "medium" | "hard" ?
}

// Right
pub type Difficulty {
  Easy
  Medium
  Hard
}

pub type Recipe {
  Recipe(difficulty: Difficulty)
}
```

---

## Commandment 7: FORMAT OR DEATH

### The Law
**Code is invalid if `gleam format --check` fails.**

### Why This Exists
Formatting debates waste time. `gleam format` is:
- **Deterministic** (same input → same output)
- **Opinionated** (no configuration)
- **Enforced** (via CI/pre-commit hooks)

### The Right Way

```bash
# Before every commit
gleam format --check
# Exit code 0 → OK
# Exit code 1 → Run `gleam format`, then check again
```

If formatter struggles or produces ugly output, your code is **too complex**. Refactor.

### The Wrong Way

```gleam
// ❌ WRONG: Manually formatted (will be changed by formatter)
pub fn calculate(x:Int,y:Int)->Int{x+y}

// ✅ CORRECT: Auto-formatted
pub fn calculate(x: Int, y: Int) -> Int {
  x + y
}
```

### Formatter as Code Smell Detector

**Scenario:** Formatter produces deeply nested code.

```gleam
// Formatter output (ugly but correct)
pub fn process(data: String) -> Result(Int, String) {
  case parse(data) {
    Ok(val) ->
      case validate(val) {
        Ok(validated) ->
          case transform(validated) {
            Ok(transformed) ->
              case encode(transformed) {
                Ok(encoded) -> Ok(encoded)
                Error(e) -> Error(e)
              }
            Error(e) -> Error(e)
          }
        Error(e) -> Error(e)
      }
    Error(e) -> Error(e)
  }
}
```

**Fix:** Use `result.try` or `use` expressions:

```gleam
// Refactored (formatter produces clean output)
pub fn process(data: String) -> Result(Int, String) {
  use val <- result.try(parse(data))
  use validated <- result.try(validate(val))
  use transformed <- result.try(transform(validated))
  encode(transformed)
}
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

gleam format --check
if [ $? -ne 0 ]; then
  echo "❌ Code is not formatted. Run 'gleam format' and try again."
  exit 1
fi
```

### Anti-Patterns

**❌ Fighting the formatter:**
```gleam
// Don't manually format to "look better"
// The formatter will undo it anyway
```

**❌ Skipping format checks:**
```bash
# Wrong
git commit -m "WIP: will format later"

# Right
gleam format && git commit -m "GREEN: feature"
```

---

## Compliance Checklist

Before every commit, verify:

- [ ] No `var` (Commandment 1)
- [ ] No `null`, all `Option`/`Result` handled (Commandment 2)
- [ ] Pipelines used for transformations (Commandment 3)
- [ ] All `case` branches covered (Commandment 4)
- [ ] Functions >2 args use labels (Commandment 5)
- [ ] No unnecessary `dynamic` (Commandment 6)
- [ ] `gleam format --check` passes (Commandment 7)

Automated check:
```bash
# Run this before every commit
make gleam-check
```

```makefile
# Makefile
.PHONY: gleam-check
gleam-check:
	@echo "Checking Gleam commandments..."
	@gleam format --check || (echo "❌ Commandment 7: Format failed" && exit 1)
	@gleam build || (echo "❌ Build failed" && exit 1)
	@gleam test || (echo "❌ Tests failed" && exit 1)
	@echo "✅ All commandments obeyed"
```

## Related Documentation

- [fractal-quality-loop.md](./fractal-quality-loop.md) - Quality enforcement framework
- [tcr-cycle.md](./tcr-cycle.md) - How commandments trigger reverts
- [multi-agent-workflow.md](./multi-agent-workflow.md) - Agent enforcement roles
- [quality-gates.md](./quality-gates.md) - Automated compliance checking

## References

- CLAUDE.md section: `GLEAM_7_COMMANDMENTS`
- Gleam Language Tour: https://tour.gleam.run/
- Gleam Standard Library: https://hexdocs.pm/gleam_stdlib/
