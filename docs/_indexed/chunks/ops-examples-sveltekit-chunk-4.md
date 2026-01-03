---
doc_id: ops/examples/sveltekit
chunk_id: ops/examples/sveltekit#chunk-4
heading_path: ["SvelteKit example", "https://github.com/moonrepo/moon-configs"]
chunk_type: code
tokens: 352
summary: "https://github.com/moonrepo/moon-configs"
---

## https://github.com/moonrepo/moon-configs
tags: ['sveltekit']
```

### ESLint integration

SvelteKit provides an option to setup ESLint along with your project, with moon you can use a [global `lint` task](/docs/guides/examples/eslint). We encourage using the global `lint` task for consistency across all projects within the repository. With this approach, the `eslint` command itself will be ran and the `svelte3` rules will still be used.

<project>/moon.yml

```yaml
tasks:
  # Extends the top-level lint
  lint:
    args:
      - '--ext'
      - '.ts,.svelte'
```

Be sure to enable the Svelte parser and plugin in a project local ESLint configuration file.

.eslintrc.cjs

```js
module.exports = {
  plugins: ['svelte3'],
  ignorePatterns: ['*.cjs'],
  settings: {
    'svelte3/typescript': () => require('typescript'),
  },
  overrides: [{ files: ['*.svelte'], processor: 'svelte3/svelte3' }],
};
```

### TypeScript integration

SvelteKit also has built-in support for TypeScript, but has similar caveats to the [ESLint integration](#eslint-integration). TypeScript itself is a bit involved, so we suggest reading the official [SvelteKit documentation](https://kit.svelte.dev/docs/introduction) before continuing.

At this point we'll assume that a `tsconfig.json` has been created in the application, and typechecking works. From here we suggest utilizing a [global `typecheck` task](/docs/guides/examples/typescript) for consistency across all projects within the repository. However, because Svelte isn't standard JavaScript, it requires the use of the `svelte-check` command for type-checking.

info

The [moon configuration preset](https://github.com/moonrepo/moon-configs/tree/master/javascript/sveltekit) provides the `check` task below.

<project>/moon.yml

```yaml
workspace:
  inheritedTasks:
    exclude: ['typecheck']

tasks:
  check:
    command: 'svelte-check --tsconfig ./tsconfig.json'
    deps:
      - 'typecheck-sync'
    inputs:
      - '@group(svelte)'
      - 'tsconfig.json'
```

In case Svelte doesn't automatically create a `tsconfig.json`, you can use the following:

<project>/tsconfig.json

```json
{
  "extends": "./.svelte-kit/tsconfig.json",
  "compilerOptions": {
    "allowJs": true,
    "checkJs": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "sourceMap": true,
    "strict": true
  }
}
```
