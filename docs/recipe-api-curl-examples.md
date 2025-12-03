# Recipe API - cURL Examples

## Table of Contents
- [GET /recipes/new](#get-recipesnew)
- [POST /api/recipes](#post-apirecipes)
- [Common Error Examples](#common-error-examples)

---

## GET /recipes/new

### Description
Fetches the HTML form for creating a new recipe.

### Example Request

```bash
curl -X GET http://localhost:8080/recipes/new \
  -H "Accept: text/html"
```

### Success Response (200 OK)

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <title>New Recipe - Meal Planner</title>
    <link rel="stylesheet" href="/static/styles.css">
  </head>
  <body>
    <div class="container">
      <a href="/recipes" class="back-link">← Back to recipes</a>
      <div class="page-header">
        <h1>New Recipe</h1>
      </div>
      <form method="POST" action="/api/recipes" class="recipe-form">
        <!-- Form fields for recipe creation -->
      </form>
    </div>
  </body>
</html>
```

---

## POST /api/recipes

### Description
Creates a new recipe with nutritional information, ingredients, and instructions.

### Example 1: Simple Chicken Recipe

```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Chicken and Rice" \
  -d "category=chicken" \
  -d "servings=1" \
  -d "protein=45.0" \
  -d "fat=8.0" \
  -d "carbs=45.0" \
  -d "fodmap_level=low" \
  -d "vertical_compliant=true" \
  -d "ingredient_name_0=Chicken breast" \
  -d "ingredient_quantity_0=8 oz" \
  -d "ingredient_name_1=White rice" \
  -d "ingredient_quantity_1=1 cup" \
  -d "ingredient_name_2=Olive oil" \
  -d "ingredient_quantity_2=1 tbsp" \
  -d "instruction_0=Cook rice according to package directions" \
  -d "instruction_1=Grill chicken breast until internal temperature reaches 165°F" \
  -d "instruction_2=Serve chicken over rice"
```

### Success Response (201 Created)

```json
{
  "id": "abc123-def456",
  "name": "Chicken and Rice",
  "category": "chicken",
  "servings": 1,
  "macros": {
    "protein": 45.0,
    "fat": 8.0,
    "carbs": 45.0,
    "calories": 472.0
  },
  "fodmap_level": "low",
  "vertical_compliant": true,
  "ingredients": [
    {
      "name": "Chicken breast",
      "quantity": "8 oz"
    },
    {
      "name": "White rice",
      "quantity": "1 cup"
    },
    {
      "name": "Olive oil",
      "quantity": "1 tbsp"
    }
  ],
  "instructions": [
    "Cook rice according to package directions",
    "Grill chicken breast until internal temperature reaches 165°F",
    "Serve chicken over rice"
  ]
}
```

**Headers:**
```
HTTP/1.1 201 Created
Location: /recipes/abc123-def456
Content-Type: application/json
```

---

### Example 2: Beef and Potatoes

```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Beef and Potatoes" \
  -d "category=beef" \
  -d "servings=2" \
  -d "protein=40.0" \
  -d "fat=20.0" \
  -d "carbs=35.0" \
  -d "fodmap_level=low" \
  -d "vertical_compliant=true" \
  -d "ingredient_name_0=Ground beef (85/15)" \
  -d "ingredient_quantity_0=12 oz" \
  -d "ingredient_name_1=Russet potatoes" \
  -d "ingredient_quantity_1=2 medium" \
  -d "ingredient_name_2=Butter" \
  -d "ingredient_quantity_2=2 tbsp" \
  -d "ingredient_name_3=Salt and pepper" \
  -d "ingredient_quantity_3=To taste" \
  -d "instruction_0=Wash and dice potatoes into 1-inch cubes" \
  -d "instruction_1=Boil potatoes in salted water for 15 minutes until tender" \
  -d "instruction_2=While potatoes cook, brown ground beef in a large skillet over medium-high heat" \
  -d "instruction_3=Drain potatoes and add butter, season with salt and pepper" \
  -d "instruction_4=Combine beef and potatoes, serve hot"
```

---

### Example 3: Vegetarian Recipe (Not Vertical Diet Compliant)

```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Quinoa Buddha Bowl" \
  -d "category=vegetarian" \
  -d "servings=2" \
  -d "protein=15.0" \
  -d "fat=12.0" \
  -d "carbs=55.0" \
  -d "fodmap_level=medium" \
  -d "vertical_compliant=false" \
  -d "ingredient_name_0=Quinoa" \
  -d "ingredient_quantity_0=1 cup uncooked" \
  -d "ingredient_name_1=Chickpeas" \
  -d "ingredient_quantity_1=1 can (15 oz)" \
  -d "ingredient_name_2=Mixed vegetables (carrots, broccoli, bell peppers)" \
  -d "ingredient_quantity_2=2 cups" \
  -d "ingredient_name_3=Tahini dressing" \
  -d "ingredient_quantity_3=1/4 cup" \
  -d "instruction_0=Rinse quinoa and cook according to package directions (usually 15 minutes)" \
  -d "instruction_1=Preheat oven to 425°F" \
  -d "instruction_2=Drain and rinse chickpeas, toss with olive oil and spices" \
  -d "instruction_3=Roast chickpeas and chopped vegetables for 20-25 minutes" \
  -d "instruction_4=Assemble bowls with quinoa base, top with roasted items and drizzle with tahini"
```

---

### Example 4: Seafood Recipe with Multiple Servings

```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Salmon with Vegetables" \
  -d "category=seafood" \
  -d "servings=4" \
  -d "protein=35.0" \
  -d "fat=18.0" \
  -d "carbs=8.0" \
  -d "fodmap_level=low" \
  -d "vertical_compliant=true" \
  -d "ingredient_name_0=Salmon fillets" \
  -d "ingredient_quantity_0=4 fillets (6 oz each)" \
  -d "ingredient_name_1=Broccoli florets" \
  -d "ingredient_quantity_1=4 cups" \
  -d "ingredient_name_2=Olive oil" \
  -d "ingredient_quantity_2=3 tbsp" \
  -d "ingredient_name_3=Lemon" \
  -d "ingredient_quantity_3=2 lemons, sliced" \
  -d "ingredient_name_4=Garlic powder" \
  -d "ingredient_quantity_4=2 tsp" \
  -d "instruction_0=Preheat oven to 400°F" \
  -d "instruction_1=Place salmon fillets on a baking sheet lined with parchment paper" \
  -d "instruction_2=Brush salmon with olive oil and season with garlic powder" \
  -d "instruction_3=Arrange broccoli around salmon, drizzle with remaining olive oil" \
  -d "instruction_4=Top salmon with lemon slices" \
  -d "instruction_5=Roast for 12-15 minutes until salmon is cooked through" \
  -d "instruction_6=Serve immediately with lemon wedges"
```

---

## Common Error Examples

### Error 400: Missing Required Field

**Request:**
```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "category=chicken" \
  -d "servings=1" \
  -d "protein=45.0" \
  -d "fat=8.0" \
  -d "carbs=45.0"
```

**Response (400 Bad Request):**
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "name",
      "message": "Recipe name is required"
    }
  ]
}
```

---

### Error 400: Invalid Category

**Request:**
```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Mystery Meat" \
  -d "category=mystery" \
  -d "servings=1" \
  -d "protein=30.0" \
  -d "fat=15.0" \
  -d "carbs=20.0" \
  -d "fodmap_level=low" \
  -d "ingredient_name_0=Unknown protein" \
  -d "ingredient_quantity_0=1 lb" \
  -d "instruction_0=Cook until done"
```

**Response (400 Bad Request):**
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "category",
      "message": "Category must be one of: chicken, beef, pork, seafood, vegetarian, other"
    }
  ]
}
```

---

### Error 400: Invalid Servings (Zero or Negative)

**Request:**
```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Test Recipe" \
  -d "category=chicken" \
  -d "servings=0" \
  -d "protein=45.0" \
  -d "fat=8.0" \
  -d "carbs=45.0" \
  -d "fodmap_level=low" \
  -d "ingredient_name_0=Chicken" \
  -d "ingredient_quantity_0=1 lb" \
  -d "instruction_0=Cook"
