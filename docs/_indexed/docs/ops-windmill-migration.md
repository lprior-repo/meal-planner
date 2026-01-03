---
id: ops/windmill/migration
title: "Migration guide"
category: ops
tags: ["windmill", "migration", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Migration guide</title>
  <description>This guide helps you migrate from the previous &quot;raw requirements&quot; system to workspace dependencies. See the [main workspace dependencies guide](./index.mdx) for feature details.</description>
  <created_at>2026-01-02T19:55:27.873955</created_at>
  <updated_at>2026-01-02T19:55:27.873955</updated_at>
  <language>en</language>
  <sections count="8">
    <section name="Migration steps" level="2"/>
    <section name="1. Resolve conflicts" level="3"/>
    <section name="2. Move dependency files" level="3"/>
    <section name="3. Update scripts" level="3"/>
    <section name="4. Set defaults (optional)" level="3"/>
    <section name="5. Update CLI" level="3"/>
    <section name="6. Test" level="3"/>
    <section name="Troubleshooting" level="2"/>
  </sections>
  <features>
    <feature>1_resolve_conflicts</feature>
    <feature>2_move_dependency_files</feature>
    <feature>3_update_scripts</feature>
    <feature>4_set_defaults_optional</feature>
    <feature>5_update_cli</feature>
    <feature>6_test</feature>
    <feature>migration_steps</feature>
    <feature>troubleshooting</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="feature">meta/windmill/index-75</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./index.mdx</entity>
    <entity relationship="uses">./index.mdx</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,migration,operations</tags>
</doc_metadata>
-->

# Migration guide

> **Context**: This guide helps you migrate from the previous "raw requirements" system to workspace dependencies. See the [main workspace dependencies guide](./inde

This guide helps you migrate from the previous "raw requirements" system to workspace dependencies. See the [main workspace dependencies guide](./index.mdx) for feature details.

## Migration steps

### 1. Resolve conflicts

If you have a `/dependencies` folder at the workspace root, rename it. The workspace root `/dependencies` path is reserved for the new system.

Note: Folders like `/f/dependencies` or `/u/username/dependencies` are not affected.

### 2. Move dependency files

Move all your requirements.txt, package.json, composer.json files to the workspace `/dependencies` directory:

- `requirements.txt` → `/dependencies/<name>.requirements.in`
- `package.json` → `/dependencies/<name>.package.json`
- `composer.json` → `/dependencies/<name>.composer.json`

Choose descriptive names like `ml.requirements.in` or `api.package.json`.

### 3. Update scripts

Add annotations to scripts that should use workspace dependencies:

```python
## requirements: ml
```

```typescript
// package_json: api
```

```php
// composer_json: web
```

### 4. Set defaults (optional)

Create unnamed default files to set workspace-wide behavior:

- `/dependencies/requirements.in` - Requirements mode default

This will be referenced by all scripts unless explicitly told otherwise.
Choose one form per language.

:::important
Creation of workspace defaults will redeploy all existing runnables for given language!
:::

### 5. Update CLI

Upgrade to the latest Windmill CLI version that supports workspace dependencies.

### 6. Test

Generate lockfiles and test your scripts:

```bash
wmill script generate-metadata script_path
wmill script run script_path
```

## Troubleshooting

- **Scripts fail**: Check that dependency files contain all required packages
- **CLI errors**: Ensure you have the latest CLI version
- **Permission errors**: Workspace admin permissions required for dependency management
- **Missing dependencies**: Add missing packages to workspace dependency files

For detailed feature information, see the [workspace dependencies guide](./meta-windmill-index-75.md).


## See Also

- [main workspace dependencies guide](./index.mdx)
- [workspace dependencies guide](./index.mdx)
