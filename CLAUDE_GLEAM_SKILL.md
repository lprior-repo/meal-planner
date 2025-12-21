# CLAUDE_GLEAM_SKILL.md - Gleam*7_Commandments & Patterns

## GLEAM*7_COMMANDMENTS

### RULE_1: IMMUTABILITY_ABSOLUTE
**No `var`. All data structures are immutable. Use recursion/folding over loops.**

```gleam
// ✅ DO: Immutable shadowing
let user = " john "
let user = string.trim(user)
let user = string.uppercase(user)

// ❌ DON'T: Mutable variables
var name = "john"
name = string.uppercase(name)
```

### RULE_2: NO_NULLS_EVER
**Use `Option(T)` or `Result(T, E)`. Handle every `Error` explicitly.**

```gleam
// ✅ DO: Option for optional values
pub type Profile {
  Profile(bio: Option(String))
}

// ✅ DO: Result for operations that might fail
pub fn parse_age(s: String) -> Result(Int, Nil) {
  int.parse(s)
}

// ❌ DON'T: Null values
profile.bio == null  // No null in Gleam
```

### RULE_3: PIPE_EVERYTHING
**Use `|>` for all data transformations. Readability flows top-down.**

```gleam
// ✅ DO: Pipe all transformations
data
|> string.trim
|> string.lowercase
|> int.parse
|> result.map(fn(n) { n + 1 })
|> result.unwrap(0)

// ❌ DON'T: Nested function calls
int.parse(string.lowercase(string.trim(data)))
```

### RULE_4: EXHAUSTIVE_MATCHING
**Every `case` expression must cover ALL possibilities. No catch-all `*` if verifiable.**

```gleam
// ✅ DO: Match all variants
case user.role {
  Admin -> "Show admin panel"
  Editor -> "Show editor tools"
  Viewer -> "Show read-only view"
}

// ✅ DO: Use guards for value constraints
case list {
  [x, ..] if x > 10 -> "Large number"
  [x, ..] -> "Normal number"
  [] -> "Empty"
}

// ❌ DON'T: Partial matching
case user.role {
  Admin -> "Admin"
  _ -> "Other"  // Only if truly exhaustive or uncertain
}
```

### RULE_5: LABELED_ARGUMENTS
**Functions with >2 arguments MUST use labels for clarity.**

```gleam
// ✅ DO: Labeled arguments >2 params
pub fn create_user(name: String, email: String, age: Int) -> User {
  // Named parameters at call site
  create_user(name: "John", email: "j@example.com", age: 30)
}

pub fn send_email(to: String, subject: String, body: String) -> Result(Nil, Error) {
  // Clear intent at call site
  send_email(to: user.email, subject: "Welcome", body: msg)
}

// ❌ DON'T: Unnamed arguments >2
pub fn old_style(String, String, Int) -> Result(User, Error)
```

### RULE_6: TYPE_SAFETY_FIRST
**Avoid `dynamic`. Define custom types for domain concepts.**

```gleam
// ✅ DO: Custom types for domain
pub type UserId { UserId(Int) }
pub type Email { Email(String) }

pub fn find_user(user_id: UserId) -> Option(User) {
  // Type-safe, intent clear
}

// ✅ DO: Sum types for impossible states
pub type State {
  Connecting
  Connected(ip: String)
  Disconnected(error: String)
}

// ❌ DON'T: Primitive obsession
pub fn find_user(user_id: Int) -> Option(User)  // Any Int could be passed

// ❌ DON'T: dynamic casting
let x = dynamic.from("string")
let _ = dynamic.string(x)
```

### RULE_7: FORMAT_OR_DEATH
**Code is invalid if `gleam format --check` fails. No exceptions.**

```bash
# Every commit must pass:
gleam format --check

# Before committing:
gleam format  # Auto-format
gleam format --check  # Verify
```

---

## LEXICAL STRUCTURE & NAMING

### Types: PascalCase (MANDATORY)
```gleam
pub type User { User(name: String, email: String) }
pub type HttpRequest { Get(url: String) }
pub type PaymentStatus { Pending | Completed(date: String) }
```

### Values & Functions: snake_case (MANDATORY)
```gleam
let user_id = 123
pub fn get_user_by_id(user_id: UserId) -> Option(User) { }
let calculate_total_cost = fn(items) { }
```

