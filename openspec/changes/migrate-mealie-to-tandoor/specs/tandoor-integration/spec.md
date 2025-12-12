# Tandoor Integration Specification

## ADDED Requirements

### Requirement: Tandoor API Client
The system SHALL provide an HTTP client for the Tandoor Recipe Manager API v1.5+ with authentication, pagination, and error handling.

#### Scenario: Fetch recipes with authentication
- **WHEN** `tandoor/client.get_recipes()` is called
- **THEN** request includes Bearer token authentication
- **AND** returns paginated list of TandoorRecipe types
- **AND** handles cursor-based pagination correctly

#### Scenario: Get recipe by ID
- **WHEN** `tandoor/client.get_recipe_by_id(id)` is called
- **THEN** returns full recipe with ingredients and nutrition
- **AND** handles recipe not found errors gracefully

#### Scenario: Create recipe programmatically
- **WHEN** `tandoor/client.create_recipe(recipe_data)` is called
- **THEN** recipe is created in Tandoor via POST
- **AND** returns created recipe with assigned ID

### Requirement: Tandoor to Internal Recipe Mapping
The system SHALL convert Tandoor recipe format to internal Recipe type with all nutritional data preserved.

#### Scenario: Complete recipe conversion
- **WHEN** `tandoor_to_recipe(tandoor_recipe)` is called with complete data
- **THEN** all fields are mapped correctly (name, ingredients, nutrition)
- **AND** macro calculations match Tandoor nutrition values

#### Scenario: Handle missing nutrition data
- **WHEN** Tandoor recipe has incomplete nutrition data
- **THEN** None values are used for missing fields
- **AND** conversion succeeds without errors

### Requirement: Connectivity and Health Checks
The system SHALL verify Tandoor service availability before making API requests.

#### Scenario: Tandoor service available
- **WHEN** health check is performed
- **THEN** Tandoor API responds with 200 OK
- **AND** connectivity is confirmed

#### Scenario: Tandoor service unavailable
- **WHEN** Tandoor is not responding
- **THEN** health check fails with appropriate error
- **AND** fallback behavior is triggered

### Requirement: Retry Logic with Exponential Backoff
The system SHALL retry failed Tandoor API requests with exponential backoff strategy.

#### Scenario: Transient failure recovery
- **WHEN** API request fails with 503 Service Unavailable
- **THEN** request is retried with exponential backoff
- **AND** succeeds on retry within timeout window

#### Scenario: Permanent failure handling
- **WHEN** all retry attempts exhausted
- **THEN** error is returned to caller
- **AND** fallback mechanism is invoked

### Requirement: Graceful Fallback for Tandoor Unavailability
The system SHALL provide fallback behavior when Tandoor service is unavailable.

#### Scenario: Use cached recipes
- **WHEN** Tandoor is unavailable
- **THEN** system uses cached recipe data
- **AND** continues operating with reduced functionality

#### Scenario: Fallback to USDA foods only
- **WHEN** Tandoor unavailable and no cached recipes
- **THEN** auto planner uses USDA foods only
- **AND** user is notified of limited functionality

### Requirement: Auto Planner Integration
The system SHALL generate meal plans using recipes fetched from Tandoor API.

#### Scenario: Fetch and plan with Tandoor recipes
- **WHEN** auto planner generates meal plan
- **THEN** recipes are fetched from Tandoor
- **AND** filtered by diet principles
- **AND** selected based on macro targets

#### Scenario: Save meal plan with Tandoor references
- **WHEN** meal plan is saved to database
- **THEN** `recipe_json` contains full Tandoor recipe data
- **AND** Tandoor recipe ID is preserved for reference

### Requirement: Food Logging with Tandoor Recipes
The system SHALL support logging meals from Tandoor recipes with proper source attribution.

#### Scenario: Create food log from Tandoor recipe
- **WHEN** user logs meal from Tandoor recipe
- **THEN** food log created with `source_type = 'tandoor_recipe'`
- **AND** `recipe_json` field populated with full recipe
- **AND** macros calculated from Tandoor nutrition data

#### Scenario: Aggregate macros with Tandoor sources
- **WHEN** daily macro totals are calculated
- **THEN** Tandoor recipe logs are included
- **AND** macros aggregate correctly across all source types

### Requirement: Data Migration from Mealie
The system SHALL provide a migration path from Mealie to Tandoor with zero data loss.

#### Scenario: Bulk recipe migration
- **WHEN** migration script is executed
- **THEN** all Mealie recipes are fetched
- **AND** transformed to Tandoor format
- **AND** created in Tandoor via API
- **AND** mapping log created (Mealie slug → Tandoor ID)

#### Scenario: Update food logs source type
- **WHEN** database migration runs
- **THEN** all `source_type = 'mealie_recipe'` updated to `'tandoor_recipe'`
- **AND** `recipe_json` fields transformed to Tandoor format
- **AND** no data loss occurs
