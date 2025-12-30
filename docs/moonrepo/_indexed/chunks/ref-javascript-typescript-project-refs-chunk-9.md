---
doc_id: ref/javascript/typescript-project-refs
chunk_id: ref/javascript/typescript-project-refs#chunk-9
heading_path: ["TypeScript project references", "Supporting `package.json` exports"]
chunk_type: code
tokens: 720
summary: "Supporting `package.json` exports"
---

## Supporting `package.json` exports

In Node.js v12, they introduced a new field to `package.json` called `exports` that aims to solve the shortcomings of the `main` field. The `exports` field is very complicated, and instead of repeating all of its implementation details, we suggest reading [the official Node.js docs on this topic](https://nodejs.org/api/packages.html#package-entry-points).

With that being said, TypeScript completely ignored the `exports` field until [v4.7](https://devblogs.microsoft.com/typescript/announcing-typescript-4-7/#esm-nodejs), and respecting `exports` is *still ignored unless* the `moduleResolution` compiler option is set to "nodenext", "node16", or "bundler". If `moduleResolution` is set to "node", then your integration is resolving based on the `main` and `types` field, which are basically "legacy".

warning

Enabling `package.json` imports/exports resolution is very complicated, and may be very tedious, especially considering the state of the npm ecosystem. Proceed with caution!

### State of the npm ecosystem

As mentioned above, the npm ecosystem (as of November 2022) is in a very fragile state in regards to imports/exports. Based on our experience attempting to utilize them in a monorepo, we ran into an array of problems, some of which are:

- Published packages are simply utilizing imports/exports incorrectly. The semantics around CJS/ESM are very strict, and they may be configured wrong. This is exacerbated by the new `type` field.
- The `exports` field *overrides* the `main` and `types` fields. If `exports` exists without type conditions, but the `types` field exists, the `types` entry point is completely ignored, resulting in TypeScript failures.

With that being said, there are [ways around this](#resolving-issues) and moving forward is possible, if you dare!

### Enabling imports/exports resolution

To start, set the `moduleResolution` compiler option to "nodenext" (for packages) or "bundler" (for apps) in the [`tsconfig.options.json`](#tsconfigoptionsjson) file.

```json
{
  "compilerOptions": {
    // ...
    "moduleResolution": "nodenext"
  }
}
```

Next, [run the typechecker from the root](#on-all-projects) against all projects. This will help uncover all potential issues with the dependencies you're using or the current configuration architecture. If no errors are found, well *congratulations*, otherwise jump to the next section for more information on [resolving them](#resolving-issues).

If you're trying to use `exports` in your own packages, ensure that the `types` condition is set, and it's the first condition in the mapping! We also suggest including `main` and the top-level `types` for tooling that do not support `exports` yet.

package.json

```json
{
  // ...
  "main": "./lib/index.js",
  "types": "./lib/index.d.ts",
  "exports": {
    "./package.json": "./package.json",
    ".": {
      "types": "./lib/index.d.ts",
      "node": "./lib/index.js"
    }
  }
}
```

info

Managing `exports` is non-trivial. If you'd prefer them to be automatically generated based on a set of inputs, we suggest using [Packemon](https://packemon.dev/)!

### Resolving issues

There's only one way to resolve issues around incorrectly published `exports`, and that is package patching, either with [Yarn's patching feature](https://yarnpkg.com/features/protocols/#patch), [pnpm's patching feature](https://pnpm.io/cli/patch), or the [`patch-package` package](https://www.npmjs.com/package/patch-package). With patching, you can:

- Inject the `types` condition/field if it's missing.
- Re-structure the `exports` mapping if it's incorrect.
- Fix incorrect entry point paths.
- And even fix invalid TypeScript declarations or JavaScript code!

package.json

```diff
{
  "main": "./lib/index.js",
  "types": "./lib/index.d.ts",
  "exports": {
    "./package.json": "./package.json",
-    ".": "./lib/index.js"
+    ".": {
+      "types": "./lib/index.d.ts",
+      "node": "./lib/index.js"
+    }
  }
}
```

info

More often than not, the owners of these packages may be unaware that their `exports` mapping is incorrect. Why not be a good member of the community and report an issue or even submit a pull request?