```

**Response (400 Bad Request):**
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "servings",
      "message": "Servings must be at least 1"
    }
  ]
}
```

---

### Error 400: Negative Macro Values

**Request:**
```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Invalid Macros" \
  -d "category=chicken" \
  -d "servings=1" \
  -d "protein=-10.0" \
  -d "fat=8.0" \
  -d "carbs=45.0" \
  -d "fodmap_level=low" \
  -d "ingredient_name_0=Chicken" \
  -d "ingredient_quantity_0=1 lb" \
  -d "instruction_0=Cook"
```

**Response (400 Bad Request):**
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "protein",
      "message": "Protein value cannot be negative"
    }
  ]
}
```

---

### Error 400: Missing Ingredients

**Request:**
```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=No Ingredients Recipe" \
  -d "category=chicken" \
  -d "servings=1" \
  -d "protein=45.0" \
  -d "fat=8.0" \
  -d "carbs=45.0" \
  -d "fodmap_level=low" \
  -d "instruction_0=Somehow cook without ingredients"
```

**Response (400 Bad Request):**
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "ingredients",
      "message": "At least one ingredient is required"
    }
  ]
}
```

---

### Error 400: Missing Instructions

**Request:**
```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=No Instructions Recipe" \
  -d "category=chicken" \
  -d "servings=1" \
  -d "protein=45.0" \
  -d "fat=8.0" \
  -d "carbs=45.0" \
  -d "fodmap_level=low" \
  -d "ingredient_name_0=Chicken" \
  -d "ingredient_quantity_0=1 lb"
```

