# Recipe Form Data Flow Diagram

## Detailed Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant Router as web.gleam
    participant Handler as recipe_handlers.gleam
    participant Validator as recipe_validation.gleam
    participant Storage as storage.gleam
    participant Database as PostgreSQL

    Note over User,Database: Happy Path - Recipe Creation

    User->>Browser: Navigate to /recipes/new
    Browser->>Router: GET /recipes/new
    Router->>Handler: new_recipe_page()
    Handler-->>Browser: Render empty form HTML
    Browser-->>User: Display form

    User->>Browser: Fill form fields
    Browser->>Browser: Client-side validation (on blur)

    User->>Browser: Click "Create Recipe"
    Browser->>Router: POST /api/recipes (form data)

    Router->>Handler: create_recipe(req, ctx)
    Handler->>Handler: parse_recipe_form(form_data)

    Handler->>Validator: validate_recipe_input(input)
    Validator->>Validator: validate_name()
    Validator->>Validator: validate_category()
    Validator->>Validator: validate_ingredients()
    Validator->>Validator: validate_instructions()
    Validator->>Validator: validate_macros()
    Validator->>Validator: validate_servings()
    Validator-->>Handler: Valid(recipe)

    Handler->>Storage: save_recipe(conn, recipe)
    Storage->>Database: INSERT INTO recipes...
    Database-->>Storage: Success
    Storage-->>Handler: Ok(Nil)

    Handler-->>Router: Redirect(/recipes/:id)
    Router-->>Browser: 302 Location: /recipes/:id
    Browser-->>User: Show recipe detail page

    Note over User,Database: Error Path - Validation Failure

    User->>Browser: Navigate to /recipes/new
    Browser->>Router: GET /recipes/new
    Router->>Handler: new_recipe_page()
    Handler-->>Browser: Render empty form HTML

    User->>Browser: Fill incomplete form
    User->>Browser: Click "Create Recipe"
    Browser->>Router: POST /api/recipes (invalid data)

    Router->>Handler: create_recipe(req, ctx)
    Handler->>Handler: parse_recipe_form(form_data)
    Handler->>Validator: validate_recipe_input(input)

    Validator->>Validator: validate_name()
    Validator-->>Validator: Error("name required")
    Validator->>Validator: validate_ingredients()
    Validator-->>Validator: Error("min 1 ingredient")

    Validator-->>Handler: Invalid([errors])
    Handler->>Handler: render_form_with_errors(input, errors)
    Handler-->>Browser: 400 Bad Request + HTML form
    Browser-->>User: Show errors inline

    Note over User,Database: Error Path - Database Failure

    User->>Browser: Submit valid form
    Browser->>Router: POST /api/recipes
    Router->>Handler: create_recipe(req, ctx)
    Handler->>Validator: validate_recipe_input(input)
    Validator-->>Handler: Valid(recipe)

    Handler->>Storage: save_recipe(conn, recipe)
    Storage->>Database: INSERT INTO recipes...
    Database-->>Storage: Error (connection lost)
    Storage-->>Handler: Error(DatabaseError("..."))

    Handler->>Handler: log_error("Recipe save failed", msg)
    Handler-->>Browser: 500 Internal Error + error page
    Browser-->>User: Show error with retry option
```

## State Transition Diagram

```mermaid
stateDiagram-v2
    [*] --> FormEmpty: Navigate to /recipes/new

    FormEmpty --> FormFilling: User starts typing
    FormFilling --> FormValidating: Field blur event

    FormValidating --> FormFilling: Field valid
    FormValidating --> FormInvalid: Field invalid
    FormInvalid --> FormFilling: User corrects error

    FormFilling --> FormSubmitting: User clicks submit
    FormInvalid --> FormSubmitting: User clicks submit (ignores warnings)

    FormSubmitting --> ServerValidating: POST /api/recipes

    ServerValidating --> FormInvalid: Validation errors
    ServerValidating --> RecipeSaving: All fields valid

    RecipeSaving --> RecipeSuccess: Database save OK
    RecipeSaving --> RecipeError: Database error

    RecipeSuccess --> RecipeDetail: Redirect to /recipes/:id
    RecipeDetail --> [*]

    RecipeError --> FormFilling: User retries
    RecipeError --> [*]: User gives up
