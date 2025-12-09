# Mealie Full Functionality Research

## Executive Summary

Mealie is a comprehensive recipe manager and meal planning system with 413 Python files across FastAPI backend + Vue.js frontend. This research identifies what functionality we can ruthlessly leverage vs. what to keep in Gleam backend.

## Full Feature Inventory

### 🔥 Core Features (Ruthlessly Use from Mealie)

#### 1. Recipe Management (`mealie/routes/recipe/`, `mealie/schema/recipe/`)
**Files**: 413 Python files, key: `recipe_crud_routes.py` (24KB), `recipe.py` schema

**Endpoints**:
- `GET /api/recipes` - List/search recipes with pagination
- `POST /api/recipes` - Create recipe
- `GET /api/recipes/{slug}` - Get recipe by ID/slug
- `PUT /api/recipes/{slug}` - Update recipe
- `PATCH /api/recipes/{slug}` - Partial update
- `DELETE /api/recipes/{slug}` - Delete recipe
- `POST /api/recipes/duplicate` - Duplicate recipe
- `POST /api/recipes/bulk` - Bulk operations
- `GET /api/recipes/suggest` - AI recipe suggestions (uses OpenAI)

**Data Model** (`schema/recipe/recipe.py:178`):
```python
class Recipe(RecipeSummary):
    id: UUID4
    name: str
    slug: str
    description: str
    recipe_ingredient: list[RecipeIngredient]
    recipe_instructions: list[RecipeStep]
    nutrition: Nutrition
    recipe_category: list[RecipeCategory]
    tags: list[RecipeTag]
    tools: list[RecipeTool]
    rating: float
    prep_time: str
    cook_time: str
    total_time: str
    recipe_servings: float
    recipe_yield: str
    image: Any
    assets: list[RecipeAsset]
    notes: list[RecipeNote]
    comments: list[RecipeComment]
    settings: RecipeSettings
```

**Verdict**: ✅ **RUTHLESSLY USE** - Mealie's recipe CRUD is production-ready with full UI support

---

#### 2. Recipe Scraping (`mealie/services/scraper/`)
**Files**: `recipe_scraper.py`, `scraper_strategies.py`

**Capabilities**:
- **RecipeScraperPackage**: Uses `recipe-scrapers` library (supports 100+ websites)
- **RecipeScraperOpenAI**: AI-powered scraping via OpenAI GPT
- **RecipeScraperOpenGraph**: Fallback using Open Graph metadata
- URL scraping with automatic ingredient/instruction extraction
- Image scraping and storage
- Bulk URL import

**Endpoints**:
- `POST /api/recipes/create-url` - Scrape single URL
- `POST /api/recipes/create-url/bulk` - Scrape multiple URLs
- `POST /api/recipes/test-scrape-url` - Test scraping

**Verdict**: ✅ **RUTHLESSLY USE** - World-class scraping infrastructure, no need to rebuild

---

#### 3. Ingredient Parser (`mealie/services/parser_services/`)
**Files**: `ingredient_parser.py`, uses `ingredient-parser-nlp` library

**Capabilities**:
- NLP-based ingredient parsing (ingredient-parser-nlp v2.4.0)
- Brute force parser fallback
- OpenAI parser for complex ingredients
- Extracts: quantity, unit, food item, notes
- Confidence scoring for parsed results

**Endpoints**:
- `POST /api/parser/ingredient` - Parse ingredient string

**Example**:
```python
Input: "2 cups chopped fresh basil"
Output: {
    quantity: 2.0,
    unit: "cup",
    food: "basil",
    note: "chopped fresh"
}
```

**Verdict**: ✅ **RUTHLESSLY USE** - Production NLP parser, don't rebuild

---

#### 4. Meal Planning (`mealie/routes/households/controller_mealplan.py`)
**Files**: `controller_mealplan.py`, `schema/meal_plan/`

**Data Model** (`schema/meal_plan/new_meal.py`):
```python
class PlanEntry:
    date: date
    entry_type: PlanEntryType  # breakfast, lunch, dinner, snack
    title: str
    text: str
    recipe_id: UUID4
```

**Endpoints**:
- `GET /api/households/mealplans` - List meal plans (date range filter)
- `POST /api/households/mealplans` - Create meal plan entry
- `PUT /api/households/mealplans/{id}` - Update entry
- `DELETE /api/households/mealplans/{id}` - Delete entry
- `POST /api/households/mealplans/random` - Generate random meal plan

**Meal Plan Rules** (`controller_mealplan_rules.py`):
- Day-based rules (Monday breakfast: filter by tag "quick")
- Category filters
- Tag filters
- Random recipe selection based on rules

**Verdict**: ⚠️ **PARTIALLY USE** - Use UI + storage, but enhance with Gleam AI planning

---

#### 5. Shopping Lists (`mealie/routes/households/controller_shopping_lists.py`)
**Files**: `controller_shopping_lists.py` (12KB)