**Response (400 Bad Request):**
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "instructions",
      "message": "At least one instruction is required"
    }
  ]
}
```

---

### Error 400: Invalid FODMAP Level

**Request:**
```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Test Recipe" \
  -d "category=chicken" \
  -d "servings=1" \
  -d "protein=45.0" \
  -d "fat=8.0" \
  -d "carbs=45.0" \
  -d "fodmap_level=super-high" \
  -d "ingredient_name_0=Chicken" \
  -d "ingredient_quantity_0=1 lb" \
  -d "instruction_0=Cook"
```

**Response (400 Bad Request):**
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "fodmap_level",
      "message": "FODMAP level must be one of: low, medium, high"
    }
  ]
}
```

---

### Error 400: Multiple Validation Errors

**Request:**
```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=" \
  -d "category=invalid" \
  -d "servings=0" \
  -d "protein=-5.0" \
  -d "fat=8.0" \
  -d "carbs=45.0" \
  -d "fodmap_level=extreme"
```

**Response (400 Bad Request):**
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "name",
      "message": "Recipe name is required"
    },
    {
      "field": "category",
      "message": "Category must be one of: chicken, beef, pork, seafood, vegetarian, other"
    },
    {
      "field": "servings",
      "message": "Servings must be at least 1"
    },
    {
      "field": "protein",
      "message": "Protein value cannot be negative"
    },
    {
      "field": "fodmap_level",
      "message": "FODMAP level must be one of: low, medium, high"
    },
    {
      "field": "ingredients",
      "message": "At least one ingredient is required"
    },
    {
      "field": "instructions",
      "message": "At least one instruction is required"
    }
  ]
}
```

---

### Error 500: Database Connection Failure

**Request:**
```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Valid Recipe" \
  -d "category=chicken" \
  -d "servings=1" \
  -d "protein=45.0" \
  -d "fat=8.0" \
  -d "carbs=45.0" \
  -d "fodmap_level=low" \
  -d "ingredient_name_0=Chicken" \
  -d "ingredient_quantity_0=1 lb" \
  -d "instruction_0=Cook"
```

**Response (500 Internal Server Error):**
```json
{
  "error": "Internal server error",
  "message": "Failed to save recipe to database"
}
```

---

## Testing Tips

### 1. Test with Browser Form Submission
Visit `http://localhost:8080/recipes/new` in your browser and submit the form to test the full user flow.

### 2. Test Validation with Invalid Data
Use the error examples above to verify validation is working correctly.

### 3. Test with Different Content Types
The API expects `application/x-www-form-urlencoded` for form submissions. JSON format would require a different endpoint.

### 4. Verify Calorie Calculation
The API automatically calculates calories from macros using the formula:
```
calories = (protein × 4) + (fat × 9) + (carbs × 4)
```

For example:
- Protein: 45g × 4 = 180 cal
- Fat: 8g × 9 = 72 cal
- Carbs: 45g × 4 = 180 cal
- **Total: 432 calories**

### 5. Test with Multiple Ingredients and Instructions
The form supports dynamic fields numbered from 0 upwards:
- `ingredient_name_0`, `ingredient_name_1`, `ingredient_name_2`, etc.
- `ingredient_quantity_0`, `ingredient_quantity_1`, `ingredient_quantity_2`, etc.
- `instruction_0`, `instruction_1`, `instruction_2`, etc.

---

## Notes on Implementation Status

**Note:** Based on the current codebase analysis:
- ✅ `GET /recipes/new` is fully implemented and returns the HTML form
- ⚠️ `POST /api/recipes` endpoint is NOT yet implemented in the handler
- The form exists and will submit to `/api/recipes` but the backend handler needs to be added

To implement the POST handler, you'll need to:
1. Parse form data from the request
2. Validate all required fields
3. Generate a unique ID for the recipe
4. Save to the database using `storage.gleam` functions
5. Return appropriate response (201, 400, or 500)
