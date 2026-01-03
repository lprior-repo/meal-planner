---
doc_id: ref/moonrepo/typescript-project-refs
chunk_id: ref/moonrepo/typescript-project-refs#chunk-7
heading_path: ["TypeScript project references", "Using `paths` aliases"]
chunk_type: code
tokens: 497
summary: "Using `paths` aliases"
---

## Using `paths` aliases

Path aliases, also known as path mapping or magic imports, is the concept of defining an import alias that re-maps its underlying location on the file system. In TypeScript, this is achieved with the [`paths` compiler option](https://www.typescriptlang.org/docs/handbook/module-resolution.html#path-mapping).

In a monorepo world, we suggest using path aliases on a per-project basis, instead of defining them "globally" in the root. This gives projects full control of what's available and what they want to import, and also plays nice with the mandatory `baseUrl` compiler option.

<project>/tsconfig.json

```json
{
  // ...
  "compilerOptions": {
    // ...
    "baseUrl": ".",
    "paths": {
      // Within the project
      ":components/*": ["./src/components/*"],
      // To a referenced project
      ":shared/*": ["../../shared/code/*"]
    }
  },
  "references": [
    {
      "path": "../../shared/code"
    }
  ]
}
```

The above aliases would be imported like the following:

```ts
// Before
import { Button } from '../../../../components/Button';
import utils from '../../shared/code/utils';

// After
import { Button } from ':components/Button';
import utils from ':shared/utils';
```

info

When using path aliases, we suggest prefixing or suffixing the alias with `:` so that it's apparent that it's an alias (this also matches the new `node:` import syntax). Using no special character or `@` is problematic as it risks a chance of collision with a public npm package and may accidentally open your repository to a [supply chain attack](https://snyk.io/blog/npm-security-preventing-supply-chain-attacks/). Other characters like `~` and `$` have an existing meaning in the ecosystem, so it's best to avoid them aswell.

### Importing source files from local packages

If you are importing from a project reference using a `package.json` name, then TypeScript will abide by Node.js module resolution logic, and will import using the [`main`/`types` or `exports` entry points](https://nodejs.org/api/packages.html#package-entry-points). This means that you're importing *compiled code* instead of source code, and will require the package to be constantly rebuilt if changes are made to it.

However, why not simply import source files instead? With path aliases, you can do just that, by defining a `paths` alias that maps the `package.json` name to its source files, like so.

<project>/tsconfig.json

```json
{
  // ...
  "compilerOptions": {
    // ...
    "paths": {
      // Index import
      "@scope/name": ["../../shared/package/src/index.ts"],
      // Deep imports
      "@scope/name/*": ["../../shared/package/src/*"]
    }
  },
  "references": [
    {
      "path": "../../shared/package"
    }
  ]
}
```

> When using moon, the [`typescript.syncProjectReferencesToPaths`](/docs/config/toolchain#syncprojectreferencestopaths) setting will automatically create `paths` based on the local references.
