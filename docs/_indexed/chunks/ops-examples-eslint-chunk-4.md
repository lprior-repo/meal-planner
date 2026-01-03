---
doc_id: ops/examples/eslint
chunk_id: ops/examples/eslint#chunk-4
heading_path: ["ESLint example", "FAQ"]
chunk_type: prose
tokens: 219
summary: "FAQ"
---

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
