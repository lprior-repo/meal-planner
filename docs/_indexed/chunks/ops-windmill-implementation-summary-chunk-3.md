---
doc_id: ops/windmill/implementation-summary
chunk_id: ops/windmill/implementation-summary#chunk-3
heading_path: ["Documentation Indexing Implementation Summary", "Key Features"]
chunk_type: code
tokens: 204
summary: "Key Features"
---

## Key Features

### DAG Layers

```text
Layer 1: Flow Control Features
    ↓
Layer 2: Core Concepts
    ↓
Layer 3: Tools & SDKs
    ↓
Layer 4: Deployment
```text

### Relationship Types

- `uses` - Feature A uses Feature B
- `can-trigger` - Feature A can trigger Feature B
- `continues-on` - Feature A continues to Feature B
- `can-break` - Feature A can break Feature B
- `related-to` - Features are conceptually related
- `deploys-to` - Tool A deploys to Feature B
- `manages` - Tool A manages Feature B
- `accesses` - Tool/SDK A accesses Feature B
- `part-of` - Feature A is part of Feature B
- `required-for` - Feature A is required for Feature B
- `enables` - Tool A enables Feature B

### XML Metadata Schema

Each document includes:

```xml
<doc_metadata>
  <type>reference|guide|tutorial</type>
  <category>flows|core_concepts|cli|sdk|deployment</category>
  <title>Document Title</title>
  <description>Brief description</description>
  <created_at>ISO-8601 timestamp</created_at>
  <updated_at>ISO-8601 timestamp</updated_at>
  <language>en</language>
  <sections count="N">...</sections>
  <features>...</features>
  <dependencies>...</dependencies>
  <examples count="N">...</examples>
  <difficulty_level>beginner|intermediate|advanced</difficulty_level>
  <estimated_reading_time>minutes</estimated_reading_time>
  <tags>tag1,tag2,tag3</tags>
</doc_metadata>
```text
