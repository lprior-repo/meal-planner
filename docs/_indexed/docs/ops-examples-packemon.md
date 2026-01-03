---
id: ops/examples/packemon
title: "Packemon example"
category: ops
tags: ["operations", "packemon", "examples"]
---

# Packemon example

> **Context**: In this guide, you'll learn how to integrate [Packemon](https://packemon.dev/) into moon. Packemon is a tool for properly building npm packages for di

In this guide, you'll learn how to integrate [Packemon](https://packemon.dev/) into moon. Packemon is a tool for properly building npm packages for distribution, it does this by providing the following functionality:

- Compiles source code to popular formats: CJS, MJS, ESM, UMD, etc.
- Validates the `package.json` for incorrect fields or values.
- Generates `exports` mappings for `package.json` based on the define configuration.
- And many more [optimizations and features](https://packemon.dev/docs/features)!

Begin by installing `packemon` in your root. We suggest using the same version across the entire repository.

```
yarn add --dev packemon
```

## Setup

Since Packemon is per-project, the associated moon tasks should be defined in each project's [`moon.yml`](/docs/config/project) file.

tip

We suggest inheriting Packemon tasks from the [official moon configuration preset](https://github.com/moonrepo/moon-configs/tree/master/javascript/packemon).

<project>/moon.yml

```yaml
## Inherit tasks from the `packemon` preset
## https://github.com/moonrepo/moon-configs
tags: ['packemon']

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


## See Also

- [`moon.yml`](/docs/config/project)
- [typecheck task](/docs/guides/examples/typescript)
