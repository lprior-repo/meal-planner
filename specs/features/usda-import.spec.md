# Feature: Import Complete USDA FoodData Central Database

## Bead ID: meal-planner-67c (CLOSED)

## Feature Description
Import the complete USDA FoodData Central database into the meal planner to provide comprehensive nutritional data for food items.

## Capabilities

### Capability 1: Parse USDA CSV Files
**Behaviors:**
- GIVEN nutrient.csv WHEN parsing THEN extract nutrient_id, name, unit_name
- GIVEN food.csv WHEN parsing THEN extract fdc_id, description, data_type
- GIVEN food_nutrient.csv WHEN parsing THEN extract fdc_id, nutrient_id, amount

### Capability 2: Create Database Schema
**Behaviors:**
- GIVEN migration system WHEN running THEN create usda_nutrients table
- GIVEN migration system WHEN running THEN create usda_foods table
- GIVEN migration system WHEN running THEN create usda_food_nutrients table
- GIVEN schema WHEN creating THEN add proper indexes for queries

### Capability 3: Import Data Pipeline
**Behaviors:**
- GIVEN USDA directory WHEN importing THEN process files in correct order (nutrients, foods, food_nutrients)
- GIVEN large CSV WHEN importing THEN batch inserts for performance
- GIVEN import error WHEN occurring THEN rollback transaction and report

### Capability 4: Query Nutritional Data
**Behaviors:**
- GIVEN food description WHEN searching THEN return matching foods
- GIVEN fdc_id WHEN querying THEN return all nutrient values
- GIVEN ingredient name WHEN matching THEN find closest USDA food match

## Acceptance Criteria
- [ ] All USDA CSV files parse correctly
- [ ] Database schema supports efficient queries
- [ ] Import handles large datasets (100k+ foods)
- [ ] Nutritional data accessible via API
- [ ] Tests cover parsing, import, and query operations

## Test Criteria (BDD)
```gherkin
Scenario: Import nutrients from CSV
  Given a nutrient.csv file with 3 nutrient rows
  When parsing and importing
  Then 3 nutrients exist in usda_nutrients table
  And each has nutrient_id, name, and unit_name

Scenario: Query food nutritional data
  Given imported USDA data for "Chicken, breast, raw"
  When querying nutrients for that food
  Then returns protein amount (31g per 100g)
  And returns fat amount (3.6g per 100g)
  And returns carbohydrate amount (0g per 100g)
```
