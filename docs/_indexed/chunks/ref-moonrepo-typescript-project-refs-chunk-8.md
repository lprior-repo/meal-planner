---
doc_id: ref/moonrepo/typescript-project-refs
chunk_id: ref/moonrepo/typescript-project-refs#chunk-8
heading_path: ["TypeScript project references", "Sharing and augmenting types"]
chunk_type: prose
tokens: 180
summary: "Sharing and augmenting types"
---

## Sharing and augmenting types

Declaring global types, augmenting node modules, and sharing reusable types is a common practice. There are many ways to achieve this, so choose what works best for your repository. We use the following pattern with great success.

At the root of the repository, create a `types` folder as a sibling to `tsconfig.json`. This folder *must only* contain declarations (`.d.ts`) files for the following reasons:

- Declarations can be `include`ed in a project without having to be a project reference.
- Hard-coded declarations *do not* need to be compiled from TypeScript files.

Based on the above, update your project's `tsconfig.json` to include all of these types, or just some of these types.

<project>/tsconfig.json

```json
{
  // ...
  "include": ["src/**/*", "../../../../types/**/*"]
}
```

> In the future, moon will provide a setting to automate this workflow!
