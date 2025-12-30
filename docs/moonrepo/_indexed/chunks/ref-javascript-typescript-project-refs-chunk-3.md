---
doc_id: ref/javascript/typescript-project-refs
chunk_id: ref/javascript/typescript-project-refs#chunk-3
heading_path: ["TypeScript project references", "Configuration"]
chunk_type: code
tokens: 772
summary: "Configuration"
---

## Configuration

The most complicated part of integrating TypeScript in a monorepo is a proper configuration setup. Based on our extensive experience, we suggest the following architecture as a base! This *is not* perfect and can most definitely be expanded upon or modified to fit your needs.

### Root-level

In a polyrepo, the root `tsconfig.json` is typically the only configuration file, as it defines common compiler options, and includes files to typecheck. In a monorepo, these responsibilities are now split across multiple configuration files.

#### `tsconfig.json`

To start, the root `tsconfig.json` file is nothing more than a list of *all* projects in the monorepo, with each project being an individual entry in the `references` field. Each entry must contain a `path` field with a relative file system path to the project root (that contains their config).

We also *do not* define compiler options in this file, as project-level configuration files would *not* be able to extend this file, as it would trigger a circular reference. Instead, we define common compiler options in a root [`tsconfig.options.json`](#tsconfigoptionsjson) file, that this file also `extends` from.

In the end, this file should only contain 3 fields: `extends`, `files` (an empty list), and `references`. This abides the [official guidance around structure](https://www.typescriptlang.org/docs/handbook/project-references.html#overall-structure).

```json
{
  "extends": "./tsconfig.options.json",
  "files": [],
  "references": [
    {
      "path": "apps/foo"
    },
    {
      "path": "packages/bar"
    }
    // ... more
  ]
}
```

> When using moon, the [`typescript.syncProjectReferences`](/docs/config/toolchain#syncprojectreferences) setting will keep this `references` list automatically in sync, and the name of the file can be customized with [`typescript.rootConfigFileName`](/docs/config/toolchain#rootconfigfilename).

#### `tsconfig.options.json`

This file will contain common compiler options that will be inherited by *all* projects in the monorepo. For project references to work correctly, the following settings *must* be enabled at the root, and typically should not be disabled in each project.

- `composite` - Enables project references and informs the TypeScript program where to find referenced outputs.
- `declaration` - Project references rely on the compiled declarations (`.d.ts`) of external projects. If declarations do not exist, TypeScript will generate them on demand.
- `declarationMap` - Generate sourcemaps for declarations, so that language server integrations in editors like "Go to" resolve correctly.
- `incremental` - Enables incremental compilation, greatly improving performance.
- `noEmitOnError` - If the typechecker fails, avoid generating invalid or partial declarations.
- `skipLibCheck` - Avoids eager loading and analyzing all declarations, greatly improving performance.

Furthermore, we have 2 settings that should be enabled *per project*, depending on the project type.

- `emitDeclarationOnly` - For packages: Emit declarations, as they're required for references, but avoid compiling to JavaScript.
- `noEmit` - For applications: Don't emit declarations, as others *should not* be depending on the project.

For convenience, we provide the [`tsconfig-moon`](https://github.com/moonrepo/dev/tree/master/packages/tsconfig) package, which defines common compiler options and may be used here.

```json
{
  "compilerOptions": {
    "composite": true,
    "declaration": true,
    "declarationMap": true,
    "emitDeclarationOnly": true,
    "incremental": true,
    "noEmitOnError": true,
    "skipLibCheck": true
    // ... others
  }
}
```

> When using moon, the name of the file can be customized with [`typescript.rootOptionsConfigFileName`](/docs/config/toolchain#rootoptionsconfigfilename).

#### ECMAScript interoperability

ECMAScript modules (ESM) have been around for quite a while now, but the default TypeScript settings are not configured for them. We suggest the following compiler options if you want proper ESM support with interoperability with the ecosystem.

```json
{
  "compilerOptions": {
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "isolatedModules": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "strict": true,
    "target": "esnext"
    // ... others
  }
}
```

#### `.gitignore`

Project references unfortunately generate *a ton* of artifacts that typically shouldn't be committed to the repository (but could be if you so choose). We suggest ignoring the following:

.gitignore

```
