---
id: ops/general/recipe-import-pipeline
title: "Recipe Import Pipeline"
category: ops
tags: ["recipe", "operations", "advanced"]
---

# Recipe Import Pipeline

> **Context**: **Status:** Planned **Last Updated:** 2025-12-30

**Status:** Planned  
**Last Updated:** 2025-12-30

## Overview

Automated recipe import pipeline that scrapes recipes from URLs, enriches with nutrition data, and stores in Tandoor with auto-tagging.

## Architecture

Following CUPID principles: small, single-purpose binaries composed via Windmill flows.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          WINDMILL FLOW                                       │
│                    (Orchestration + Error Handling)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│   │  tandoor_   │    │  tandoor_   │    │  fatsecret_ │    │  tandoor_   │ │
│   │  scrape_    │───▶│  create_    │───▶│  enrich_    │───▶│  update_    │ │
│   │  recipe     │    │  recipe     │    │  nutrition  │    │  keywords   │ │
│   └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │
│                                                                              │
│   JSON in → out      JSON in → out      JSON in → out      JSON in → out   │
│   ~50 lines          ~50 lines          ~50 lines          ~50 lines        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```text

## Binaries

### Phase 1 (Core Import)

| Binary | Purpose | Input | Output |
|--------|---------|-------|--------|
| `tandoor_scrape_recipe` | Scrape recipe from URL via Tandoor API | `{tandoor, url}` | `{recipe_json, images}` |
| `tandoor_create_recipe` | Create recipe in Tandoor from scraped data | `{tandoor, recipe, keywords}` | `{recipe_id, name}` |

### Phase 2 (Nutrition Enrichment)

| Binary | Purpose | Input | Output |
|--------|---------|-------|--------|
| `fatsecret_enrich_nutrition` | Look up nutrition for ingredients | `{fatsecret, ingredients}` | `{nutrition, auto_tags}` |
| `tandoor_update_keywords` | Add keywords to existing recipe | `{tandoor, recipe_id, keywords}` | `{success}` |

## Binary Specifications

### `tandoor_scrape_recipe`

**Purpose:** Scrape recipe data from URL using Tandoor's built-in scraper.

**Input:**
```json
{
  "tandoor": {
    "base_url": "http://localhost:8090",
    "api_token": "..."
  },
  "url": "https://www.meatchurch.com/blogs/recipes/texas-style-brisket"
}
```text

**Output (success):**
```json
{
  "success": true,
  "recipe_json": {
    "name": "Texas Style Brisket",
    "description": "...",
    "source_url": "https://...",
    "servings": 8,
    "working_time": 30,
    "waiting_time": 720,
    "steps": [...],
    "keywords": [...]
  },
  "images": ["https://..."]
}
```text

**Output (error):**
```json
{
  "success": false,
  "error": "Failed to scrape recipe: site not supported"
}
```text

**API Call:** `POST /api/recipe-from-source/`

### `tandoor_create_recipe`

**Purpose:** Create a recipe in Tandoor from scraped/provided data.

**Input:**
```json
{
  "tandoor": {
    "base_url": "http://localhost:8090",
    "api_token": "..."
  },
  "recipe": {
    "name": "Texas Style Brisket",
    "description": "...",
    "source_url": "https://...",
    "steps": [...],
    "keywords": [...]
  },
  "additional_keywords": ["smoking", "meat-church", "beef"]
}
```text

**Output (success):**
```json
{
  "success": true,
  "recipe_id": 123,
  "name": "Texas Style Brisket"
}
```text

**API Call:** `POST /api/recipe/`

### `fatsecret_enrich_nutrition` (Phase 2)

**Purpose:** Look up nutrition data for recipe ingredients.

**Input:**
```json
{
  "fatsecret": {
    "consumer_key": "...",
    "consumer_secret": "..."
  },
  "ingredients": [
    {"food": "brisket", "amount": 1, "unit": "lb"},
    {"food": "black pepper", "amount": 2, "unit": "tbsp"}
  ],
  "servings": 8
}
```text

**Output:**
```json
{
  "success": true,
  "per_serving": {
    "calories": 450,
    "protein": 45,
    "carbohydrate": 2,
    "fat": 28
  },
  "auto_tags": ["high-protein", "low-carb"]
}
```text

**Auto-tag Rules:**
- `>30g protein/serving` → `high-protein`
- `<20g carbs/serving` → `low-carb`
- `<10g fat/serving` → `low-fat`
- `>500 cal/serving` → `high-calorie`

## Windmill Flows

### Phase 1: Basic Import

```yaml
## f/tandoor/import_recipe.flow/flow.yaml
summary: Import recipe from URL with auto-tagging
description: |
  Scrapes a recipe from a URL using Tandoor's built-in scraper,
  adds source-based and user-provided keywords, and creates
  the recipe in Tandoor.

