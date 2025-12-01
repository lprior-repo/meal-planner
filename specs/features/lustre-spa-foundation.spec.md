# Feature: Lustre SPA Foundation with MVU Architecture

## Bead ID: meal-planner-4hf

## Feature Description
Create a Lustre Single Page Application foundation using Model-View-Update (Elm-like) architecture for the client-side meal planner interface.

## Capabilities

### Capability 1: Initialize Lustre Application
**Behaviors:**
- GIVEN client/src/client.gleam WHEN app starts THEN initialize Lustre application with init/update/view functions
- GIVEN initial model WHEN app starts THEN set default state with empty meals, no user loaded
- GIVEN modem router WHEN navigating THEN update URL and model accordingly

### Capability 2: Implement Model-View-Update Pattern
**Behaviors:**
- GIVEN Model type WHEN defining THEN include current_page, user_profile, daily_log, recipes
- GIVEN Msg type WHEN defining THEN include NavigateTo, LoadRecipes, LogMeal, UpdateProfile
- GIVEN update function WHEN receiving Msg THEN return (Model, Effect)
- GIVEN view function WHEN rendering THEN produce Html based on current_page

### Capability 3: Handle Client-Side Routing
**Behaviors:**
- GIVEN URL path "/" WHEN navigating THEN show home page
- GIVEN URL path "/recipes" WHEN navigating THEN show recipes list
- GIVEN URL path "/recipes/:id" WHEN navigating THEN show recipe detail
- GIVEN URL path "/dashboard" WHEN navigating THEN show nutrition dashboard
- GIVEN unknown path WHEN navigating THEN show 404 page

### Capability 4: Integrate with Shared Types
**Behaviors:**
- GIVEN shared/src/shared/types.gleam WHEN client compiles THEN import Recipe, Macros, UserProfile
- GIVEN JSON from server WHEN decoding THEN use shared decoders (recipe_decoder, etc.)
- GIVEN client data WHEN encoding THEN use shared encoders (recipe_to_json, etc.)

## Acceptance Criteria
- [ ] Lustre app compiles to JavaScript target
- [ ] MVU pattern implemented with type-safe Model/Msg/update/view
- [ ] Client-side routing works with browser history
- [ ] Shared types compile on JavaScript target
- [ ] Integration with SSR hydration path prepared

## Test Criteria (BDD)
```gherkin
Scenario: Navigate between pages in SPA
  Given the Lustre app is running
  When user clicks "Recipes" navigation link
  Then URL updates to "/recipes"
  And view renders recipes list
  And model.current_page equals RecipesPage

Scenario: Load recipes from API
  Given the app is on recipes page
  When recipes are fetched from /api/recipes
  Then JSON is decoded using shared/types.recipe_decoder
  And model.recipes contains the loaded recipes
  And view updates to show recipe cards
```