```

## Component Interaction Diagram

```mermaid
graph TB
    subgraph "Browser Layer"
        A[HTML Form] -->|User Input| B[Client Validation JS]
        B -->|Valid| C[Form Submission]
        B -->|Invalid| D[Error Display]
        D -->|User Fix| A
    end

    subgraph "Routing Layer"
        C -->|POST /api/recipes| E[web.gleam Router]
        E -->|Route Match| F[recipe_handlers.gleam]
    end

    subgraph "Business Logic Layer"
        F -->|Parse| G[parse_recipe_form]
        G -->|Input| H[recipe_validation.gleam]
        H -->|ValidationResult| F
    end

    subgraph "Data Layer"
        F -->|Valid Recipe| I[storage.gleam]
        I -->|SQL Query| J[(PostgreSQL)]
        J -->|Result| I
        I -->|Result| F
    end

    subgraph "Response Layer"
        F -->|Success| K[Redirect Response]
        F -->|Error| L[Error Response]
        K -->|302| M[Recipe Detail Page]
        L -->|400/500| N[Error Page]
    end

    style H fill:#f9f,stroke:#333,stroke-width:4px
    style I fill:#bbf,stroke:#333,stroke-width:2px
    style J fill:#ddf,stroke:#333,stroke-width:2px
```

## Data Transformation Flow

```mermaid
graph LR
    A[Form HTML] -->|Submit| B[FormData Object]
    B -->|Parse| C[RecipeInput Type]
    C -->|Validate| D{Valid?}
    D -->|Yes| E[Recipe Type]
    D -->|No| F[List ValidationError]
    E -->|Serialize| G[SQL Parameters]
    G -->|Execute| H[(Database Row)]
    F -->|Format| I[Error HTML]
    H -->|Success| J[Redirect]
    I -->|400| K[Form with Errors]

    style D fill:#ff9,stroke:#333,stroke-width:4px
    style E fill:#9f9,stroke:#333,stroke-width:2px
    style F fill:#f99,stroke:#333,stroke-width:2px
```

## Key Data Structures

### 1. Form Data (HTTP POST)

```
Content-Type: application/x-www-form-urlencoded

name=Grilled+Chicken&
category=chicken&
ingredients[0][name]=Chicken+breast&
ingredients[0][quantity]=8+oz&
ingredients[1][name]=Rice&
ingredients[1][quantity]=1+cup&
instructions[0]=Cook+rice&
instructions[1]=Grill+chicken&
protein=45.0&
fat=12.0&
carbs=55.0&
servings=2&
fodmap_level=low&
vertical_compliant=true
```

### 2. RecipeInput Type (Parsed)

```gleam
RecipeInput(
  name: "Grilled Chicken",
  category: "chicken",
  ingredients: [
    IngredientInput("Chicken breast", "8 oz"),
    IngredientInput("Rice", "1 cup"),
  ],
  instructions: [
    "Cook rice",
    "Grill chicken",
  ],
  protein: 45.0,
  fat: 12.0,
  carbs: 55.0,
  servings: 2,
  fodmap_level: "low",
  vertical_compliant: True,
)
```

### 3. Recipe Type (Validated)

```gleam
Recipe(
  id: "uuid-generated",
  name: "Grilled Chicken",
  ingredients: [
    Ingredient("Chicken breast", "8 oz"),
    Ingredient("Rice", "1 cup"),
  ],
  instructions: ["Cook rice", "Grill chicken"],
  macros: Macros(protein: 45.0, fat: 12.0, carbs: 55.0),
  servings: 2,
  category: "chicken",
  fodmap_level: Low,
  vertical_compliant: True,
)
```

### 4. Database Row (Serialized)

```sql
INSERT INTO recipes VALUES (
  'uuid-generated',                              -- id
  'Grilled Chicken',                             -- name
  'Chicken breast:8 oz|Rice:1 cup',              -- ingredients
  'Cook rice|Grill chicken',                     -- instructions
  45.0,                                          -- protein
  12.0,                                          -- fat
  55.0,                                          -- carbs
  2,                                             -- servings
  'chicken',                                     -- category
  'low',                                         -- fodmap_level
  true                                           -- vertical_compliant
);
```

## Error Handling Flow

```mermaid
flowchart TD
    A[Request Received] --> B{Parse Form Data}
    B -->|Success| C{Validate Input}
    B -->|Failure| D[400 Parse Error]

    C -->|Valid| E{Save to DB}
    C -->|Invalid| F[400 Validation Errors]

    E -->|Success| G[302 Redirect]
    E -->|DB Error| H{Error Type}

    H -->|Constraint| I[400 Duplicate/Constraint]
    H -->|Connection| J[500 DB Connection]
    H -->|Timeout| K[500 DB Timeout]

    F --> L[Render Form with Errors]
    I --> L
    J --> M[Render Error Page]
    K --> M

    style C fill:#ff9,stroke:#333,stroke-width:4px
    style E fill:#ff9,stroke:#333,stroke-width:4px
    style F fill:#f99,stroke:#333,stroke-width:2px
    style G fill:#9f9,stroke:#333,stroke-width:2px
