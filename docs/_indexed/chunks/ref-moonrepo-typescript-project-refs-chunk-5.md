---
doc_id: ref/moonrepo/typescript-project-refs
chunk_id: ref/moonrepo/typescript-project-refs#chunk-5
heading_path: ["TypeScript project references", "Build cache manifests"]
chunk_type: code
tokens: 1041
summary: "Build cache manifests"
---

## Build cache manifests
*.tsbuildinfo
```

### Project-level

Each project that contains TypeScript files and will utilize the typechecker *must* contain a `tsconfig.json` in the project root, typically as a sibling to `package.json`.

#### `tsconfig.json`

A `tsconfig.json` in the root of a project (application or package) is required, as it informs TypeScript that this is a project, and that it can be referenced by other projects. In its simplest form, this file should extend the root [`tsconfig.options.json`](#tsconfigoptionsjson) to inherit common compiler options, define its own compiler options (below), define includes/excludes, and any necessary references.

> When using moon, the name of the file can be customized with [`typescript.projectConfigFileName`](/docs/config/toolchain#projectconfigfilename).

**For Applications:**

For applications, declaration emitting can be disabled, since external projects *should not* be importing files from an application. If this use case ever arises, move those files into a package.

apps/foo/tsconfig.json

```json
{
  "extends": "../../../../tsconfig.options.json",
  "compilerOptions": {
    "noEmit": true
  },
  "include": [],
  "references": []
}
```

**For Packages:**

For packages, we must define the location in which to generate declarations. These are the declarations that external projects would reference. This location is typically [gitignored](#gitignore)!

packages/bar/tsconfig.json

```json
{
  "extends": "../../../../tsconfig.options.json",
  "compilerOptions": {
    "emitDeclarationOnly": true,
    "outDir": "./lib"
  },
  "include": [],
  "references": []
}
```

> When using moon, the `outDir` can automatically be re-routed to a shared cache using [`typescript.routeOutDirToCache`](/docs/config/toolchain#routeoutdirtocache), to avoid littering the repository with compilation artifacts.

#### Includes and excludes

Based on experience, we suggest defining `include` instead of `exclude`, as managing a whitelist of typecheckable files is much easier. When dealing with excludes, there are far too many possibilities. To start, you have `node_modules`, and for applications maybe `dist`, `build`, `.next`, or another application specific folder, and then for packages you may have `lib`, `cjs`, `esm`, etc. It becomes very... tedious.

The other benefit of using `include` is that it forces TypeScript to only load *what's necessary*, instead of eager loading everything into memory, and for typechecking files that aren't part of source, like configuration.

<project>/tsconfig.json

```json
{
  // ...
  "include": ["src/**/*", "tests/**/*", "*.js", "*.ts"]
}
```

#### Depending on other projects

When a project depends on another project (by importing code from it), either using relative paths, [path aliases](#using-paths-aliases), or its `package.json` name, it must be declared as a reference. If not declared, TypeScript will error with a message about importing outside the project boundary.

<project>/tsconfig.json

```json
{
  // ...
  "references": [
    {
      "path": "../../foo"
    },
    {
      "path": "../../bar"
    },
    {
      "path": "../../../../baz"
    }
  ]
}
```

To make use of editor intellisense and auto-imports of deeply nested files, you'll most likely need to add includes for referenced projects as well.

<project>/tsconfig.json

```json
{
  // ...
  "include": [
    // ...
    "src/**/*",
    "../../foo/src/**/*",
    "../../bar/src/**/*",
    "../../../../baz/src/**/*"
  ]
}
```

> When using moon, the [`typescript.syncProjectReferences`](/docs/config/toolchain#syncprojectreferences) setting will keep this `references` list automatically in sync, and [`typescript.includeProjectReferenceSources`](/docs/config/toolchain#syncprojectreferences) for `include`.

#### `tsconfig.*.json`

Additional configurations may exist in a project that serve a role outside of typechecking, with one such role being *npm package publishing*. These configs are sometimes named `tsconfig.build.json`, `tsconfig.types.json`, or `tsconfig.lib.json`. Regardless of what they're called, these configs are *optional*, so unless you have a business need for them, you may skip this section.

#### Package publishing

As mentioned previously, these configs may be used for npm packages, primarily for generating TypeScript declarations that are mapped through the `package.json` [`types` (or `typings`) field](https://www.typescriptlang.org/docs/handbook/declaration-files/publishing.html).

Given this `package.json`...

<project>/package.json

```json
{
  // ...
  "types": "./lib/index.d.ts"
}
```

Our `tsconfig.build.json` may look like...

<project>/tsconfig.build.json

```json
{
  "extends": "../../../../tsconfig.options.json",
  "compilerOptions": {
    "outDir": "lib",
    "rootDir": "src"
  },
  "include": ["src/**/*"]
}
```

Simple right? But why do we need an additional configuration? Why not use the other `tsconfig.json`? Great questions! The major reason is that we *only want to publish declarations for source files*, and the declarations file structure should match 1:1 with the sources structure. The `tsconfig.json` *does not* guarantee this, as it may include test, config, or arbitrary files, all of which may not exist in the sources directory (`src`), and will alter the output to an incorrect directory structure. Our `tsconfig.build.json` solves this problem by only including source files, and by forcing the source root to `src` using the `rootDir` compiler option.

However, there is a giant caveat with this approach! Because TypeScript utilizes Node.js's module resolution, it will reference the declarations defined by the `package.json` `types` or [`exports`](#supporting-packagejson-exports) fields, instead of the `outDir` compiler option, and the other `tsconfig.json` *does not guarantee* these files will exist. This results in TypeScript failing to find the appropriate types! To solve this, add the `tsconfig.build.json` as a project reference to `tsconfig.json`.

<project>/tsconfig.json

```json
{
  // ...
  "references": [
    {
      "path": "./tsconfig.build.json"
    }
    // ... others
  ]
}
```

#### Vendor specific

Some vendors, like [Vite](/docs/guides/examples/vite), [Vitest](/docs/guides/examples/vite), and [Astro](/docs/guides/examples/astro) may include additional `tsconfig.*.json` files unique to their ecosystem. We suggest following their guidelines and implementation when applicable.
