# Feature: Recipe Management CRUD

## Bead ID: meal-planner-wwd

## Parent Epic: meal-planner-g8s (Meal Planner Web Application MVP)

## Feature Description
Enable users to create, read, update, and delete custom recipes with full nutritional information, ingredients, and instructions.

## Capabilities

### Capability 1: Create New Recipe
**Behaviors:**
- GIVEN recipe form WHEN user fills details THEN validate required fields
- GIVEN ingredients WHEN adding THEN allow USDA food search for auto-macros
- GIVEN manual macros WHEN entered THEN use user-provided values
- GIVEN valid recipe WHEN saved THEN store in recipes table with unique ID

### Capability 2: View Recipe Details
**Behaviors:**
- GIVEN recipe ID WHEN viewing THEN show full recipe with all fields
- GIVEN macros WHEN displaying THEN show per-serving values
- GIVEN instructions WHEN rendering THEN show numbered steps

### Capability 3: Edit Existing Recipe
**Behaviors:**
- GIVEN recipe WHEN editing THEN pre-fill form with current values
- GIVEN changes WHEN saved THEN update recipe in database
- GIVEN ingredient change WHEN macros auto-calc THEN recalculate totals

### Capability 4: Delete Recipe
**Behaviors:**
- GIVEN recipe WHEN deleting THEN prompt for confirmation
- GIVEN confirmation WHEN confirmed THEN remove from database
- GIVEN recipe in food logs WHEN deleted THEN preserve historical entries

### Capability 5: Import Recipe from URL
**Behaviors:**
- GIVEN recipe URL WHEN importing THEN parse common recipe sites
- GIVEN parsed recipe WHEN imported THEN allow user to edit before saving
- GIVEN USDA matching WHEN available THEN suggest ingredient macros

## Acceptance Criteria
- [ ] Users can create recipes with name, ingredients, instructions, macros
- [ ] Recipes display with full nutritional breakdown
- [ ] Editing preserves recipe history
- [ ] Delete confirmation prevents accidents
- [ ] Recipe import parses common formats

## Test Criteria (BDD)
```gherkin
Scenario: Create a new recipe
  Given user is on recipe creation page
  When user enters name "Grilled Salmon"
  And adds ingredient "salmon fillet" 200g
  And adds ingredient "olive oil" 1 tbsp
  And enters instructions
  And saves recipe
  Then recipe appears in recipe list
  And macros are calculated from ingredients

Scenario: Edit recipe macros
  Given existing recipe "Chicken Stir Fry"
  When user edits protein from 35g to 40g
  And saves changes
  Then recipe shows updated 40g protein
```