### Documentation: First-Class
```gleam
//// Module-level documentation (top of file).
//// Explain what this module does.

/// Function documentation.
/// Explain parameters, return value, and usage.
pub fn my_function(arg: String) -> Result(Int, Error) { }
```

---

## TYPE SYSTEM: Modeling Reality

### Null Safety
```gleam
// ✅ Option for "maybe" values
pub type Profile {
  Profile(bio: Option(String), created_at: String)
}

// Access with exhaustive matching
case profile.bio {
  Some(text) -> "Bio: " <> text
  None -> "No bio"
}
```

### Custom Types Over Primitives
```gleam
// ✅ DO: Wrap primitives in meaningful types
pub type UserId { UserId(Int) }
pub type Email { Email(String) }

// ❌ DON'T: Pass raw primitives
pub fn find(id: Int) -> Option(User)  // What Int? ID or age?
```

### Records with Labeled Fields
```gleam
// ✅ DO: Clear structure
pub type CreateUserRequest {
  CreateUserRequest(name: String, email: String, age: Int)
}

pub fn create_user(req: CreateUserRequest) -> Result(User, Error) { }

// Call with labels
create_user(CreateUserRequest(
  name: "John",
  email: "john@example.com",
  age: 30,
))

// Or shorter
let user = CreateUserRequest(name: "John", email: "j@ex.com", age: 30)
```

### Strict Primitives
```gleam
// ❌ DON'T: Mix Int and Float
1 + 1.0  // Compile error

// ✅ DO: Explicit conversion
1 |> int.to_float |> float.add(1.0)
```

---

## CONTROL FLOW: The Death of the Loop

### No Loops
```gleam
// ❌ DON'T: Loops don't exist
for i in [1, 2, 3] { }

// ✅ DO: Use list.map, list.filter, recursion
[1, 2, 3]
|> list.map(fn(x) { x * 2 })
|> list.filter(fn(x) { x > 2 })

// ✅ DO: Recursion with accumulator (TCO)
fn sum(list: List(Int), acc: Int) -> Int {
  case list {
    [] -> acc
    [x, ..xs] -> sum(xs, acc + x)
  }
}
```

### Exhaustive case Expressions
```gleam
// ✅ DO: All branches handled
case state {
  Connecting -> "Connecting..."
  Connected(ip) -> "Connected to " <> ip
  Disconnected(error) -> "Error: " <> error
}

// ✅ DO: Tuple matching for complex logic
case user.role, is_authenticated {
  Admin, True -> render_admin_dashboard()
  Editor, True -> render_editor_tools()
  _, False -> render_login()
}
```

### Guards for Value Constraints
```gleam
case age {
  x if x >= 18 -> "Adult"
  x if x >= 13 -> "Teen"
  _ -> "Child"
}
```

---

## ERROR HANDLING: Railway Oriented Programming

### Result as Values
```gleam
// ✅ DO: Errors are values, not exceptions
pub fn divide(a: Int, b: Int) -> Result(Int, String) {
  case b {
    0 -> Error("Division by zero")
    _ -> Ok(a / b)
  }
}

// Chain with result.try, result.map, result.map_error
result.try(parse_age(s), fn(age) {
  result.try(validate_age(age), fn(_) {
    Ok("Valid age")
  })
})
```

### Error Mapping
```gleam
// ✅ DO: Map errors to domain types
result.map_error(io_error, fn(err) {
  ReadFileError(reason: err)
})
```

### Assertions (RARE)
```gleam
// ✅ DO: Only when invariant is guaranteed by logic
let assert Ok(value) = trusted_function_that_cannot_fail()

// ❌ DON'T: Assertions for uncertain operations
let assert Ok(parsed) = int.parse(user_input)  // Could fail!
```

---

## The `use` Expression

### Purpose: Callback Flattening
```gleam
// ✅ DO: Flatten resource management
pub fn main() {
  use file <- simplifile.open("data.txt")
  // File auto-closes at end of block
  use lines <- simplifile.read_lines(file)
  process(lines)
}

// ❌ DON'T: Pyramid of doom
case simplifile.open("data.txt") {
  Ok(file) -> case simplifile.read_lines(file) {
    Ok(lines) -> process(lines)
    Error(e) -> Error(e)
  }
  Error(e) -> Error(e)
}
```

### Resource Management Pattern
```gleam
// Open/Defer/Close pattern via `use`
use db <- connect_database()
// db is automatically closed at end of scope
```

