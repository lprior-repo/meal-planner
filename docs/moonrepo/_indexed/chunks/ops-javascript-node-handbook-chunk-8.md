---
doc_id: ops/javascript/node-handbook
chunk_id: ops/javascript/node-handbook#chunk-8
heading_path: ["Node.js handbook", "Code sharing"]
chunk_type: code
tokens: 923
summary: "Code sharing"
---

## Code sharing

One of the primary reasons to use a monorepo is to easily share code between projects. When code is co-located within the same repository, it avoids the overhead of the "build -> version -> publish to registry -> upgrade in consumer" workflow (when the code is located in an external repository).

Co-locating code also provides the benefit of fast iteration, fast adoption, and easier migration (when making breaking changes for example).

With [package workspaces](#dependency-management), code sharing is a breeze. As mentioned above, every project that contains a `package.json` that is part of the workspace, will be symlinked into `node_modules`. Because of this, these packages can easily be imported using their `package.json` name.

```js
// Imports from /packages/utils/package.json
import utils from '@company/utils';
```

### Depending on packages

Because packages are symlinked into `node_modules`, we can depend on them as if they were normal npm packages, but with 1 key difference. Since these packages aren't published, they do not have a version to reference, and instead, we can use the special `workspace:^` version (yarn and pnpm only, use `*` for npm).

```json
{
  "name": "@company/consumer",
  "dependencies": {
    "@company/provider": "workspace:^"
  }
}
```

The `workspace:` version basically means "use the package found in the current workspace". The `:^` determines the version range to *substitute with when publishing*. For example, the `workspace:^` above would be replaced with version of `@company/provider` as `^<version>` when the `@company/consumer` package is published.

There's also `workspace:~` and `workspace:*` which substitutes to `~<version>` and `<version>` respectively. We suggest using `:^` so that version ranges can be deduped.

### Types of packages

When sharing packages in a monorepo, there's typically 3 different kinds of packages:

#### Local only

A local only package is just that, it's only available locally to the repository and *is not* published to a registry, and *is not* available to external repositories. For teams and companies that utilize a single repository, this will be the most common type of package.

A benefit of local packages is that they do not require a build step, as source files can be imported directly ([when configured correctly](#bundler-integration)). This avoids a lot of `package.json` overhead, especially in regards to `exports`, `imports`, and other import patterns.

#### Internally published

An internal package is published to a private registry, and *is not* available to the public. Published packages are far more strict than local packages, as the `package.json` structure plays a much larger role for downstream consumers, as it dictates how files are imported, where they can be found, what type of formats are supported (CJS, ESM), so on and so forth.

Published packages require a build step, for both source code and TypeScript types (when applicable). We suggest using [esbuild](https://esbuild.github.io/) or [Packemon](/docs/guides/examples/packemon) to handle this entire flow. With that being said, local projects can still [import their source files](#bundler-integration).

#### Externally published

An external package is structured similarly to an internal package, but instead of publishing to a private registry, it's published to the npm public registry.

External packages are primarily for open source projects, and require the repository to also be public.

### Bundler integration

Co-locating packages is great, but how do you import and use them effectively? The easiest solution is to configure resolver aliases within your bundler (Webpack, Vite, etc). By doing so, you enable the following functionality:

- Avoids having to build (and rebuild) the package everytime its code changes.
- Enables file system watching of the package, not just the application.
- Allows for hot module reloading (HMR) to work.
- Package code is transpiled and bundled alongside application code.

**Vite** - vite.config.ts

```ts
import path from 'path';
import { defineConfig } from 'vite';

export default defineConfig({
  // ...
  resolve: {
    alias: {
      '@company/utils': path.join(__dirname, '../packages/utils/src'),
    },
  },
});
```

**Webpack** - webpack.config.js

```js
const path = require('path');

module.exports = {
  // ...
  resolve: {
    alias: {
      '@company/utils': path.join(__dirname, '../packages/utils/src'),
    },
  },
};
```

info

When configuring aliases, we suggest using the `package.json` name as the alias! This ensures that on the consuming side, you're using the package as if it's a normal node module, and avoids deviating from the ecosystem.

### TypeScript integration

We suggest using TypeScript project references. Luckily, we have an [in-depth guide on how to properly and efficiently integrate them](/docs/guides/javascript/typescript-project-refs)!
