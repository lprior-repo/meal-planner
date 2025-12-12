# Code Refactoring: Long Parameter Lists

## Completed Refactorings

### 1. ServerConfig (web.gleam) - 8 parameters → 3 grouped records
**Before:**
```gleam
pub type ServerConfig {
  ServerConfig(
    port: Int,
    db_host: String,
    db_port: Int,
    db_name: String,
    db_user: String,
    db_password: String,
    mealie_url: String,
    mealie_token: String,
  )
}
```

**After:**
```gleam
pub type DatabaseConfig {
  DatabaseConfig(host: String, port: Int, name: String, user: String, password: String)
}

pub type MealieConfig {
  MealieConfig(url: String, token: String)
}

pub type ServerConfig {
  ServerConfig(port: Int, database: DatabaseConfig, mealie: MealieConfig)
}
```

**Benefits:**
- Logical grouping of related configuration
- Easier to extend database or Mealie config independently
- Better encapsulation and single responsibility

### 2. Config (config.gleam) - 14 parameters → 4 grouped records
**Before:**
```gleam
pub type Config {
  Config(
    database_host: String,
    database_port: Int,
    database_name: String,
    database_user: String,
    database_password: String,
    database_pool_size: Int,
    port: Int,
    environment: String,
    mealie_base_url: String,
    mealie_api_token: String,
    todoist_api_key: String,
    usda_api_key: String,
    openai_api_key: String,
    openai_model: String,
  )
}
```

**After:**
```gleam
pub type DatabaseConfig {
  DatabaseConfig(host: String, port: Int, name: String, user: String, password: String, pool_size: Int)
}

pub type ServerConfig {
  ServerConfig(port: Int, environment: String)
}

pub type MealieConfig {
  MealieConfig(base_url: String, api_token: String)
}

pub type ExternalServicesConfig {
  ExternalServicesConfig(
    todoist_api_key: String,
    usda_api_key: String,
    openai_api_key: String,
    openai_model: String,
  )
}

pub type Config {
  Config(
    database: DatabaseConfig,
    server: ServerConfig,
    mealie: MealieConfig,
    external_services: ExternalServicesConfig,
  )
}
```

**Benefits:**
- Clear separation of concerns (database, server, integrations)
- External services grouped together for easier management
- Scalable: easy to add new external service configs
- Access pattern: `config.database.host` is more semantic than `config.database_host`

## Remaining Refactoring Opportunities

### 3. Micronutrients (types.gleam) - 21 parameters
**Current State:**
```gleam
pub type Micronutrients {
  Micronutrients(
    fiber: Option(Float),
    sugar: Option(Float),
    sodium: Option(Float),
    cholesterol: Option(Float),
    vitamin_a: Option(Float),
    vitamin_c: Option(Float),
    vitamin_d: Option(Float),
    vitamin_e: Option(Float),
    vitamin_k: Option(Float),
    vitamin_b6: Option(Float),
    vitamin_b12: Option(Float),
    folate: Option(Float),
    thiamin: Option(Float),
    riboflavin: Option(Float),
    niacin: Option(Float),
    calcium: Option(Float),
    iron: Option(Float),
    magnesium: Option(Float),
    phosphorus: Option(Float),
    potassium: Option(Float),
    zinc: Option(Float),
  )
}
```

**Recommendation:** Consider a builder pattern or grouped vitamin records:
```gleam
pub type Vitamins {
  Vitamins(
    a: Option(Float),
    c: Option(Float),
    d: Option(Float),
    e: Option(Float),
    k: Option(Float),
    b_complex: BVitamins,
  )
}

pub type BVitamins {
  BVitamins(
    b6: Option(Float),
    b12: Option(Float),
    folate: Option(Float),
    thiamin: Option(Float),
    riboflavin: Option(Float),
    niacin: Option(Float),
  )
}

pub type Minerals {
  Minerals(
    calcium: Option(Float),
    iron: Option(Float),
    magnesium: Option(Float),
    phosphorus: Option(Float),
    potassium: Option(Float),
    zinc: Option(Float),
  )
}

pub type Micronutrients {
  Micronutrients(
    fiber: Option(Float),
    sugar: Option(Float),
    sodium: Option(Float),
    cholesterol: Option(Float),
    vitamins: Vitamins,
    minerals: Minerals,
  )
}
```

### 4. FoodLogEntry (types.gleam) - 10 parameters
**Current State:**
```gleam
pub type FoodLogEntry {
  FoodLogEntry(
    id: LogEntryId,
    recipe_id: RecipeId,
    recipe_name: String,
    servings: Float,
    macros: Macros,
    micronutrients: Option(Micronutrients),
    meal_type: MealType,
    logged_at: String,
    source_type: String,
    source_id: String,
  )
}
```

**Recommendation:** Group into metadata and nutritional info:
```gleam
pub type FoodLogMetadata {
  FoodLogMetadata(
    id: LogEntryId,
    meal_type: MealType,
    logged_at: String,
  )
}

pub type FoodReference {
  FoodReference(
    recipe_id: RecipeId,
    recipe_name: String,
    servings: Float,
    source_type: String,
    source_id: String,
  )
}

pub type FoodLogEntry {
  FoodLogEntry(
    metadata: FoodLogMetadata,
    food: FoodReference,
    nutrition: NutritionData,
  )
}
```

### 5. CustomFood (types.gleam) - 9 parameters
**Current State:**
```gleam
pub type CustomFood {
  CustomFood(
    id: CustomFoodId,
    user_id: UserId,
    name: String,
    brand: Option(String),
    description: Option(String),
    serving_size: Float,
    serving_unit: String,
    macros: Macros,
    calories: Float,
    micronutrients: Option(Micronutrients),
  )
}
```

**Recommendation:** Separate identity, metadata, and nutrition:
```gleam
pub type FoodIdentity {
  FoodIdentity(
    id: CustomFoodId,
    user_id: UserId,
    name: String,
  )
}

pub type FoodMetadata {
  FoodMetadata(
    brand: Option(String),
    description: Option(String),
    serving_size: Float,
    serving_unit: String,
  )
}

pub type NutritionData {
  NutritionData(
    macros: Macros,
    calories: Float,
    micronutrients: Option(Micronutrients),
  )
}

pub type CustomFood {
  CustomFood(
    identity: FoodIdentity,
    metadata: FoodMetadata,
    nutrition: NutritionData,
  )
}
```

## Summary

### Completed
- ✅ ServerConfig: 8 → 3 parameters (62% reduction)
- ✅ Config: 14 → 4 parameters (71% reduction)

### Remaining Work
- Micronutrients: 21 parameters (critical - highest complexity)
- FoodLogEntry: 10 parameters (medium priority)
- CustomFood: 9 parameters (medium priority)

### Impact
- **Improved readability:** Nested access (e.g., `config.database.host`) is more semantic
- **Better maintainability:** Related fields are grouped together
- **Easier testing:** Can mock smaller config objects independently
- **Scalability:** Easy to add new fields to specific groups without impacting unrelated code
