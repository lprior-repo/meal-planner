---
id: concept/reference/configuration-modules
title: "Module Configuration"
category: concept
tags: ["file", "ci", "module", "sdk", "concept"]
---

# Module Configuration

> **Context**: Modules can be configured by editing their `dagger.json` file. The configuration contains all module metadata - from the name and SDK to dependencies.


Modules can be configured by editing their `dagger.json` file. The configuration contains all module metadata - from the name and SDK to dependencies.

## File and Directory Filters

The `dagger.json` supports an `include` field to specify additional files to include or exclude when loading the module.

```json
{
  "include": ["!.venv", "!node_modules"]
}
```

## TypeScript Configuration

TypeScript-specific SDK settings can be configured using `package.json`.

### Alternative Runtimes

Supported runtimes: Node.js (default), Bun, Deno

**Node.js:**
```json
{
  "dagger": {
    "runtime": "node@20.15.0"
  }
}
```

**Bun:**
```json
{
  "dagger": {
    "runtime": "bun@1.0.11"
  }
}
```

**Deno:** Detected automatically if `deno.json` is present.

### Alternative Package Managers

Supported: npm, yarn, pnpm, bun

```json
{
  "packageManager": "pnpm@9.9"
}
```

### Alternative Base Images

```json
{
  "dagger": {
    "baseImage": "node:23.2.0-alpine@sha256:..."
  }
}
```

### Bundled vs Vendored SDK

By default, the SDK is installed as a bundled local dependency. To use vendored SDK:

```bash
rm -rf ./sdk
npm pkg set "dependencies[@dagger.io/dagger]=./sdk"
dagger develop
```

To revert to bundled SDK:

```bash
rm -rf ./sdk
npm pkg delete "dependencies[@dagger.io/dagger]"
dagger develop
```

## See Also

- [Documentation Overview](./COMPASS.md)
