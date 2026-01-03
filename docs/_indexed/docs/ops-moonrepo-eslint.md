---
id: ops/moonrepo/eslint
title: "ESLint example"
category: ops
tags: ["eslint", "advanced", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>ESLint example</title>
  <description>In this guide, you&apos;ll learn how to integrate [ESLint](https://eslint.org/) into moon.</description>
  <created_at>2026-01-02T19:55:27.090026</created_at>
  <updated_at>2026-01-02T19:55:27.090026</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Setup" level="2"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
    <section name="Sharing" level="3"/>
    <section name="FAQ" level="2"/>
    <section name="How to lint a single file or folder?" level="3"/>
    <section name="Should we use `overrides`?" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>how_to_lint_a_single_file_or_folder</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>sharing</feature>
    <feature>should_we_use_overrides</feature>
    <feature>typescript_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="11">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>eslint,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# ESLint example

> **Context**: In this guide, you'll learn how to integrate [ESLint](https://eslint.org/) into moon.

In this guide, you'll learn how to integrate [ESLint](https://eslint.org/) into moon.

Begin by installing `eslint` and any plugins in your root. We suggest using the same version across the entire repository.

```
yarn add --dev eslint eslint-config-moon
```

## Setup

Since linting is a universal workflow, add a `lint` task to [`.moon/tasks/node.yml`](/docs/config/tasks) with the following parameters.

.moon/tasks/node.yml

```yaml
tasks:
  lint:
    command:
      - 'eslint'
      # Support other extensions
      - '--ext'
      - '.js,.jsx,.ts,.tsx'
      # Always fix and run extra checks
      - '--fix'
      - '--report-unused-disable-directives'
      # Dont fail if a project has nothing to lint
      - '--no-error-on-unmatched-pattern'
      # Do fail if we encounter a fatal error
      - '--exit-on-fatal-error'
      # Only 1 ignore file is supported, so use the root
      - '--ignore-path'
      - '@in(4)'
      # Run in current dir
      - '.'
    inputs:
      # Source and test files
      - 'src/**/*'
      - 'tests/**/*'
      # Other config files
      - '*.config.*'
      # Project configs, any format, any depth
      - '**/.eslintrc.*'
      # Root configs, any format
      - '/.eslintignore'
      - '/.eslintrc.*'
```

Projects can extend this task and provide additional parameters if need be, for example.

<project>/moon.yml

```yaml
tasks:
  lint:
    args:
      # Enable caching for this project
      - '--cache'
```

### TypeScript integration

If you're using the [`@typescript-eslint`](https://typescript-eslint.io) packages, and want to enable type-safety based lint rules, we suggest something similar to the official [monorepo configuration](https://typescript-eslint.io/docs/linting/monorepo).

Create a `tsconfig.eslint.json` in your repository root, extend your shared compiler options (we use [`tsconfig.options.json`](/docs/guides/examples/typescript)), and include all your project files.

tsconfig.eslint.json

```json
{
  "extends": "./tsconfig.options.json",
  "compilerOptions": {
    "emitDeclarationOnly": false,
    "noEmit": true
  },
  "include": ["apps/**/*", "packages/**/*"]
}
```

Append the following inputs to your `lint` task.

.moon/tasks/node.yml

```yaml
tasks:
  lint:
    # ...
    inputs:
      # TypeScript support
      - 'types/**/*'
      - 'tsconfig.json'
      - '/tsconfig.eslint.json'
      - '/tsconfig.options.json'
```

And lastly, add `parserOptions` to your [root-level config](#root-level).

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

## FAQ

### How to lint a single file or folder?

Unfortunately, this isn't currently possible, as the `eslint` binary itself requires a file or folder path to operate on, and in the task above we pass `.` (current directory). If this was not passed, then nothing would be linted.

This has the unintended side-effect of not being able to filter down lintable targets by passing arbitrary file paths. This is something we hope to resolve in the future.

To work around this limitation, you can create another lint task.

### Should we use `overrides`?

Projects should define their own rules using an ESLint config in their project root. However, if you want to avoid touching many ESLint configs (think migrations), then [overrides in the root](https://eslint.org/docs/user-guide/configuring/configuration-files#configuration-based-on-glob-patterns) are a viable option. Otherwise, we highly encourage project-level configs.

.eslintrc.js

```js
module.exports = {
  // ...
  overrides: [
    // Only apply to apps "foo" and "bar", but not others
    {
      files: ['apps/foo/**/*', 'apps/bar/**/*'],
      rules: {
        'no-magic-numbers': 'off',
      },
    },
  ],
};
```


## See Also

- [`.moon/tasks/node.yml`](/docs/config/tasks)
- [`tsconfig.options.json`](/docs/guides/examples/typescript)
- [root-level config](#root-level)
- [root-level config](#root-level)