**Capabilities**:
- Create/manage shopping lists
- Add items manually or from recipes
- Organize by supermarket sections
- Check off items
- Multiple lists per household
- Recipe scale support (adjust quantities)

**Endpoints**:
- `GET /api/households/shopping/lists` - List all shopping lists
- `POST /api/households/shopping/lists` - Create list
- `PUT /api/households/shopping/lists/{id}` - Update list
- `POST /api/households/shopping/lists/{id}/recipe/{recipe_id}` - Add recipe to list

**Verdict**: ✅ **RUTHLESSLY USE** - Complete shopping list system

---

#### 6. Nutrition Data (`schema/recipe/recipe_nutrition.py`)
**Data Model**:
```python
class Nutrition:
    calories: str
    carbohydrate_content: str
    cholesterol_content: str
    fat_content: str
    fiber_content: str
    protein_content: str
    saturated_fat_content: str
    sodium_content: str
    sugar_content: str
    trans_fat_content: str
    unsaturated_fat_content: str
```

**Verdict**: ⚠️ **PARTIALLY USE** - Store nutrition in Mealie, but calculate macros in Gleam

---

#### 7. User Management & Authentication
**Routes**: `mealie/routes/users/`, `mealie/routes/auth/`

**Capabilities**:
- User registration/login
- JWT token authentication
- Password reset
- LDAP integration
- OpenID Connect (OIDC)
- User profiles
- Household/group management

**Verdict**: ✅ **RUTHLESSLY USE** - Complete auth system

---

#### 8. Cookbooks (`mealie/routes/households/controller_cookbooks.py`)
**Capabilities**:
- Group recipes into cookbooks
- Share cookbooks
- Export cookbooks

**Verdict**: ✅ **RUTHLESSLY USE** - Good organizational feature

---

#### 9. Recipe Timeline & Comments
**Files**: `recipe_timeline_events.py`, `recipe_comments.py`

**Capabilities**:
- Track recipe changes over time
- Add comments/ratings to recipes
- Photo timeline (e.g., "I made this on 2024-01-15")

**Verdict**: ✅ **RUTHLESSLY USE** - Nice social features

---

#### 10. Import/Export (`mealie/services/exporter/`)
**Capabilities**:
- Export recipes as JSON, ZIP
- Import from Mealie ZIP format
- Backup/restore functionality

**Verdict**: ✅ **RUTHLESSLY USE** - Production backup system

---

#### 11. OpenAI Integration (`mealie/services/openai/`)
**Files**: `openai/` directory with prompts

**Capabilities**:
- Recipe scraping via GPT
- Ingredient parsing via GPT
- Recipe suggestions

**Verdict**: ✅ **RUTHLESSLY USE** - Already integrated

---

### ⚡ What Gleam Backend Should Provide

Based on research, Gleam should focus on **AI intelligence** that Mealie doesn't have:

#### 1. **Advanced AI Meal Planning** (Gleam Priority)
Mealie has basic random selection + rules. Gleam provides:
- Multi-objective optimization (macros + variety + diet compliance)
- NCP (Normalized Cumulative Percentage) algorithms
- Recipe scoring with exponential decay matching
- Vertical Diet compliance checking
- Macro target optimization across multiple meals

**Integration Point**: `POST /api/ai/meal-plan`

---

#### 2. **Recipe Macro Scoring** (Gleam Priority)
Mealie stores nutrition as strings. Gleam calculates:
- Precise macro calculations (protein/fat/carbs)
- Recipe scoring against targets
- Macro match scoring (0-1 scale)
- Deviation analysis

**Integration Point**: `POST /api/ai/score-recipe`

---

#### 3. **Diet Compliance Engine** (Gleam Priority)
Mealie has tags. Gleam provides:
- Vertical Diet validation
- FODMAP level checking
- Diet principle enforcement
- Compliance scoring

**Integration Point**: `GET /api/diet/vertical/compliance/{recipe_id}`

---

#### 4. **Advanced Macro Math** (Gleam Priority)
Mealie doesn't calculate portions. Gleam provides:
- `quantity.gleam` - Quantity parsing and conversion
- `portion.gleam` - Portion calculations
- `ncp.gleam` - Normalized cumulative percentage
- `nutrient_parser.gleam` - USDA data parsing

**Integration Point**: `POST /api/macros/calculate`

---

## Architecture Decision

### What to Use from Mealie (Ruthlessly)

| Feature | Use Mealie | Reason |
|---------|-----------|--------|
| Recipe CRUD UI | ✅ Yes | Production Vue.js UI with 35+ translations |
| Recipe Storage | ✅ Yes | PostgreSQL schema battle-tested |
| Recipe Scraping | ✅ Yes | Supports 100+ websites + OpenAI |
| Ingredient Parsing | ✅ Yes | NLP library with confidence scoring |
| Shopping Lists | ✅ Yes | Complete feature with supermarket sections |
| User Auth | ✅ Yes | JWT + LDAP + OIDC |
| Meal Plan Storage | ✅ Yes | Database schema for meal plans |
| Meal Plan UI | ✅ Yes | Calendar interface |
| Cookbooks | ✅ Yes | Good organizational feature |
| Comments/Ratings | ✅ Yes | Social features |
| Import/Export | ✅ Yes | Backup system |

