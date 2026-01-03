---
id: concept/general/recipe-import-pipeline
title: "Recipe Import Pipeline"
category: concept
tags: ["tandoor", "concept", "recipe"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>core</category>
  <title>Recipe Import Pipeline</title>
  <description>Automated recipe import: scrape → enrich with nutrition → store in Tandoor.</description>
  <created_at>2026-01-02T19:55:26.826014</created_at>
  <updated_at>2026-01-02T19:55:26.826014</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Architecture" level="2"/>
    <section name="Binaries (Phase 1)" level="2"/>
    <section name="Binaries (Phase 2)" level="2"/>
    <section name="Example: `tandoor_scrape_recipe`" level="2"/>
    <section name="Flow Steps" level="2"/>
    <section name="Error Handling" level="2"/>
    <section name="Testing" level="2"/>
  </sections>
  <features>
    <feature>architecture</feature>
    <feature>binaries_phase_1</feature>
    <feature>binaries_phase_2</feature>
    <feature>error_handling</feature>
    <feature>example_tandoor_scrape_recipe</feature>
    <feature>flow_steps</feature>
    <feature>testing</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="feature">ops/general/architecture</dependency>
    <dependency type="feature">ops/general/moon-ci-pipeline</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">ARCHITECTURE.md</entity>
    <entity relationship="uses">MOON_CI_PIPELINE.md</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>tandoor,concept,recipe</tags>
</doc_metadata>
-->

# Recipe Import Pipeline

> **Context**: Automated recipe import: scrape → enrich with nutrition → store in Tandoor.

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

See: [ARCHITECTURE.md](./ops-general-architecture.md)

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

See: [MOON_CI_PIPELINE.md](./ops-general-moon-ci-pipeline.md) for build/test commands


## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [MOON_CI_PIPELINE.md](MOON_CI_PIPELINE.md)
