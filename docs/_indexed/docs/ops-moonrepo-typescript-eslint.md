---
id: ops/moonrepo/typescript-eslint
title: "typescript-eslint"
category: ops
tags: ["typescript", "typescripteslint", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>typescript-eslint</title>
  <description>A handful of ESLint rules are not compatible with the TypeScript plugin, or they cause serious performance degradation, and should be disabled entirely. According to the [official typescript-eslint.io</description>
  <created_at>2026-01-02T19:55:27.149639</created_at>
  <updated_at>2026-01-02T19:55:27.149639</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="ESLint integration" level="2"/>
    <section name="Disabling problematic rules" level="3"/>
    <section name="Running from the command line" level="3"/>
    <section name="Running within editors" level="3"/>
    <section name="ESLint" level="4"/>
    <section name="Prettier" level="4"/>
  </sections>
  <features>
    <feature>disabling_problematic_rules</feature>
    <feature>eslint</feature>
    <feature>eslint_integration</feature>
    <feature>prettier</feature>
    <feature>running_from_the_command_line</feature>
    <feature>running_within_editors</feature>
  </features>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>typescript,typescripteslint,operations,moonrepo</tags>
</doc_metadata>
-->

# typescript-eslint

> **Context**: A handful of ESLint rules are not compatible with the TypeScript plugin, or they cause serious performance degradation, and should be disabled entirel

## ESLint integration

### Disabling problematic rules

A handful of ESLint rules are not compatible with the TypeScript plugin, or they cause serious performance degradation, and should be disabled entirely. According to the [official typescript-eslint.io documentation](https://typescript-eslint.io/docs/linting/troubleshooting#eslint-plugin-import), most of these rules come from the `eslint-plugin-import` plugin.

.eslintrc.js

```js
module.exports = {
  // ...
  rules: {
    'import/default': 'off',
    'import/named': 'off',
    'import/namespace': 'off',
    'import/no-cycle': 'off',
    'import/no-deprecated': 'off',
    'import/no-named-as-default': 'off',
    'import/no-named-as-default-member': 'off',
    'import/no-unused-modules': 'off',
  },
};
```

### Running from the command line

### Running within editors

#### ESLint

Use the [dbaeumer.vscode-eslint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) extension. Too avoid poor performance, *do not* use ESLint for formatting code (via the `eslint-plugin-prettier` plugin or something similar), and *only* use it for linting. The difference in speed is comparable to 100ms vs 2000ms.

.vscode/settings.json

```json
{
  // Automatically run all linting fixes on save as a concurrent code action,
  // and avoid formatting with ESLint. Use another formatter, like Prettier.
  "editor.codeActionsOnSave": ["source.fixAll.eslint"],
  "eslint.format.enable": false,

  // If linting is *too slow* while typing, uncomment the following line to
  // only run the linter on save only.
  // "editor.run": "onSave",

  // Your package manager of choice.
  "eslint.packageManager": "yarn",

  // Use the newer and more performant `ESLint` class implementation.
  "eslint.useESLintClass": true,

  // List of directories that that linter should operate on.
  "eslint.workingDirectories": [{ "pattern": "apps/*" }, { "pattern": "packages/*" }]
}
```

#### Prettier

Use the [esbenp.prettier-vscode](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) extension.

.vscode/settings.json

```json
{
  // Use Prettier as the default formatter for all file types. Types not
  // supported by Prettier can be overridden using bracket syntax, or ignore files.
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true
}
```


## See Also

- [Documentation Index](./COMPASS.md)