### What Gleam Provides (Unique Value)

| Feature | Gleam Backend | Reason |
|---------|---------------|--------|
| AI Meal Planning | ✅ Yes | Multi-objective optimization Mealie doesn't have |
| Macro Optimization | ✅ Yes | Precise calculations beyond Mealie's string storage |
| Recipe Scoring | ✅ Yes | AI-based scoring algorithms |
| Diet Compliance | ✅ Yes | Vertical Diet + FODMAP validation |
| NCP Algorithms | ✅ Yes | Advanced nutritional calculations |
| Portion Math | ✅ Yes | Conversion and scaling logic |

---

## Integration Strategy

### Data Flow

```
User → Mealie UI → Mealie API → Gleam API → Mealie API → Response
  1. User clicks "Generate AI Meal Plan"
  2. Mealie frontend calls Mealie backend
  3. Mealie backend calls Gleam AI endpoint
  4. Gleam fetches recipes from Mealie API
  5. Gleam runs AI planning algorithms
  6. Gleam returns scored recipes
  7. Mealie saves meal plan
  8. User sees results in Mealie UI
```

### API Boundaries

**Mealie Owns**:
- `/api/recipes/*` - All recipe CRUD
- `/api/households/mealplans/*` - Meal plan storage
- `/api/households/shopping/*` - Shopping lists
- `/api/users/*` - User management
- `/api/parser/*` - Ingredient parsing

**Gleam Owns**:
- `/api/ai/meal-plan` - AI planning algorithm
- `/api/ai/score-recipe` - Recipe scoring
- `/api/diet/vertical/compliance/*` - Diet validation
- `/api/macros/calculate` - Macro calculations

---

## Code Locations Reference

### Recipe Schema
- `mealie-app/mealie/schema/recipe/recipe.py:178` - Main Recipe class
- `mealie-app/mealie/schema/recipe/recipe_ingredient.py` - Ingredient models
- `mealie-app/mealie/schema/recipe/recipe_nutrition.py` - Nutrition model

### Recipe CRUD
- `mealie-app/mealie/routes/recipe/recipe_crud_routes.py` - All CRUD endpoints

### Meal Planning
- `mealie-app/mealie/routes/households/controller_mealplan.py` - Meal plan controller
- `mealie-app/mealie/schema/meal_plan/new_meal.py` - Meal plan models

### Shopping Lists
- `mealie-app/mealie/routes/households/controller_shopping_lists.py` - Shopping API

### Scraping
- `mealie-app/mealie/services/scraper/recipe_scraper.py` - Scraper service

### Ingredient Parser
- `mealie-app/mealie/services/parser_services/ingredient_parser.py` - Parser service

---

## Dependencies to Leverage

### External Libraries Mealie Uses (We Get for Free)
- `recipe-scrapers==15.10.0` - Web scraping for 100+ sites
- `ingredient-parser-nlp==2.4.0` - NLP ingredient parsing
- `openai==2.9.0` - GPT integration
- `FastAPI==0.124.0` - API framework
- `SQLAlchemy==2.0.44` - ORM
- `Pydantic==2.12.5` - Data validation

---

## Constraints Discovered

### Rate Limits
- OpenAI scraping: Subject to OpenAI API rate limits
- Recipe scraping: Respectful delays to avoid being blocked

### Database
- Mealie uses `mealie` schema in PostgreSQL
- Gleam uses `public` schema
- No conflicts, clean separation

### Authentication
- Mealie uses JWT tokens
- Gleam endpoints will need to validate Mealie's JWT

---

## Recommended Approach

### Phase 1: Basic Integration
1. Run Mealie on port 9000 with PostgreSQL
2. Create Gleam HTTP server on port 8080
3. Implement Gleam → Mealie API client (fetch recipes)
4. Test basic data flow

### Phase 2: AI Endpoints
1. Implement `POST /api/ai/meal-plan` in Gleam
2. Use existing `auto_planner` + `ncp_auto_planner` modules
3. Fetch recipes from Mealie API
4. Return scored meal plan

### Phase 3: Mealie Frontend Integration
1. Add "AI Meal Plan" button to Mealie UI
2. Button calls Gleam API via Mealie backend proxy
3. Display results in Mealie's meal plan calendar

---

## Conclusion

**Ruthlessly use from Mealie**:
- Recipe management (CRUD + scraping)
- Ingredient parsing
- Shopping lists
- User authentication
- Meal plan storage + UI
- All frontend components

**Keep in Gleam**:
- AI meal planning algorithms
- Macro optimization
- Recipe scoring
- Diet compliance validation
- Advanced nutritional calculations

**Result**: Gleam provides the "brain" (AI planning), Mealie provides the "body" (UI + storage).
