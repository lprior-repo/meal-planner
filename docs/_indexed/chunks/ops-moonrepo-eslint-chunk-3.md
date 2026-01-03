---
doc_id: ops/moonrepo/eslint
chunk_id: ops/moonrepo/eslint#chunk-3
heading_path: ["ESLint example", "Configuration"]
chunk_type: code
tokens: 403
summary: "Configuration"
---

## Configuration

### Root-level

The root-level ESLint config is *required*, as ESLint traverses upwards from each file to find configurations, and this denotes the stopping point. It's also used to define rules for the *entire* repository.

.eslintrc.js

```js
module.exports = {
  root: true, // Required!
  extends: ['moon'],
  rules: {
    'no-console': 'error',
  },
  // TypeScript support
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: 'tsconfig.eslint.json',
    tsconfigRootDir: __dirname,
  },
};
```

The `.eslintignore` file must also be defined at the root, as [only 1 ignore file](https://eslint.org/docs/user-guide/configuring/ignoring-code#the-eslintignore-file) can exist in a repository. We ensure this ignore file is used by passing `--ignore-path` above.

.eslintignore

```
node_modules/
*.min.js
*.map
*.snap
```

### Project-level

A project-level ESLint config can be utilized by creating a `.eslintrc.<json|js|cjs|yml>` in the project root. This is optional, but necessary when defining rules and ignore patterns unique to the project.

<project>/.eslintrc.js

```js
module.exports = {
  // Patterns to ignore (alongside the root .eslintignore)
  ignorePatterns: ['build', 'lib'],
  // Project specific rules
  rules: {
    'no-console': 'off',
  },
};
```

> The [`extends`](https://eslint.org/docs/user-guide/configuring/configuration-files#extending-configuration-files) setting should **not** extend the root-level config, as ESLint will automatically merge configs while traversing upwards!

### Sharing

To share configuration across projects, you have 3 options:

- Define settings in the [root-level config](#root-level). This only applies to the parent repository.
- Create and publish an [`eslint-config`](https://eslint.org/docs/developer-guide/shareable-configs#using-a-shareable-config) or [`eslint-plugin`](https://eslint.org/docs/developer-guide/working-with-plugins) npm package. This can be used in any repository.
- A combination of 1 and 2.

For options 2 and 3, if you're utilizing package workspaces, create a local package with the following content.

packages/eslint-config-company/index.js

```js
module.exports = {
  extends: ['airbnb'],
};
```

Within your root-level ESLint config, you can extend this package to inherit the settings.

.eslintrc.js

```js
module.exports = {
  extends: 'eslint-config-company',
};
```

> When using this approach, the package must be built and symlinked into `node_modules` *before* the linter will run correctly. Take this into account when going down this path!
