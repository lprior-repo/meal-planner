---
doc_id: ops/examples/jest
chunk_id: ops/examples/jest#chunk-3
heading_path: ["Jest example", "Configuration"]
chunk_type: code
tokens: 202
summary: "Configuration"
---

## Configuration

### Root-level

A root-level Jest config is not required and should be avoided, instead, use a [preset](#sharing) to share configuration.

### Project-level

A project-level Jest config can be utilized by creating a `jest.config.<js|ts|cjs|mjs>` in the project root. This is optional, but necessary when defining project specific settings.

<project>/jest.config.js

```js
module.exports = {
  // Project specific settings
  testEnvironment: 'node',
};
```

### Sharing

To share configuration across projects, you can utilize Jest's built-in [`preset`](https://jestjs.io/docs/configuration#preset-string) functionality. If you're utilizing package workspaces, create a local package with the following content, otherwise publish the npm package for consumption.

packages/company-jest-preset/jest-preset.js

```js
module.exports = {
  testEnvironment: 'jsdom',
  watchman: true,
};
```

Within your project-level Jest config, you can extend the preset to inherit the settings.

<project>/jest.config.js

```js
module.exports = {
  preset: 'company-jest-preset',
};
```

> You can take this a step further by passing the `--preset` option in the [task above](#setup), so that all projects inherit the preset by default.