input_schema:
  type: object
  properties:
    url:
      type: string
      description: Recipe URL to import
    additional_keywords:
      type: array
      items:
        type: string
      description: Additional keywords to add
  required:
    - url

steps:
  - id: scrape
    summary: Scrape recipe from URL
    script: f/tandoor/scrape_recipe
    input:
      tandoor: $res:u/admin/tandoor
      url: ${flow_input.url}
      
  - id: derive_source_tag
    summary: Extract source tag from URL domain
    script: inline
    lang: python
    code: |
      from urllib.parse import urlparse
      domain = urlparse(flow_input["url"]).netloc
      # meatchurch.com -> meat-church
      # seriouseats.com -> serious-eats
      return domain.replace("www.", "").replace(".com", "").replace(".", "-")
      
  - id: create
    summary: Create recipe in Tandoor
    script: f/tandoor/create_recipe
    input:
      tandoor: $res:u/admin/tandoor
      recipe: ${steps.scrape.result.recipe_json}
      additional_keywords: 
        - ${steps.derive_source_tag.result}
        - ${flow_input.additional_keywords}
```python

### Phase 2: Enriched Import (with Nutrition)

```yaml
## f/tandoor/import_recipe_enriched.flow/flow.yaml
summary: Import recipe with nutrition enrichment

steps:
  - id: scrape
    script: f/tandoor/scrape_recipe
    
  - id: enrich
    summary: Look up nutrition data
    script: f/fatsecret/enrich_nutrition
    input:
      fatsecret: $res:u/admin/fatsecret
      ingredients: ${steps.scrape.result.recipe_json.steps[0].ingredients}
      servings: ${steps.scrape.result.recipe_json.servings}
      
  - id: create
    script: f/tandoor/create_recipe
    input:
      recipe: ${steps.scrape.result.recipe_json}
      additional_keywords:
        - ${steps.derive_source_tag.result}
        - ${steps.enrich.result.auto_tags}
        - ${flow_input.additional_keywords}
```python

### Batch Import Flow

```yaml
## f/tandoor/batch_import_recipes.flow/flow.yaml
summary: Import multiple recipes from URL list

input_schema:
  type: object
  properties:
    urls:
      type: array
      items:
        type: string
    common_keywords:
      type: array
      items:
        type: string

steps:
  - id: import_all
    summary: Import each URL
    for_loop:
      iterator: ${flow_input.urls}
      script: f/tandoor/import_recipe
      input:
        url: ${iter.value}
        additional_keywords: ${flow_input.common_keywords}
        
  - id: summarize
    summary: Generate import report
    script: inline
    lang: python
    code: |
      results = steps["import_all"]["result"]
      succeeded = [r for r in results if r.get("success")]
      failed = [r for r in results if not r.get("success")]
      return {
        "total": len(results),
        "succeeded": len(succeeded),
        "failed": len(failed),
        "recipes": [{"id": r["recipe_id"], "name": r["name"]} for r in succeeded],
        "errors": [{"url": r.get("url"), "error": r.get("error")} for r in failed]
      }
