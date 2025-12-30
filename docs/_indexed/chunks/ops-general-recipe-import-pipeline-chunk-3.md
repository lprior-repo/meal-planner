---
doc_id: ops/general/recipe-import-pipeline
chunk_id: ops/general/recipe-import-pipeline#chunk-3
heading_path: ["Recipe Import Pipeline", "Architecture"]
chunk_type: prose
tokens: 145
summary: "Architecture"
---

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
