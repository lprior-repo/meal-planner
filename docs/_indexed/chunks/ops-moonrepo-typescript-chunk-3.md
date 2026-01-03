---
doc_id: ops/moonrepo/typescript
chunk_id: ops/moonrepo/typescript#chunk-3
heading_path: ["TypeScript example", "Configuration"]
chunk_type: code
tokens: 422
summary: "Configuration"
---

## Configuration

### Root-level

Multiple root-level TypeScript configs are *required*, as we need to define compiler options that are shared across the repository, and we need to house a list of all project references.

To start, let's create a `tsconfig.options.json` that will contain our compiler options. In our example, we'll extend [tsconfig-moon](https://www.npmjs.com/package/tsconfig-moon) for convenience. Specifically, the `tsconfig.workspaces.json` config, which enables ECMAScript modules, composite mode, declaration emitting, and incremental builds.

tsconfig.options.json

```json
{
  "extends": "tsconfig-moon/tsconfig.projects.json",
  "compilerOptions": {
    // Your custom options
    "moduleResolution": "nodenext",
    "target": "es2022"
  }
}
```

We'll also need the standard `tsconfig.json` to house our project references. This is used by editors and tooling for deep integrations.

tsconfig.json

```json
{
  "extends": "./tsconfig.options.json",
  "files": [],
  // All project references in the repo
  "references": []
}
```

> The [`typescript.rootConfigFileName`](/docs/config/toolchain#rootconfigfilename) setting can be used to change the root-level config name and the [`typescript.syncProjectReferences`](/docs/config/toolchain#syncprojectreferences) setting will automatically keep project references in sync!

### Project-level

Every project will require a `tsconfig.json`, as TypeScript itself requires it. The following `tsconfig.json` will typecheck the entire project, including source and test files.

<project>/tsconfig.json

```json
{
  // Extend the root compiler options
  "extends": "../../tsconfig.options.json",
  "compilerOptions": {
    // Declarations are written here
    "outDir": "lib"
  },
  // Include files in the project
  "include": ["src/**/*", "tests/**/*"],
  // Depends on other projects
  "references": []
}
```

> The [`typescript.projectConfigFileName`](/docs/config/toolchain#projectconfigfilename) setting can be used to change the project-level config name.

### Sharing

To share configuration across projects, you have 3 options:

- Define settings in a [root-level config](#root-level). This only applies to the parent repository.
- Create and publish an [`tsconfig base`](https://www.typescriptlang.org/docs/handbook/tsconfig-json.html#tsconfig-bases) npm package. This can be used in any repository.
- A combination of 1 and 2.

For options 2 and 3, if you're utilizing package workspaces, create a local package with the following content.

packages/tsconfig-company/tsconfig.json

```json
{
  "compilerOptions": {
    // ...
    "lib": ["esnext"]
  }
}
```

Within another `tsconfig.json`, you can extend this package to inherit the settings.

tsconfig.json

```json
{
  "extends": "tsconfig-company/tsconfig.json"
}
```