```text

## Files to Create

| File | Purpose |
|------|---------|
| `src/bin/tandoor_scrape_recipe.rs` | Binary: scrape recipe from URL |
| `src/bin/tandoor_create_recipe.rs` | Binary: create recipe in Tandoor |
| `windmill/f/tandoor/scrape_recipe.rs` | Windmill script (alternative) |
| `windmill/f/tandoor/scrape_recipe.script.yaml` | Windmill script metadata |
| `windmill/f/tandoor/create_recipe.rs` | Windmill script (alternative) |
| `windmill/f/tandoor/create_recipe.script.yaml` | Windmill script metadata |
| `windmill/f/tandoor/import_recipe.flow/flow.yaml` | Windmill flow |

## Open Questions

### 1. Windmill Script vs Binary

**Option A: Windmill Scripts (current pattern)**
- Self-contained Rust with inline `cargo` deps
- Compiled by Windmill on first run
- Example: `windmill/f/tandoor/test_connection.rs`

**Option B: Compiled Binaries**
- Built via Dagger, deployed to worker container
- Called from Windmill bash scripts
- More control, faster execution

**Recommendation:** Start with Windmill scripts (simpler), migrate to binaries if performance matters.

### 2. Keyword Handling

Tandoor keywords must exist before assigning to recipes. Options:

**Option A: Create-if-missing (simpler)**
- Binary checks if keyword exists, creates if not
- Single API call pattern

**Option B: Separate step (more CUPID)**
- `tandoor_ensure_keywords` binary creates missing keywords
- `tandoor_create_recipe` assumes keywords exist

**Recommendation:** Option A for simplicity.

### 3. Auto-Tagging Rules

Source-based tagging from URL domain:
```text
meatchurch.com → meat-church
seriouseats.com → serious-eats
bonappetit.com → bon-appetit
```

Content-based tagging (future):
- Parse instructions for keywords: "smoker", "grill", "slow cooker"
- Tag accordingly: `#smoking`, `#grilling`, `#slow-cooker`

### 4. Error Handling

If scraping succeeds but creation fails:
- **Fail fast:** Return error, require re-scrape
- **Partial success:** Return scraped data for manual retry

**Recommendation:** Fail fast. Scraping is idempotent.

## Test Recipes (Meat Church)

URLs ready for testing:

| Recipe | URL |
|--------|-----|
| Texas Style Brisket | `https://www.meatchurch.com/blogs/recipes/texas-style-brisket` |
| Brisket Flat | `https://www.meatchurch.com/blogs/recipes/brisket-flat` |
| Smoked Pulled Ham | `https://www.meatchurch.com/blogs/recipes/smoked-pulled-ham` |
| Eye of Round | `https://www.meatchurch.com/blogs/recipes/eye-of-round` |
| Beef Back Ribs | `https://www.meatchurch.com/blogs/recipes/beef-back-ribs` |
| Texas Style Spare Ribs | `https://www.meatchurch.com/blogs/recipes/texas-style-spare-ribs` |
| Baby Back Ribs | `https://www.meatchurch.com/blogs/recipes/baby-back-ribs` |
| Honey Hog Spatchcock Turkey | `https://www.meatchurch.com/blogs/recipes/honey-hog-spatchcock-turkey` |
| Maple Bourbon Turkey | `https://www.meatchurch.com/blogs/recipes/maple-burbon-turkey` |
| Mexican Brisket | `https://www.meatchurch.com/blogs/recipes/mexican-brisket` |

## Implementation Order

1. **Phase 1a:** `tandoor_scrape_recipe` binary/script
2. **Phase 1b:** `tandoor_create_recipe` binary/script
3. **Phase 1c:** `import_recipe` flow
4. **Phase 1d:** Test with Meat Church URLs
5. **Phase 2a:** `fatsecret_enrich_nutrition` binary
6. **Phase 2b:** `import_recipe_enriched` flow
7. **Phase 3:** `batch_import_recipes` flow

## Related Documents

- [Architecture](./ops-general-architecture.md) - CUPID principles, binary contract
- [FatSecret SDK](../src/README.md) - Nutrition API integration
- [Windmill Development](./ops-windmill-development-guide.md) - Script/flow patterns


## See Also

- [Architecture](./ARCHITECTURE.md)
- [FatSecret SDK](../src/README.md)
- [Windmill Development](./windmill/DEVELOPMENT_GUIDE.md)
