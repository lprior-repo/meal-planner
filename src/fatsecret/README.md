# FatSecret Rust SDK

CUPID-compliant Rust implementation of the FatSecret Platform API client with OAuth 1.0a signing.

**Status:** In Development
**Reference Implementation:** Gleam SDK in `src/meal_planner/fatsecret/`
**Epic:** MP-feq4

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Module Structure](#module-structure)
- [OAuth Flow](#oauth-flow)
- [API Layers](#api-layers)
- [CUPID Compliance](#cupid-compliance)
- [Code Examples](#code-examples)
- [Migration Guide (Gleam to Rust)](#migration-guide-gleam-to-rust)
- [API Endpoint Reference](#api-endpoint-reference)
- [Testing](#testing)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Application Layer                               │
│   (Windmill Scripts, CLI, Web Handlers)                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                          Service Layer                                   │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│   │  Foods  │  │  Diary  │  │ Profile │  │ Weight  │  │Exercise │      │
│   │ Service │  │ Service │  │ Service │  │ Service │  │ Service │      │
│   └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘      │
├────────┼───────────┼───────────┼───────────┼───────────┼───────────────┤
│                          Client Layer (API)                              │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│   │  Foods  │  │  Diary  │  │ Profile │  │ Weight  │  │Exercise │      │
│   │ Client  │  │ Client  │  │ Client  │  │ Client  │  │ Client  │      │
│   └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘      │
├────────┴───────────┴───────────┴───────────┴───────────┴───────────────┤
│                          Core Layer                                      │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│   │  Config  │  │   HTTP   │  │  OAuth   │  │  Errors  │               │
│   │          │  │  Client  │  │  1.0a    │  │          │               │
│   └──────────┘  └──────────┘  └──────────┘  └──────────┘               │
├─────────────────────────────────────────────────────────────────────────┤
│                          Types Layer                                     │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│   │  Foods   │  │  Diary   │  │ Profile  │  │  Common  │               │
│   │  Types   │  │  Types   │  │  Types   │  │  Types   │               │
│   └──────────┘  └──────────┘  └──────────┘  └──────────┘               │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Module Structure

```
src/fatsecret/
├── lib.rs                    # Main facade - re-exports all public types/functions
│
├── core/                     # Core infrastructure
│   ├── mod.rs               # Module exports
│   ├── config.rs            # Environment configuration
│   ├── oauth.rs             # OAuth 1.0a primitives
│   ├── http.rs              # HTTP client with OAuth signing
│   └── errors.rs            # Error types with thiserror
│
├── types/                    # Domain types (shared)
│   ├── mod.rs               # Type exports
│   ├── ids.rs               # Opaque ID newtypes (FoodId, ServingId, etc.)
│   ├── nutrition.rs         # Nutrition, Serving types
│   └── common.rs            # MealType, Date helpers
│
├── foods/                    # Foods domain
│   ├── mod.rs               # Domain exports
│   ├── types.rs             # Food, FoodSearchResult, FoodSearchResponse
│   ├── client.rs            # API client (search, get)
│   └── service.rs           # Business logic (caching, enrichment)
│
├── diary/                    # Diary domain (user-specific, 3-legged OAuth)
│   ├── mod.rs
│   ├── types.rs             # FoodEntry, FoodEntryInput, DaySummary
│   ├── client.rs            # CRUD + summaries
│   └── service.rs           # Daily tracking, goal validation
│
├── profile/                  # Profile domain (user auth)
│   ├── mod.rs
│   ├── types.rs             # Profile, ProfileAuth
│   ├── oauth.rs             # 3-legged OAuth flow
│   ├── client.rs            # create, get, get_auth
│   └── service.rs           # Goal calculations
│
├── weight/                   # Weight tracking
│   ├── mod.rs
│   ├── types.rs             # WeightEntry, WeightUpdate
│   ├── client.rs            # CRUD + summaries
│   └── service.rs           # Weight trend analysis
│
├── exercise/                 # Exercise logging
│   ├── mod.rs
│   ├── types.rs             # Exercise, ExerciseEntry
│   ├── client.rs            # CRUD
│   └── service.rs           # Calorie burn calculations
│
├── recipes/                  # Recipes domain
│   ├── mod.rs
│   ├── types.rs             # Recipe, RecipeSearchResult
│   ├── client.rs            # search, get, autocomplete
│   └── service.rs           # Recipe enrichment
│
├── favorites/                # Favorites management
│   ├── mod.rs
│   ├── types.rs             # FavoriteFood, FavoriteRecipe
│   ├── client.rs            # CRUD
│   └── service.rs           # Recently/most eaten
│
├── saved_meals/              # Saved meal templates
│   ├── mod.rs
│   ├── types.rs             # SavedMeal, SavedMealItem
│   ├── client.rs            # CRUD
│   └── service.rs           # Template management
│
├── storage/                  # Token persistence
│   ├── mod.rs
│   ├── crypto.rs            # AES-256-GCM encryption
│   └── postgres.rs          # PostgreSQL storage
│
└── meal_logger/              # Meal logging orchestration
    ├── mod.rs
    ├── batch.rs             # Batch operations
    ├── retry.rs             # Exponential backoff retry
    ├── validators.rs        # Input validation
    └── macro_calculator.rs  # Macro calculations
```

**Total Modules:** ~45 files (porting 69 Gleam modules with consolidation)

---

## OAuth Flow

### OAuth 1.0a Three-Legged Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     OAuth 1.0a Three-Legged Flow                         │
└─────────────────────────────────────────────────────────────────────────┘

  Your App                        FatSecret                       User
     │                               │                              │
     │  1. POST /oauth/request_token │                              │
     │  ─────────────────────────────>                              │
     │                               │                              │
     │  oauth_token + oauth_token_secret                            │
     │  <─────────────────────────────                              │
     │                               │                              │
     │  2. Redirect to /oauth/authorize?oauth_token=...             │
     │  ────────────────────────────────────────────────────────────>
     │                               │                              │
     │                               │  User logs in, approves app  │
     │                               │  <───────────────────────────│
     │                               │                              │
     │                          oauth_verifier                      │
     │  <────────────────────────────────────────────────────────────
     │                               │                              │
     │  3. GET /oauth/access_token   │                              │
     │     + oauth_verifier          │                              │
     │  ─────────────────────────────>                              │
     │                               │                              │
     │  access_token + access_token_secret (permanent)              │
     │  <─────────────────────────────                              │
     │                               │                              │
     │  4. API calls with access token                              │
     │  ─────────────────────────────>                              │
     │                               │                              │
     └───────────────────────────────┴──────────────────────────────┘
```

### OAuth Signature Generation

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      OAuth Signature Generation                          │
└─────────────────────────────────────────────────────────────────────────┘

  1. Collect Parameters                    2. Build Base String
  ┌────────────────────────────┐          ┌────────────────────────────┐
  │ oauth_consumer_key         │          │ METHOD&URL&PARAMS          │
  │ oauth_nonce                │   ───>   │                            │
  │ oauth_signature_method     │          │ POST&https%3A%2F%2F...     │
  │ oauth_timestamp            │          │ &oauth_consumer_key%3D...  │
  │ oauth_token (if available) │          │                            │
  │ oauth_version              │          └────────────────────────────┘
  │ + request parameters       │                      │
  └────────────────────────────┘                      │
                                                      ▼
  4. Add to Request                        3. HMAC-SHA1 + Base64
  ┌────────────────────────────┐          ┌────────────────────────────┐
  │ oauth_signature=XYZ123...  │   <───   │ Key: consumer_secret&      │
  │                            │          │      token_secret          │
  │ (in Authorization header   │          │                            │
  │  or POST body)             │          │ Result: base64(hmac-sha1)  │
  └────────────────────────────┘          └────────────────────────────┘
```

### Code Example

```rust
use fatsecret::core::{Config, oauth};
use fatsecret::profile;

// Step 1: Get request token
let config = Config::from_env()?;
let request_token = profile::oauth::get_request_token(&config, "oob").await?;

// Step 2: Direct user to authorization URL
let auth_url = profile::oauth::get_authorization_url(&config, &request_token);
println!("Visit: {}", auth_url);
println!("Enter verifier code: ");

// Step 3: Exchange for access token
let verifier = read_user_input()?;
let access_token = profile::oauth::get_access_token(
    &config,
    &request_token,
    &verifier
).await?;

// Step 4: Store tokens securely
storage::store_token(&access_token).await?;

// Now make authenticated requests
let entries = diary::client::get_entries(&config, &access_token, date).await?;
```

---

## API Layers

### Layer Responsibilities

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Layer         │ Responsibility          │ Example                       │
├───────────────┼─────────────────────────┼───────────────────────────────┤
│ Service       │ Business logic          │ Validate nutrition goals      │
│               │ Orchestration           │ Cache popular foods           │
│               │ Error enrichment        │ Retry failed requests         │
├───────────────┼─────────────────────────┼───────────────────────────────┤
│ Client        │ API method calls        │ foods.search(query)           │
│               │ Parameter building      │ Build request params          │
│               │ Response parsing        │ Parse JSON to types           │
├───────────────┼─────────────────────────┼───────────────────────────────┤
│ Core/HTTP     │ OAuth signing           │ Add oauth_signature           │
│               │ HTTP transport          │ POST to /rest/server.api      │
│               │ Error handling          │ Parse API error responses     │
├───────────────┼─────────────────────────┼───────────────────────────────┤
│ Types         │ Domain modeling         │ FoodId, Serving, Nutrition    │
│               │ Validation              │ ID format, nutrition range    │
│               │ Serialization           │ serde derives                 │
└───────────────┴─────────────────────────┴───────────────────────────────┘
```

### Request Flow

```
Application
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Service Layer                                                            │
│   foods::service::search_with_cache("apple")                            │
│     - Check cache                                                        │
│     - Validate input                                                     │
│     - Call client                                                        │
│     - Enrich results                                                     │
│     - Update cache                                                       │
└────────────────────────────────────────┬────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Client Layer                                                             │
│   foods::client::search(&config, "apple", None)                         │
│     - Build params: {"method": "foods.search", "search_expression": ... │
│     - Call HTTP layer                                                    │
│     - Parse response to FoodSearchResponse                               │
└────────────────────────────────────────┬────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Core/HTTP Layer                                                          │
│   core::http::make_api_request(&config, "foods.search", params)         │
│     - Add oauth_* parameters                                             │
│     - Generate signature                                                 │
│     - POST to https://platform.fatsecret.com/rest/server.api            │
│     - Check for API errors                                               │
│     - Return JSON body                                                   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## CUPID Compliance

### Principle Analysis by Module

#### C - Composable

| Module | Score | Evidence |
|--------|-------|----------|
| core/config | 10/10 | Pure data struct, injectable |
| core/oauth | 10/10 | Small functions, compose for signing |
| core/http | 10/10 | Takes config, returns Result |
| core/errors | 10/10 | Exhaustive enum, thiserror derives |
| foods/types | 10/10 | Opaque IDs, validation in constructors |
| foods/client | 10/10 | Pure functions, no state |
| foods/service | 10/10 | Wraps client with business logic |

**Composability Patterns:**
```rust
// Small functions that compose
let params = oauth::build_params(&config)?;
let base_string = oauth::create_base_string("POST", url, &params);
let signature = oauth::sign(&base_string, &config.consumer_secret, token_secret);

// Dependency injection
let response = http::make_request(&config, params).await?;

// Result chaining
config.from_env()
    .ok_or(ConfigMissing)?
    .then(|c| client.search(&c, query))?
    .map(|r| service.enrich(r))?
```

#### U - Unix Philosophy

| Module | Score | Evidence |
|--------|-------|----------|
| core/config | 10/10 | Only loads configuration |
| core/oauth | 10/10 | Only OAuth primitives |
| core/http | 10/10 | Only HTTP transport |
| core/errors | 10/10 | Only error types |
| foods/client | 10/10 | Only API calls |
| foods/service | 10/10 | Only business logic |
| diary/handlers/delete | 10/10 | Only DELETE handler |

**Single Responsibility Examples:**
```rust
// oauth.rs - ONLY OAuth primitives
pub fn generate_nonce() -> String { ... }
pub fn unix_timestamp() -> i64 { ... }
pub fn oauth_encode(s: &str) -> String { ... }
pub fn create_signature(...) -> String { ... }

// http.rs - ONLY HTTP transport
pub async fn make_request(...) -> Result<String, FatSecretError> { ... }
pub fn check_api_error(body: &str) -> Result<(), FatSecretError> { ... }

// client.rs - ONLY API calls
pub async fn search(...) -> Result<FoodSearchResponse, FatSecretError> { ... }
pub async fn get(...) -> Result<Food, FatSecretError> { ... }
```

#### P - Predictable

| Module | Score | Evidence |
|--------|-------|----------|
| All | 10/10 | All fallible ops return Result<T, E> |
| types/ids | 10/10 | Opaque newtype wrappers prevent misuse |
| core/errors | 10/10 | Exhaustive error codes |
| */validators | 10/10 | Validation in constructors |

**Predictability Patterns:**
```rust
// Opaque IDs - can't accidentally mix up
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FoodId(String);

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ServingId(String);

// Compiler prevents: get_serving(food_id) - wrong type!

// Exhaustive errors
#[derive(Error, Debug)]
pub enum FatSecretError {
    #[error("API error {code}: {message}")]
    ApiError { code: ApiErrorCode, message: String },

    #[error("Request failed with status {status}: {body}")]
    RequestFailed { status: u16, body: String },

    #[error("Parse error: {0}")]
    ParseError(String),

    // ... all cases covered
}

// Validation in constructors
impl FoodId {
    pub fn new(id: impl Into<String>) -> Result<Self, InvalidId> {
        let id = id.into();
        if id.is_empty() {
            return Err(InvalidId::Empty);
        }
        Ok(FoodId(id))
    }
}
```

#### I - Idiomatic

| Module | Score | Evidence |
|--------|-------|----------|
| All | 10/10 | Uses Result, ?, thiserror |
| types | 10/10 | serde derives |
| async | 10/10 | async/await with reqwest |
| builders | 10/10 | Builder pattern for complex types |

**Idiomatic Rust Patterns:**
```rust
// Error propagation with ?
pub async fn search(config: &Config, query: &str) -> Result<FoodSearchResponse, FatSecretError> {
    let params = build_search_params(query)?;
    let response = http::make_api_request(config, "foods.search", &params).await?;
    let parsed: FoodSearchResponse = serde_json::from_str(&response)?;
    Ok(parsed)
}

// Builder pattern
let entry = FoodEntryBuilder::new()
    .food_id(food_id)
    .serving_id(serving_id)
    .number_of_units(1.5)
    .meal_type(MealType::Lunch)
    .build()?;

// Type-state pattern for OAuth flow
struct NoToken;
struct HasRequestToken(RequestToken);
struct HasAccessToken(AccessToken);

struct OAuthFlow<State> {
    config: Config,
    state: State,
}

impl OAuthFlow<NoToken> {
    fn get_request_token(self) -> Result<OAuthFlow<HasRequestToken>, Error> { ... }
}

impl OAuthFlow<HasRequestToken> {
    fn get_access_token(self, verifier: &str) -> Result<OAuthFlow<HasAccessToken>, Error> { ... }
}
```

#### D - Domain-Based

| Module | Score | Evidence |
|--------|-------|----------|
| types/ids | 10/10 | Opaque IDs enforce domain boundaries |
| diary/types | 10/10 | Rich domain types with variants |
| core/errors | 10/10 | 16 API error codes mapped |
| */service | 10/10 | Business rules in domain layer |

**Domain Modeling Patterns:**
```rust
// Rich domain types with variants
pub enum FoodEntryInput {
    /// From FatSecret database
    FromFood {
        food_id: FoodId,
        serving_id: ServingId,
        number_of_units: f64,
        meal: MealType,
    },
    /// User-created custom entry
    Custom {
        food_entry_name: String,
        serving_id: ServingId,
        calories: f64,
        fat: Option<f64>,
        carbohydrate: Option<f64>,
        protein: Option<f64>,
    },
}

// Business validation in domain
impl FoodEntryInput {
    pub fn validate(&self) -> Result<(), ValidationError> {
        match self {
            Self::Custom { calories, fat, .. } => {
                if *calories < 0.0 {
                    return Err(ValidationError::NegativeNutrition("calories"));
                }
                // ... more validations
            }
            Self::FromFood { number_of_units, .. } => {
                if *number_of_units <= 0.0 {
                    return Err(ValidationError::InvalidUnits);
                }
            }
        }
        Ok(())
    }
}
```

### CUPID Scorecard

| Principle | Target | Strategy |
|-----------|--------|----------|
| **C**omposable | 10/10 | Small functions, dependency injection, Result chaining |
| **U**nix Philosophy | 10/10 | One module = one responsibility |
| **P**redictable | 10/10 | Opaque IDs, Result everywhere, exhaustive errors |
| **I**diomatic | 10/10 | ?, thiserror, serde, async/await, builders |
| **D**omain-Based | 10/10 | Rich types, validation, bounded contexts |

---

## Code Examples

### Search for Foods (2-Legged OAuth)

```rust
use fatsecret::{Config, foods};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Load config from environment
    let config = Config::from_env()
        .ok_or("Missing FATSECRET_CONSUMER_KEY or FATSECRET_CONSUMER_SECRET")?;

    // Search for foods (no user auth required)
    let response = foods::client::search(&config, "chicken breast", None).await?;

    println!("Found {} foods", response.total_results);
    for food in response.foods {
        println!("- {} (ID: {})", food.food_name, food.food_id);
    }

    Ok(())
}
```

### Get Food Details with Servings

```rust
use fatsecret::{Config, foods, FoodId};

async fn get_food_nutrition(food_id_str: &str) -> Result<(), fatsecret::FatSecretError> {
    let config = Config::from_env().ok_or(fatsecret::ConfigMissing)?;
    let food_id = FoodId::new(food_id_str)?;

    let food = foods::client::get(&config, &food_id).await?;

    println!("Food: {}", food.food_name);
    println!("Servings:");
    for serving in &food.servings {
        println!("  - {} ({:.0}g): {:.0} kcal, {:.1}g protein, {:.1}g carbs, {:.1}g fat",
            serving.serving_description,
            serving.metric_serving_amount.unwrap_or(0.0),
            serving.calories,
            serving.protein,
            serving.carbohydrate,
            serving.fat
        );
    }

    Ok(())
}
```

### Create Food Diary Entry (3-Legged OAuth)

```rust
use fatsecret::{Config, diary, FoodId, ServingId, MealType};
use chrono::Utc;

async fn log_meal(
    access_token: &AccessToken,
    food_id: &FoodId,
    serving_id: &ServingId,
) -> Result<diary::FoodEntry, fatsecret::FatSecretError> {
    let config = Config::from_env().ok_or(fatsecret::ConfigMissing)?;

    let input = diary::FoodEntryInput::FromFood {
        food_id: food_id.clone(),
        serving_id: serving_id.clone(),
        number_of_units: 1.5,
        meal: MealType::Lunch,
    };

    let entry = diary::client::create_entry(
        &config,
        access_token,
        &input,
        Utc::now().date_naive(),
    ).await?;

    println!("Created entry: {} ({} kcal)", entry.food_entry_name, entry.calories);
    Ok(entry)
}
```

### Get Daily Summary

```rust
use fatsecret::{Config, diary};
use chrono::NaiveDate;

async fn daily_report(
    access_token: &AccessToken,
    date: NaiveDate,
) -> Result<(), fatsecret::FatSecretError> {
    let config = Config::from_env().ok_or(fatsecret::ConfigMissing)?;

    let summary = diary::client::get_day_summary(&config, access_token, date).await?;

    println!("=== {} ===", date);
    println!("Calories: {:.0} kcal", summary.calories);
    println!("Protein:  {:.1}g", summary.protein);
    println!("Carbs:    {:.1}g", summary.carbohydrate);
    println!("Fat:      {:.1}g", summary.fat);

    if let Some(goal) = summary.calorie_goal {
        let remaining = goal - summary.calories;
        println!("Remaining: {:.0} kcal", remaining);
    }

    Ok(())
}
```

### Batch Log Meals with Retry

```rust
use fatsecret::{Config, meal_logger};

async fn batch_log_from_meal_plan(
    access_token: &AccessToken,
    entries: Vec<diary::FoodEntryInput>,
) -> Result<meal_logger::BatchResult, fatsecret::FatSecretError> {
    let config = Config::from_env().ok_or(fatsecret::ConfigMissing)?;

    // Batch create with automatic retry on transient failures
    let result = meal_logger::batch::create_entries(
        &config,
        access_token,
        entries,
        meal_logger::RetryConfig::default(),
    ).await?;

    println!("Logged {} entries", result.succeeded.len());
    if !result.failed.is_empty() {
        println!("Failed {} entries:", result.failed.len());
        for failure in &result.failed {
            println!("  - {}: {}", failure.entry_name, failure.error);
        }
    }

    Ok(result)
}
```

---

## Migration Guide (Gleam to Rust)

### Type Mappings

| Gleam | Rust | Notes |
|-------|------|-------|
| `Option(T)` | `Option<T>` | Same semantics |
| `Result(T, E)` | `Result<T, E>` | Same semantics |
| `String` | `String` | Same semantics |
| `Int` | `i64` or `i32` | Choose based on range |
| `Float` | `f64` | Same precision |
| `Bool` | `bool` | Same semantics |
| `List(T)` | `Vec<T>` | Same semantics |
| `Dict(K, V)` | `HashMap<K, V>` | Same semantics |
| `opaque type FoodId` | `struct FoodId(String)` | Newtype pattern |

### Pattern Mapping

**Gleam Pattern:**
```gleam
// Gleam: Opaque type
pub opaque type FoodId {
  FoodId(String)
}

pub fn food_id(id: String) -> FoodId {
  FoodId(id)
}

pub fn food_id_to_string(id: FoodId) -> String {
  case id {
    FoodId(s) -> s
  }
}
```

**Rust Equivalent:**
```rust
// Rust: Newtype with private inner
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct FoodId(String);

impl FoodId {
    pub fn new(id: impl Into<String>) -> Result<Self, InvalidId> {
        let id = id.into();
        if id.is_empty() {
            return Err(InvalidId::Empty);
        }
        Ok(FoodId(id))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for FoodId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}
```

### Error Handling

**Gleam Pattern:**
```gleam
// Gleam: use for Result chaining
pub fn search_foods(query: String) -> Result(List(Food), FatSecretError) {
  use config <- result.try(
    config.from_env()
    |> option.to_result(errors.ConfigMissing)
  )
  use response <- result.try(
    http.make_api_request(config, "foods.search", params)
  )
  parse_response(response)
}
```

**Rust Equivalent:**
```rust
// Rust: ? operator for Result chaining
pub async fn search_foods(query: &str) -> Result<Vec<Food>, FatSecretError> {
    let config = Config::from_env()
        .ok_or(FatSecretError::ConfigMissing)?;

    let response = http::make_api_request(&config, "foods.search", &params).await?;

    parse_response(&response)
}
```

### Module Structure

**Gleam:**
```
fatsecret/
  foods/
    types.gleam      # Type definitions
    decoders.gleam   # JSON decoders
    client.gleam     # API client
    service.gleam    # Business logic
```

**Rust:**
```
fatsecret/
  foods/
    mod.rs           # Module exports
    types.rs         # Types + serde derives (combines types.gleam + decoders.gleam)
    client.rs        # API client
    service.rs       # Business logic
```

### Key Differences

| Aspect | Gleam | Rust |
|--------|-------|------|
| JSON Decoding | Separate decoder modules | Serde derives on types |
| Async | Sync (OTP processes) | async/await with tokio |
| HTTP Client | httpc | reqwest |
| Error Types | Custom union types | thiserror derives |
| Configuration | Custom env module | envy or dotenvy |

---

## API Endpoint Reference

### Authentication Endpoints

| Endpoint | Method | OAuth | Description |
|----------|--------|-------|-------------|
| `/oauth/request_token` | POST | 2-leg | Get request token |
| `/oauth/authorize` | GET | - | User authorization page |
| `/oauth/access_token` | GET | 3-leg | Exchange for access token |

### Public API (2-Legged OAuth)

| Method | Description | Parameters |
|--------|-------------|------------|
| `foods.search` | Search foods | `search_expression`, `page`, `max_results` |
| `foods.get` | Get food details | `food_id` |
| `foods.get_v2` | Get food with extended info | `food_id` |
| `foods.autocomplete` | Autocomplete search | `expression` |
| `food_brands.get` | Get brand info | `food_brand_id` |
| `recipe_types.get` | Get recipe categories | - |
| `recipes.search` | Search recipes | `search_expression`, `recipe_types_*`, `page`, `max_results` |
| `recipe.get` | Get recipe details | `recipe_id` |

### User API (3-Legged OAuth)

| Method | Description | Parameters |
|--------|-------------|------------|
| `profile.get` | Get user profile | - |
| `profile.create` | Create profile | `user_id` |
| `profile.get_auth` | Get profile auth | `user_id` |
| `food_entries.get` | Get diary entries | `date` |
| `food_entries.get_month` | Get month summary | `date` |
| `food_entry.create` | Create entry | `food_id`, `serving_id`, `number_of_units`, `meal`, `date` |
| `food_entry.edit` | Edit entry | `food_entry_id`, ... |
| `food_entry.delete` | Delete entry | `food_entry_id` |
| `food_entry.copy` | Copy entries | `from_date`, `to_date`, `meals` |
| `weight.update` | Update weight | `current_weight_kg`, `date`, `comment` |
| `weights.get_month` | Get weight month | `date` |
| `exercise_entries.get` | Get exercises | `date` |
| `exercise_entry.create` | Log exercise | `exercise_id`, `duration_mins`, `date` |
| `exercise_entry.edit` | Edit exercise | `exercise_entry_id`, ... |
| `exercise_entry.delete` | Delete exercise | `exercise_entry_id` |
| `exercise_entries.save_template` | Save as template | `date` |
| `exercise_entries.commit` | Commit day | `date` |
| `saved_meals.get` | Get saved meals | `meal` |
| `saved_meal.create` | Create saved meal | `meal`, `saved_meal_name` |
| `saved_meal.edit` | Edit saved meal | `saved_meal_id`, `saved_meal_name` |
| `saved_meal.delete` | Delete saved meal | `saved_meal_id` |
| `saved_meal_items.get` | Get meal items | `saved_meal_id` |
| `saved_meal_item.add` | Add item | `saved_meal_id`, `food_id`, `serving_id`, ... |
| `saved_meal_item.edit` | Edit item | `saved_meal_item_id`, ... |
| `saved_meal_item.delete` | Delete item | `saved_meal_item_id` |
| `favorite_foods.get` | Get favorites | `page`, `max_results` |
| `favorite_food.add` | Add favorite | `food_id` |
| `favorite_food.delete` | Remove favorite | `food_id` |
| `most_eaten.get` | Get most eaten | `meal` |
| `recently_eaten.get` | Get recent | `meal` |
| `favorite_recipes.get` | Get favorite recipes | `page`, `max_results` |
| `favorite_recipe.add` | Add favorite | `recipe_id` |
| `favorite_recipe.delete` | Remove favorite | `recipe_id` |

### API Error Codes

| Code | Name | Description |
|------|------|-------------|
| 2 | `MissingOAuthParameter` | Required OAuth parameter missing |
| 3 | `UnsupportedOAuthParameter` | Unknown OAuth parameter |
| 4 | `InvalidSignatureMethod` | Must be HMAC-SHA1 |
| 5 | `InvalidConsumerCredentials` | Bad consumer key/secret |
| 6 | `InvalidOrExpiredToken` | Token expired or invalid |
| 7 | `InvalidSignature` | Signature verification failed |
| 8 | `InvalidNonce` | Nonce already used |
| 9 | `InvalidAccessToken` | Access token invalid |
| 13 | `InvalidMethod` | Unknown API method |
| 14 | `ApiUnavailable` | API temporarily unavailable |
| 101 | `MissingRequiredParameter` | Required parameter missing |
| 106 | `InvalidId` | ID format invalid |
| 107 | `InvalidSearchValue` | Search expression invalid |
| 108 | `InvalidDate` | Date format invalid |
| 205 | `WeightDateTooFar` | Weight date too far in future |
| 206 | `WeightDateEarlier` | Weight date earlier than last entry |
| 207 | `NoEntries` | No entries found for date |

---

## Testing

### Unit Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_food_id_validation() {
        assert!(FoodId::new("12345").is_ok());
        assert!(FoodId::new("").is_err());
    }

    #[test]
    fn test_oauth_encode() {
        assert_eq!(oauth_encode("hello world"), "hello%20world");
        assert_eq!(oauth_encode("foo=bar&baz"), "foo%3Dbar%26baz");
    }

    #[test]
    fn test_signature_base_string() {
        let base = create_base_string(
            "POST",
            "https://platform.fatsecret.com/rest/server.api",
            &[("method", "foods.search"), ("search_expression", "apple")],
        );
        assert!(base.starts_with("POST&https%3A%2F%2F"));
    }
}
```

### Integration Tests

```rust
#[tokio::test]
#[ignore] // Requires API credentials
async fn test_foods_search() {
    let config = Config::from_env().expect("Config required");
    let result = foods::client::search(&config, "chicken", None).await;
    assert!(result.is_ok());
    assert!(!result.unwrap().foods.is_empty());
}

#[tokio::test]
#[ignore] // Requires user auth
async fn test_diary_entry_lifecycle() {
    let config = Config::from_env().expect("Config required");
    let token = load_test_token().await.expect("Token required");

    // Create
    let entry = diary::client::create_entry(&config, &token, &input, date).await?;
    assert!(entry.food_entry_id.as_str().len() > 0);

    // Read
    let entries = diary::client::get_entries(&config, &token, date).await?;
    assert!(entries.iter().any(|e| e.food_entry_id == entry.food_entry_id));

    // Delete
    diary::client::delete_entry(&config, &token, &entry.food_entry_id).await?;
}
```

### Test Fixtures

Located at `test/fixtures/fatsecret/scraped/`:

```
test/fixtures/fatsecret/scraped/
├── foods.search.json         # Search response
├── foods.get.json            # Food details
├── food_entries.get.json     # Diary entries
├── profile.get.json          # User profile
└── ...
```

---

## Dependencies

```toml
[dependencies]
# Async runtime
tokio = { version = "1", features = ["full"] }

# HTTP client
reqwest = { version = "0.11", features = ["json"] }

# Serialization
serde = { version = "1", features = ["derive"] }
serde_json = "1"

# Error handling
thiserror = "1"
anyhow = "1"  # For application code

# OAuth 1.0a
hmac = "0.12"
sha1 = "0.10"
base64 = "0.21"
rand = "0.8"

# Encryption (for token storage)
aes-gcm = "0.10"

# Date/time
chrono = { version = "0.4", features = ["serde"] }

# Environment
dotenvy = "0.15"

# URL encoding
percent-encoding = "2"

[dev-dependencies]
tokio-test = "0.4"
wiremock = "0.5"  # For HTTP mocking
```

---

## Resources

- **FatSecret Platform API:** https://platform.fatsecret.com/api/Default.aspx?screen=rapih
- **OAuth 1.0a RFC:** https://datatracker.ietf.org/doc/html/rfc5849
- **Gleam Reference Implementation:** `src/meal_planner/fatsecret/`
- **CUPID Audit:** `FATSECRET_CUPID_AUDIT_2025-12-28.md`
- **Implementation Plan:** `FATSECRET_IMPLEMENTATION_PLAN.md`
- **Epic:** MP-feq4 in Beads

---

## Contributing

1. Follow CUPID principles (Composable, Unix, Predictable, Idiomatic, Domain-based)
2. Add tests for all new functionality
3. Update this README for new features
4. Run `cargo fmt` and `cargo clippy` before committing

---

**Last Updated:** 2025-12-28
**Author:** Claude Code