```

## Validation Pipeline

```mermaid
graph TD
    A[RecipeInput] --> B[validate_name]
    A --> C[validate_category]
    A --> D[validate_ingredients]
    A --> E[validate_instructions]
    A --> F[validate_macros]
    A --> G[validate_servings]
    A --> H[validate_fodmap_level]

    B --> I{Collect Results}
    C --> I
    D --> I
    E --> I
    F --> I
    G --> I
    H --> I

    I -->|All OK| J[Valid Recipe]
    I -->|Any Errors| K[Invalid + Error List]

    style I fill:#ff9,stroke:#333,stroke-width:4px
    style J fill:#9f9,stroke:#333,stroke-width:2px
    style K fill:#f99,stroke:#333,stroke-width:2px
```

## Concurrency & Locking

Since this is a single-user application (MVP), we don't need complex locking. However, for future multi-user scenarios:

```mermaid
sequenceDiagram
    participant User1
    participant User2
    participant Database

    Note over User1,Database: Optimistic Locking (Future)

    User1->>Database: Load recipe (v1)
    User2->>Database: Load recipe (v1)

    User1->>Database: Save recipe (v1 -> v2)
    Database-->>User1: Success (v2)

    User2->>Database: Save recipe (v1 -> v2)
    Database-->>User2: Error: Stale version
    User2->>User2: Notify user of conflict
    User2->>Database: Reload recipe (v2)
    User2->>Database: Save recipe (v2 -> v3)
    Database-->>User2: Success (v3)
```

**Implementation**:
- Add `version` column to recipes table
- Increment on every update
- Check version matches before UPDATE
- Return error if version mismatch

---

## Detailed Validation Rules Flow

```mermaid
graph TD
    A[validate_recipe_input] --> B[validate_name]
    A --> C[validate_category]
    A --> D[validate_ingredients]
    A --> E[validate_instructions]
    A --> F[validate_macros]
    A --> G[validate_servings]

    B --> B1{Length = 0?}
    B1 -->|Yes| B2[Error: required]
    B1 -->|No| B3{Length > 100?}
    B3 -->|Yes| B4[Error: too_long]
    B3 -->|No| B5[OK: name]

    D --> D1{Count = 0?}
    D1 -->|Yes| D2[Error: required]
    D1 -->|No| D3{Count > 50?}
    D3 -->|Yes| D4[Error: too_many]
    D3 -->|No| D5[Validate each ingredient]

    D5 --> D6{For each ingredient}
    D6 --> D7{Name empty?}
    D7 -->|Yes| D8[Error: ingredient name required]
    D7 -->|No| D9{Quantity empty?}
    D9 -->|Yes| D10[Error: quantity required]
    D9 -->|No| D11[OK: ingredient]

    F --> F1[validate_protein]
    F --> F2[validate_fat]
    F --> F3[validate_carbs]

    F1 --> F4{Value < 0?}
    F4 -->|Yes| F5[Error: negative]
    F4 -->|No| F6{Value > 1000?}
    F6 -->|Yes| F7[Error: too_large]
    F6 -->|No| F8[OK: protein]

    style B1 fill:#ff9
    style D1 fill:#ff9
    style F4 fill:#ff9
```

---

This data flow documentation provides a comprehensive view of how data moves through the recipe creation system, from user input to database persistence, including all validation and error handling paths.
