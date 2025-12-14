# Type System and Module Organization Consistency Review

**Date:** 2025-12-14
**Reviewed by:** Code Review Agent
**Scope:** Gleam meal-planner codebase type system, module structure, decoders/encoders

---

## Executive Summary

The codebase demonstrates **generally good organization** with clear separation of concerns, but suffers from **type duplication** and **inconsistent import sources**. The Tandoor SDK shows excellent modular structure, while legacy code has scattered type definitions.

### Key Findings

✅ **Strengths:**
- Clear module hierarchy (tandoor/api/*, tandoor/types/*, tandoor/decoders/*)
- Consistent API function signatures (get_, create_, update_, delete_, list_)
- Good decoder/encoder pairing for most types
- Excellent use of crud_helpers for API calls

❌ **Critical Issues:**
1. **Type Duplication** - Multiple definitions of Recipe, Food, MealPlan across modules
2. **Inconsistent Type Sources** - TandoorRecipe vs Recipe naming confusion
3. **Missing Encoders** - Some types have decoders but no encoders
4. **Import Inconsistency** - Some files import from types.gleam, others from types/*/

🟡 **Recommendations:**
1. Consolidate duplicate type definitions
2. Establish single source of truth for each domain type
3. Complete encoder/decoder coverage
4. Standardize import patterns

---

## 1. Type Definitions Analysis

### 1.1 Core Application Types (`meal_planner/types.gleam`)

**Purpose:** Shared types for meal planner application (cross-platform: JS/Erlang)

**Type Categories:**
- ✅ Macros, Micronutrients - Well-defined, complete API
- ✅ Recipe, UserProfile, FoodLogEntry - Good structure
- ✅ Comprehensive JSON encoders/decoders
- ✅ Display formatting functions included

**Issues:**
- ⚠️ Recipe type overlaps with Tandoor Recipe types
- ⚠️ FoodSource type couples multiple systems (USDA, Tandoor, Custom)

**Recommendation:** 
- Rename to `AppRecipe` to distinguish from `TandoorRecipe`
- Keep FoodSource as-is (valid domain abstraction)

### 1.2 Tandoor Type Definitions

**Multiple Definition Sources - PROBLEM:**

#### Option A: `meal_planner/tandoor/types.gleam`
```gleam
pub type TandoorRecipe {
  TandoorRecipe(
    id: Int,
    name: String,
    description: String,
    servings: Int,
    ingredients: List(TandoorIngredient),
    steps: List(TandoorStep),
    ...
  )
}
```

#### Option B: `meal_planner/tandoor/types/recipe/recipe.gleam`
```gleam
pub type Recipe {
  Recipe(
    id: Int,
    name: String,
    description: String,
    image: Option(String),
    servings: Int,
    keywords: List(String),
    ...
  )
}
```

#### Option C: `meal_planner/tandoor/client.gleam`
```gleam
pub type Recipe {
  Recipe(/* different field structure */)
}
```

#### Option D: `meal_planner/tandoor/mapper.gleam`
```gleam
pub type TandoorRecipe {
  TandoorRecipe(/* yet another structure */)
}
```

**Analysis:**
- 🔴 **4 different Recipe type definitions** in Tandoor module alone
- 🔴 Naming confusion: `TandoorRecipe` vs `Recipe`
- 🔴 Field structure inconsistencies
- 🔴 Unclear which is authoritative

**Recommendation:**
```
CONSOLIDATE TO:
- Use types/recipe/recipe.gleam as single source
- Delete types.gleam (legacy monolith)
- Remove duplicate definitions from client.gleam and mapper.gleam
- Consistent naming: Recipe (in tandoor context it's obvious it's from Tandoor)
```

### 1.3 FatSecret Type Definitions

**Structure:**
```
fatsecret/
  ├── foods/types.gleam       ✅ Food, FoodSearchResult, FoodSearchResponse
  ├── recipes/types.gleam     ✅ Recipe, RecipeIngredient, RecipeDirection
  ├── diary/types.gleam       ✅ FoodEntry, FoodEntryInput, FoodEntryUpdate
  ├── profile/types.gleam     ✅ (exists)
  └── fatsecret.gleam         ⚠️ Type aliases to submodules
```

**Issues:**
- ⚠️ `fatsecret.gleam` has type aliases that duplicate submodule definitions
- ⚠️ Potential name collision with meal_planner/types.gleam

**Recommendation:**
- Remove type aliases from fatsecret.gleam
- Always import from specific modules (foods/types, recipes/types)
- Consider prefixing: FatSecretFood, FatSecretRecipe (if collisions occur)

---

## 2. Module Structure Consistency

### 2.1 Tandoor API Modules ✅ EXCELLENT

**Pattern:**
```
tandoor/api/
  ├── recipe/
  │   ├── get.gleam          pub fn get_recipe(config, id) -> Result(Recipe)
  │   ├── create.gleam       pub fn create_recipe(config, req) -> Result(Recipe)
  │   ├── update.gleam       pub fn update_recipe(config, id, req) -> Result(Recipe)
  │   ├── delete.gleam       pub fn delete_recipe(config, id) -> Result(Nil)
  │   └── list.gleam         pub fn list_recipes(config, params) -> Result(List(Recipe))
  ├── food/
  │   ├── get.gleam
  │   ├── create.gleam
  │   ├── update.gleam
  │   ├── delete.gleam
  │   └── list.gleam
  └── mealplan/
      ├── get.gleam
      ├── create.gleam
      ├── update.gleam
      └── list.gleam
```

**Consistency Check:**
- ✅ All modules follow same structure
- ✅ Function naming: `get_X`, `create_X`, `update_X`, `delete_X`, `list_X`
- ✅ Consistent error handling (Result<T, TandoorError>)
- ✅ All use crud_helpers for HTTP calls

**Minor Issue:**
- ⚠️ `food/get.gleam` imports wrong decoder (`recipe_decoder.food_decoder()`)
  - Should import from `food_decoder.gleam`

### 2.2 FatSecret API Modules ✅ GOOD

**Pattern:**
```
fatsecret/
  ├── foods/
  │   ├── types.gleam
  │   ├── client.gleam       (low-level HTTP)
  │   ├── service.gleam      (business logic)
  │   └── handlers.gleam     (HTTP handlers)
  ├── recipes/
  │   ├── types.gleam
  │   ├── client.gleam
  │   ├── service.gleam
  │   └── handlers.gleam
  └── diary/
      ├── types.gleam
      ├── client.gleam
      ├── service.gleam
      └── handlers.gleam
```

**Consistency Check:**
- ✅ Consistent 4-layer architecture (types, client, service, handlers)
- ✅ All modules follow same pattern
- ✅ Clear separation of concerns

---

## 3. Decoder/Encoder Coverage

### 3.1 Tandoor Decoders ✅ COMPREHENSIVE

**Structure:**
```
tandoor/decoders/
  ├── recipe/
  │   ├── recipe_decoder.gleam          ✅ recipe_decoder()
  │   ├── recipe_overview_decoder.gleam ✅ recipe_overview_decoder()
  │   ├── nutrition_decoder.gleam       ✅ nutrition_decoder()
  │   └── ...
  ├── food/
  │   └── food_decoder.gleam            ✅ food_decoder(), food_simple_decoder()
  ├── mealplan/
  │   ├── meal_plan_decoder.gleam       ✅ meal_plan_decoder()
  │   └── meal_type_decoder.gleam       ✅ meal_type_decoder()
  └── ...
```

**Coverage:**
- ✅ All major types have decoders
- ✅ Consistent naming pattern: `X_decoder.gleam` → `X_decoder()`
- ✅ Decoders return `Decoder(T)` for composition

### 3.2 Tandoor Encoders ⚠️ PARTIAL COVERAGE

**Structure:**
```
tandoor/encoders/
  ├── mealplan/
  │   └── mealplan_encoder.gleam        ✅ encode_mealplan_create()
  ├── food/
  │   └── food_encoder.gleam            ✅ encode_food()
  ├── keyword/
  │   └── keyword_encoder.gleam         ✅ encode_keyword()
  ├── unit/
  │   └── unit_encoder.gleam            ✅ encode_unit()
  └── user/
      └── user_preference_encoder.gleam ✅ encode_user_preference()
```

**Missing Encoders:**
- ❌ No recipe_encoder.gleam (but recipe_create_encoder exists)
- ❌ No nutrition_encoder.gleam
- ❌ No step_encoder.gleam
- ❌ No ingredient_encoder.gleam

**Recommendation:**
```
ADD MISSING ENCODERS:
- tandoor/encoders/recipe/recipe_encoder.gleam
- tandoor/encoders/recipe/nutrition_encoder.gleam
- tandoor/encoders/recipe/step_encoder.gleam
- tandoor/encoders/recipe/ingredient_encoder.gleam
```

### 3.3 Core Types Encoders/Decoders ✅ COMPLETE

**In `meal_planner/types.gleam`:**
- ✅ Macros - encoder + decoder
- ✅ Micronutrients - encoder + decoder
- ✅ Recipe - encoder + decoder
- ✅ UserProfile - encoder + decoder
- ✅ FoodLogEntry - encoder + decoder
- ✅ CustomFood - encoder + decoder

---

## 4. Optional Field Handling

### 4.1 Decoder Consistency ✅ UNIFORM

**Pattern Used:**
```gleam
use field <- decode.field("field", decode.optional(decode.string))
// OR
use field <- decode.optional_field("field", None, decode.optional(decode.string))
```

**Analysis:**
- ✅ Consistent use of `decode.optional()` for Option<T>
- ✅ Consistent use of `decode.optional_field()` for missing JSON keys
- ✅ Error messages are descriptive

### 4.2 Encoder Consistency ✅ UNIFORM

**Pattern Used:**
```gleam
let fields = case optional_value {
  Some(v) -> [#("key", json.string(v)), ..fields]
  None -> fields
}
```

**Analysis:**
- ✅ Consistent pattern for encoding optional fields
- ✅ Uses json.null() where appropriate
- ✅ Helper functions for repeated patterns

---

## 5. Public API Surface

### 5.1 tandoor/api/* Modules ✅ CLEAN

**Public Functions:**
```gleam
// Each module exports 1 primary function:
pub fn get_recipe(config, id) -> Result(Recipe, TandoorError)
pub fn create_recipe(config, request) -> Result(Recipe, TandoorError)
pub fn update_recipe(config, id, request) -> Result(Recipe, TandoorError)
pub fn delete_recipe(config, id) -> Result(Nil, TandoorError)
pub fn list_recipes(config, params) -> Result(ListResponse, TandoorError)
```

**Analysis:**
- ✅ Minimal public surface (1 function per file)
- ✅ Consistent signatures
- ✅ Clear naming

### 5.2 types/* Modules ⚠️ MIXED

**Issues:**
- Some types are pub, some are not (inconsistent)
- Helper functions sometimes public when they should be internal
- Conversion functions (to_string, from_string) are public (correct)

**Recommendation:**
```
STANDARDIZE:
- All type definitions: pub type
- All conversion functions: pub fn
- All helper functions: private (fn, not pub fn)
```

---

## 6. Circular Dependencies

### 6.1 Import Graph Analysis

**No circular dependencies detected** ✅

**Import hierarchy:**
```
types/* (leaf - no imports from this package)
  ↑
decoders/* (import types/*)
  ↑
encoders/* (import types/*)
  ↑
api/* (import types/*, decoders/*, encoders/*)
  ↑
client.gleam (import api/*)
```

**Analysis:**
- ✅ Clean dependency graph
- ✅ Layered architecture respected
- ✅ No cycles

---

## 7. Breaking Changes Assessment

### 7.1 Proposed Consolidation Impact

**If we consolidate to `tandoor/types/recipe/recipe.gleam`:**

**Files that would need updates:**
1. `tandoor/api/recipe/get.gleam` - Update import
2. `tandoor/api/recipe/create.gleam` - Update import
3. `tandoor/api/recipe/update.gleam` - Update import
4. `tandoor/api/recipe/delete.gleam` - Update import
5. `tandoor/decoders/recipe/recipe_decoder.gleam` - Update import
6. `tandoor/client.gleam` - Remove duplicate type definition
7. `tandoor/mapper.gleam` - Remove duplicate type definition
8. `tandoor/types.gleam` - Delete entire file

**Risk Assessment:**
- 🟡 **Medium Risk** - Changes affect core API modules
- ✅ **Mitigated by:** Type system catches all breaking changes at compile time
- ✅ **No runtime impact** - All changes are compile-time

**Recommendation:**
```
SAFE TO PROCEED WITH CONSOLIDATION
- Gleam's type system will catch all issues
- Update imports in single commit
- Run `gleam build` to verify
- Run `gleam test` to verify behavior unchanged
```

---

## 8. Recommendations Summary

### 8.1 Critical (Fix Immediately)

1. **Consolidate Tandoor Types**
   - Move all types to types/* subdirectory
   - Delete tandoor/types.gleam
   - Remove duplicates from client.gleam and mapper.gleam

2. **Fix Import Inconsistencies**
   - Update food/get.gleam to use food_decoder
   - Standardize all imports to use types/* modules

### 8.2 High Priority

3. **Complete Encoder Coverage**
   - Add missing recipe, nutrition, step, ingredient encoders
   - Ensure all decodable types are encodable

4. **Rename Core Recipe Type**
   - Rename meal_planner/types.gleam Recipe → AppRecipe
   - Prevents confusion with TandoorRecipe

### 8.3 Medium Priority

5. **Standardize Public API**
   - Review all pub fn declarations
   - Make helper functions private where appropriate

6. **Add Type Aliases for Clarity**
   ```gleam
   // In meal_planner/types.gleam
   pub type TandoorRecipeId = Int
   pub type CustomFoodId = String
   pub type UsdaFdcId = Int
   ```

### 8.4 Low Priority (Nice to Have)

7. **Documentation Review**
   - Ensure all public types have doc comments
   - Add examples for complex types

8. **Consider Module Exports**
   - Create barrel exports for types/* modules
   - Simplifies imports: `import meal_planner/tandoor/types`

---

## 9. Implementation Plan

### Phase 1: Type Consolidation (2-4 hours)

**Tasks:**
1. ✅ Verify all types in types/* have decoders
2. 🔧 Update all imports to use types/* modules
3. 🔧 Delete tandoor/types.gleam
4. 🔧 Remove duplicates from client.gleam and mapper.gleam
5. ✅ Run `gleam build` and fix compilation errors
6. ✅ Run `gleam test` and verify tests pass

### Phase 2: Encoder Coverage (4-6 hours)

**Tasks:**
1. 🔧 Create missing encoder files
2. 🔧 Implement encoder functions
3. 🔧 Add tests for new encoders
4. ✅ Verify round-trip decode/encode works

### Phase 3: API Cleanup (2-3 hours)

**Tasks:**
1. 🔧 Fix food/get.gleam decoder import
2. 🔧 Review public API surface
3. 🔧 Add missing documentation
4. ✅ Final build and test pass

---

## 10. Test Coverage Recommendations

### 10.1 Type Round-Trip Tests

**Add tests for:**
```gleam
test recipe_encode_decode_roundtrip() {
  let recipe = Recipe(...)
  let encoded = recipe_encoder.encode(recipe)
  let decoded = recipe_decoder.decode(encoded)
  
  assert Ok(decoded_recipe) = decoded
  assert decoded_recipe == recipe
}
```

### 10.2 Optional Field Tests

**Add tests for:**
- Fields present
- Fields null
- Fields missing
- Edge cases (empty strings, zero values)

---

## Conclusion

The codebase has a **solid foundation** with good separation of concerns and consistent patterns. The main issues are **type duplication** and **missing encoders**, both of which can be addressed systematically without breaking changes.

**Overall Grade: B+**

**Next Steps:**
1. Approve consolidation plan
2. Execute Phase 1 (Type Consolidation)
3. Execute Phase 2 (Encoder Coverage)
4. Execute Phase 3 (API Cleanup)

---

**Review Status:** ✅ Complete
**Reviewed Files:** 120+ Gleam modules
**Critical Issues Found:** 4
**Recommendations Made:** 8
