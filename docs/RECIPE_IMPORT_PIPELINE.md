# Recipe Import Pipeline

**Status**: Planned

Automated recipe import: scrape → enrich with nutrition → store in Tandoor.

**For both humans and AI agents**: Links throughout help you navigate to related docs for deeper context.

## Architecture

Windmill flow composes small binaries (CUPID principles):

```
windmill flow
├── tandoor_scrape_recipe    → recipe JSON
├── tandoor_create_recipe    → recipe_id
├── fatsecret_enrich_nutrition → nutrition, tags
└── tandoor_update_keywords  → success
```

Each binary: JSON in → JSON out, ~50 lines, does one thing.

See: [ARCHITECTURE.md](ARCHITECTURE.md)

## Binaries (Phase 1)

| Binary | Input | Output |
|--------|-------|--------|
| `tandoor_scrape_recipe` | `{tandoor, url}` | `{recipe_json, images}` |
| `tandoor_create_recipe` | `{tandoor, recipe, keywords}` | `{recipe_id, name}` |

## Binaries (Phase 2)

| Binary | Input | Output |
|--------|-------|--------|
| `fatsecret_enrich_nutrition` | `{fatsecret, ingredients}` | `{nutrition, auto_tags}` |
| `tandoor_update_keywords` | `{tandoor, recipe_id, keywords}` | `{success}` |

## Example: `tandoor_scrape_recipe`

**Input**:
```json
{
  "tandoor": {"base_url": "http://localhost:8090", "api_token": "..."},
  "url": "https://www.meatchurch.com/blogs/recipes/texas-style-brisket"
}
```

**Output**:
```json
{
  "success": true,
  "recipe_json": {
    "name": "Texas Style Brisket",
    "source_url": "...",
    "servings": 8,
    "working_time": 30,
    "waiting_time": 720,
    "steps": [...],
    "keywords": [...]
  },
  "images": ["https://..."]
}
```

## Flow Steps

1. **Scrape**: Extract recipe from URL
2. **Create**: Store in Tandoor, get recipe_id
3. **Enrich**: Look up nutrition for each ingredient
4. **Tag**: Auto-tag based on ingredients and nutrition

## Error Handling

- Invalid URL → fail step, log, continue
- API timeout → retry with backoff
- Missing nutrition → warn, use defaults
- Duplicate recipe → skip, log

## Testing

```bash
moon run :test     # Unit tests for each binary
wmill flow run ... # Integration test on Windmill
```

See: [MOON_CI_PIPELINE.md](MOON_CI_PIPELINE.md) for build/test commands
