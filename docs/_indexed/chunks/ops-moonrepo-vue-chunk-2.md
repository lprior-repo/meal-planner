---
doc_id: ops/moonrepo/vue
chunk_id: ops/moonrepo/vue#chunk-2
heading_path: ["Vue example", "Setup"]
chunk_type: code
tokens: 293
summary: "Setup"
---

## Setup

This section assumes Vue is being used with Vite.

### ESLint integration

When linting with [ESLint](/docs/guides/examples/eslint) and the [`eslint-plugin-vue`](https://eslint.vuejs.org/user-guide/#installation) library, you'll need to include the `.vue` extension within the `lint` task. This can be done by extending the top-level task within the project (below), or by adding it to the top-level entirely.

<project>/moon.yml

```yaml
tasks:
  lint:
    args:
      - '--ext'
      - '.js,.ts,.vue'
```

Furthermore, when using TypeScript within ESLint, we need to make a few additional changes to the `.eslintrc.js` config found in the root (if the entire repo is Vue), or within the project (if only the project is Vue).

```js
module.exports = {
  parser: 'vue-eslint-parser',
  parserOptions: {
    extraFileExtensions: ['.vue'],
    parser: '@typescript-eslint/parser',
    project: 'tsconfig.json', // Or another config
    tsconfigRootDir: __dirname,
  },
};
```

### TypeScript integration

Vue does not use [TypeScript](/docs/guides/examples/typescript)'s `tsc` binary directly, but instead uses [`vue-tsc`](https://vuejs.org/guide/typescript/overview.html), which is a thin wrapper around `tsc` to support Vue components. Because of this, we should update the `typecheck` task in the project to utilize this command instead.

<project>/moon.yml

```yaml
workspace:
  inheritedTasks:
    exclude: ['typecheck']

tasks:
  typecheck:
    command:
      - 'vue-tsc'
      - '--noEmit'
      # Always use pretty output
      - '--pretty'
    inputs:
      - 'env.d.ts'
      # Source and test files
      - 'src/**/*'
      - 'tests/**/*'
      # Project configs
      - 'tsconfig.json'
      - 'tsconfig.*.json'
      # Root configs (extended from only)
      - '/tsconfig.options.json'
```

> Be sure `tsconfig.json` compiler options are based on [`@vue/tsconfig`](https://vuejs.org/guide/typescript/overview.html#configuring-tsconfig-json).