---

## PIPELINES & DATA FLOW

### Pipe Operator (`|>`)
```gleam
// ✅ DO: Top-down data flow
raw_data
|> string.trim
|> string.lowercase
|> int.parse
|> result.unwrap(0)
|> int.add(5, _)  // Passes to 2nd argument

// Capture non-first positions
let multiply_by_two = fn(x) { x * 2 }
10 |> multiply_by_two  // Passes to first arg
```

---

## ARCHITECTURE & VISIBILITY

### Encapsulation with Opaque Types
```gleam
// ✅ DO: Hide implementation details
pub opaque type Email { Email(String) }

pub fn new(s: String) -> Result(Email, Nil) {
  case string.contains(s, "@") {
    True -> Ok(Email(s))
    False -> Error(Nil)
  }
}

// ✅ DO: Expose validated constructors
pub fn to_string(email: Email) -> String {
  let Email(s) = email
  s
}
```

### Module Structure
```gleam
// 1-to-1 mapping: file = module
src/my_app/user.gleam → import my_app/user

// No circular imports allowed
// If A imports B, B must not import A
```

---

## TESTING & RELIABILITY

### Framework: gleeunit
```gleam
// Files must end in _test.gleam
import gleeunit
import gleeunit/should

pub fn my_test() {
  1 + 1
  |> should.equal(2)
}
```

### Mocking: Higher-Order Functions
```gleam
// ✅ DO: Inject dependencies as functions
pub type Service {
  Service(fetch: fn(UserId) -> Result(User, Error))
}

pub fn get_user(service: Service, id: UserId) -> Result(User, Error) {
  service.fetch(id)
}

// Test with mock
let mock = Service(fetch: fn(_) { Ok(test_user) })
get_user(mock, UserId(1))
|> should.equal(Ok(test_user))
```

### Record Dependency Injection
```gleam
pub type Config {
  Config(database: fn(String) -> Result(String, Nil))
}

pub fn handle_request(config: Config) -> Result(Response, Error) {
  use data <- result.try(config.database("SELECT * FROM users"))
  Ok(Response(data))
}
```

---

## ANTI-PATTERNS (AVOID)

### Bool Blindness
```gleam
// ❌ DON'T: Return Bool for validation
pub fn is_valid_email(s: String) -> Bool { }

// ✅ DO: Return Result with reason
pub fn validate_email(s: String) -> Result(Email, ValidationError) {
  case string.contains(s, "@") {
    True -> Ok(Email(s))
    False -> Error(MissingAtSign)
  }
}
```

### Index Iteration
```gleam
// ❌ DON'T: Loop by index (linked lists!)
for i in 0..list.length(items) {
  list.at(items, i)  // O(n) per access!
}

// ✅ DO: Pattern match
case items {
  [x, ..xs] -> process(x, xs)
  [] -> Nil
}

// ✅ DO: Use list.map, list.fold
items |> list.map(process)
```

### Primitive Obsession
```gleam
// ❌ DON'T: Pass raw Int for IDs
pub fn find_user(user_id: Int) -> Option(User)

// ✅ DO: Wrap in custom type
pub type UserId { UserId(Int) }
pub fn find_user(user_id: UserId) -> Option(User)
```

### Catching Dynamic Values
```gleam
// ❌ DON'T: Use dynamic without strong reason
let x = dynamic.from(some_value)
let result = dynamic.int(x)

// ✅ DO: Define custom types
pub type Value { IntValue(Int) | StringValue(String) }
```

---

## GLEAM IDIOMS

### Option Chaining
```gleam
// ✅ DO: Chain Option operations
let user = find_user(id)
|> option.then(fn(u) { find_profile(u.id) })
|> option.map(fn(p) { p.bio })
|> option.unwrap("No bio")
```

### Result Railway
```gleam
// ✅ DO: Chain Result operations
parse_config(s)
|> result.try(fn(cfg) { validate_config(cfg) })
|> result.map(fn(cfg) { apply_config(cfg) })
|> result.map_error(fn(err) { ConfigError(err) })
```

### List Transformations
```gleam
// ✅ DO: Use standard library over recursion
items
|> list.filter(fn(x) { x.active })
|> list.map(fn(x) { x.name })
|> list.sort(string.compare)
```

---

**Gleam is strict for a reason. Enforce the skill. Trust the compiler.**
