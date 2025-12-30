---
doc_id: ops/examples/typescript
chunk_id: ops/examples/typescript#chunk-1
heading_path: ["TypeScript example"]
chunk_type: prose
tokens: 104
summary: "TypeScript example"
---

# TypeScript example

> **Context**: In this guide, you'll learn how to integrate [TypeScript](https://www.typescriptlang.org/) into moon. We'll be using [project references](/docs/guides

In this guide, you'll learn how to integrate [TypeScript](https://www.typescriptlang.org/) into moon. We'll be using [project references](/docs/guides/javascript/typescript-project-refs), as it ensures that only affected projects are built, and not the entire repository.

Begin by installing `typescript` and any pre-configured tsconfig packages in your root. We suggest using the same version across the entire repository.

```
yarn add --dev typescript tsconfig-moon
```
