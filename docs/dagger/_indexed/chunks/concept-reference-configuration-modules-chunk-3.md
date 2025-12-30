---
doc_id: concept/reference/configuration-modules
chunk_id: concept/reference/configuration-modules#chunk-3
heading_path: ["configuration-modules", "TypeScript Configuration"]
chunk_type: code
tokens: 155
summary: "TypeScript-specific SDK settings can be configured using `package."
---
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
