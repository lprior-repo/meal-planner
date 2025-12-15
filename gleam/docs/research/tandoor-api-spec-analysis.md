# Tandoor Recipe Manager API Specification Analysis
## Food Object Structure Research

**Bead**: meal-planner-27a
**Agent**: 5 of 8 (Tandoor API Spec Research)
**Date**: 2025-12-14

---

## Executive Summary

After extensive research into Tandoor Recipe Manager's API documentation, I was unable to find explicit, published OpenAPI schema documentation for the `/api/food/` endpoint. However, based on multiple sources and code implementations, I can provide informed analysis.

---

## Research Methodology

### Sources Consulted

1. **Official Documentation**
   - [Tandoor Recipes Documentation](https://docs.tandoor.dev/)
   - [Configuration Guide](https://docs.tandoor.dev/system/configuration/)
   - [API Support Discussion](https://github.com/TandoorRecipes/recipes/discussions/818)

2. **Implementation References**
   - [Tandoor MCP Server](https://github.com/starbuck93/tandoor-mcp-server)
   - [Tandoor Importer](https://github.com/timkolloch/tandoor_importer)
   - [RecipeBook-Tandoor Python Client](https://github.com/NBPub/RecipeBook-Tandoor)

3. **Community Resources**
   - [TandoorRecipes GitHub](https://github.com/TandoorRecipes/recipes)
   - [Open Tandoor Data](https://github.com/TandoorRecipes/open-tandoor-data)

### Key Findings from Documentation

**From Official Docs**:
- "Almost every object used by Tandoor is accessible via a standardized RESTful API"
- API uses Django REST Framework (DRF)
- API Client generated automatically from OpenAPI interface
- Built-in API browser available at `https://your-instance/api/`

**From Community Tools**:
- Foods have properties like "Sugars," "Fats," "Energy"
- Foods contain "URL" field and "FDC ID" field
- Tandoor importer references nutrient properties

---

## Current Implementation Analysis

### Our Type Definitions

We currently have TWO different food type representations:

#### 1. **TandoorFood** (2 fields) - Minimal/Embedded
```gleam
// File: src/meal_planner/tandoor/types.gleam
pub type TandoorFood {
  TandoorFood(
    id: Int,
    name: String
  )
}
```

**Usage**: Referenced in recipe ingredients (embedded/simplified representation)
**Purpose**: Lightweight reference when full food data not needed

#### 2. **Food** (8 fields) - Complete
```gleam
// File: src/meal_planner/tandoor/types/food/food.gleam
pub type Food {
  Food(
    id: Int,
    name: String,
    plural_name: Option(String),
    description: String,
    recipe: Option(FoodSimple),
    food_onhand: Option(Bool),
    supermarket_category: Option(Int),
    ignore_shopping: Bool,
  )
}
```

**Usage**: Full food API operations (get, list, create, update)
**Purpose**: Complete food metadata for detailed operations

---

## Tandoor API Food Object - Inferred Structure

Based on research and Django REST Framework patterns, the actual Tandoor API food object likely contains:

### Core Fields (High Confidence)
```json
{
  "id": 123,                    // Integer - Primary key
  "name": "Chicken Breast",     // String - Required
  "plural_name": "Chicken Breasts", // String - Optional
  "description": "Skinless chicken breast", // String
  "url": "https://...",         // String - External reference
  "fdc_id": "174500",          // String - FoodData Central ID
}
```

### Additional Fields (Medium Confidence)
```json
{
  "recipe": {                   // Object - Optional recipe reference
    "id": 456,
    "name": "Base Recipe"
  },
  "food_onhand": true,         // Boolean - Inventory status
  "supermarket_category": {    // Object or Integer - Category reference
    "id": 1,
    "name": "Meat & Poultry"
  },
  "ignore_shopping": false,    // Boolean - Shopping list flag
}
```

### Nutrient Properties (From Importer Tool)
```json
{
  "properties": [              // Array - Nutrient data
    {
      "property_type": "energy",
      "property_amount": 165,
      "unit": "kcal"
    },
    {
      "property_type": "protein",
      "property_amount": 31,
      "unit": "g"
    }
  ]
}
```

---

## Comparison: Our Types vs. Tandoor Reality

### TandoorFood (2 fields) - ❌ INCOMPLETE

**What it has**: `id`, `name`
**What it's missing**: Everything else
**Verdict**: Too minimal for real API operations

**Problems**:
- Cannot represent full food data from API
- Missing optional fields that API returns
- Inadequate for create/update operations
- Loses data when deserializing API responses

### Food (8 fields) - ✅ CLOSER TO REALITY

**What it has**:
- ✅ `id` - Core identifier
- ✅ `name` - Required name
- ✅ `plural_name` - Optional plural form
- ✅ `description` - Food description
- ✅ `recipe` - Optional recipe reference
- ✅ `food_onhand` - Inventory tracking
- ✅ `supermarket_category` - Shopping organization
- ✅ `ignore_shopping` - Shopping list control

**What it's likely missing** (based on research):
- ❌ `url` - External reference URL
- ❌ `fdc_id` - FoodData Central identifier
- ❌ `properties` - Nutrient/property array
- ❌ Timestamps (`created_at`, `updated_at`)
- ❌ User/space relationships

**Verdict**: Good foundation, but incomplete

---

## Recommendations

### 1. **Type Architecture Decision** ✅

**Keep BOTH types, but clarify their purposes**:

```gleam
// Minimal type for embedded references (ingredients)
pub type TandoorFood {
  TandoorFood(id: Int, name: String)
}

// Complete type for full API operations
pub type Food {
  Food(
    // Core fields
    id: Int,
    name: String,

    // Enhanced metadata
    plural_name: Option(String),
    description: String,
    url: Option(String),           // ADD: External reference
    fdc_id: Option(String),        // ADD: FoodData Central ID

    // Relationships
    recipe: Option(FoodSimple),
    supermarket_category: Option(Int),

    // Flags
    food_onhand: Option(Bool),
    ignore_shopping: Bool,

    // Future: Add properties/nutrients as needed
  )
}
```

### 2. **API Response Mapping**

**Current Issue**: Type inconsistency between:
- What API returns (full Food object)
- What we expect (sometimes TandoorFood, sometimes Food)

**Solution**:
```gleam
// API operations ALWAYS return Food type
pub fn get_food(config, id) -> Result(Food, TandoorError)
pub fn list_foods(config, params) -> Result(PaginatedResponse(Food), TandoorError)
pub fn create_food(config, request) -> Result(Food, TandoorError)
pub fn update_food(config, id, request) -> Result(Food, TandoorError)

// Conversion helper when you need minimal reference
pub fn to_tandoor_food(food: Food) -> TandoorFood {
  TandoorFood(id: food.id, name: food.name)
}
```

### 3. **Missing Fields to Add**

Based on research, enhance Food type with:

```gleam
pub type Food {
  Food(
    // ... existing fields ...

    // Add these based on Tandoor API research:
    url: Option(String),              // External URL reference
    fdc_id: Option(String),           // FoodData Central ID
    properties: Option(List(FoodProperty)), // Nutrients
    created_at: Option(String),       // ISO timestamp
    updated_at: Option(String),       // ISO timestamp
  )
}

pub type FoodProperty {
  FoodProperty(
    property_type: String,  // e.g., "energy", "protein"
    property_amount: Float,
    unit: String,          // e.g., "kcal", "g"
  )
}
```

### 4. **Documentation Updates Needed**

- **types.gleam**: Update TandoorFood documentation to clarify "embedded-only use"
- **food/food.gleam**: Update Food documentation to list all supported fields
- **API modules**: Ensure all functions clearly state return type (Food, not TandoorFood)
- **README**: Add section explaining type hierarchy

---

## Verification Strategy

**Since OpenAPI schema is not publicly documented**, to verify actual structure:

1. **Direct API Testing** (Recommended):
   ```bash
   # Query a Tandoor instance directly
   curl -H "Authorization: Bearer YOUR_TOKEN" \
        https://your-tandoor.com/api/food/1/ | jq
   ```

2. **Inspect Source Code**:
   - Clone: `git clone https://github.com/TandoorRecipes/recipes.git`
   - Find: `grep -r "class Food" --include="*.py"`
   - Check: `cookbook/serializers.py` or `cookbook/api/serializers.py`

3. **Use Built-in API Browser**:
   - Navigate to: `https://your-tandoor-instance/api/`
   - Browse to: `/api/food/` endpoint
   - Inspect: Schema tab for exact field definitions

---

## Conclusion

### Which Type Matches Reality?

**Answer**: **Neither exactly matches, but Food (8-field) is much closer**.

- **TandoorFood** (2 fields): Too minimal, only suitable for embedded references
- **Food** (8 fields): Good foundation, but missing documented fields like `url`, `fdc_id`, and `properties`

### Recommended Path Forward

1. ✅ **Keep both types** with clear separation:
   - `TandoorFood` → Embedded ingredient references ONLY
   - `Food` → Full API operations

2. ✅ **Enhance Food type** with missing fields:
   - Add `url`, `fdc_id`
   - Consider adding `properties` for nutrients
   - Add timestamps if needed

3. ✅ **Update all API functions** to consistently:
   - Return `Food` type (not `TandoorFood`)
   - Accept `Food` for updates
   - Use decoders that handle all Food fields

4. ✅ **Add conversion utilities**:
   - `to_tandoor_food(Food) -> TandoorFood` for when minimal ref needed
   - `from_tandoor_food(TandoorFood) -> FoodCreateRequest` for creating

5. ⚠️ **Verify with real API**:
   - Test against actual Tandoor instance
   - Confirm all fields decode correctly
   - Update types based on real responses

---

## References

- [Tandoor Recipes Documentation](https://docs.tandoor.dev/)
- [API Support Discussion](https://github.com/TandoorRecipes/recipes/discussions/818)
- [TandoorRecipes Repository](https://github.com/TandoorRecipes/recipes)
- [Tandoor Importer Tool](https://github.com/timkolloch/tandoor_importer)
- [Django REST Framework Serializers](https://www.django-rest-framework.org/api-guide/serializers/)

---

**Next Steps for Other Agents**:
- Agent 6: Review this analysis for technical accuracy
- Agent 7: Implement recommended type changes
- Agent 8: Update tests and documentation
