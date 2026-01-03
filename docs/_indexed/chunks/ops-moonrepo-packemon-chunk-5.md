---
doc_id: ops/moonrepo/packemon
chunk_id: ops/moonrepo/packemon#chunk-5
heading_path: ["Packemon example", "Set the output formats"]
chunk_type: code
tokens: 161
summary: "Set the output formats"
---

## Set the output formats
tasks:
  build:
    outputs:
      - 'cjs'
```

### TypeScript integration

Packemon has built-in support for TypeScript, but to *not* conflict with a [typecheck task](/docs/guides/examples/typescript), a separate `tsconfig.json` file is required, which is named `tsconfig.<format>.json`.

This config is necessary to *only* compile source files, and to not include unwanted files in the declaration output directory.

tsconfig.esm.json

```json
{
  "extends": "../../tsconfig.options.json",
  "compilerOptions": {
    "outDir": "esm",
    "rootDir": "src"
  },
  "include": ["src/**/*"],
  "references": []
}
```

### Build targets

To configure the target platform(s) and format(s), you must define a [`packemon` block](https://packemon.dev/docs/config) in the project's `package.json`. The chosen formats must also be listed as `outputs` in the task.

package.json

```json
{
  "name": "package",
  // ...
  "packemon": {
    "format": "esm",
    "platform": "browser"
  }
}
```
