---
doc_id: ops/moonrepo/packemon
chunk_id: ops/moonrepo/packemon#chunk-1
heading_path: ["Packemon example"]
chunk_type: prose
tokens: 154
summary: "Packemon example"
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
