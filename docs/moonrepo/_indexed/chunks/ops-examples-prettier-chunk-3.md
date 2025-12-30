---
doc_id: ops/examples/prettier
chunk_id: ops/examples/prettier#chunk-3
heading_path: ["Prettier example", "Configuration"]
chunk_type: code
tokens: 146
summary: "Configuration"
---

## Configuration

### Root-level

The root-level Prettier config is *required*, as it defines conventions and standards to apply to the entire repository.

.prettierrc.js

```js
module.exports = {
  arrowParens: 'always',
  semi: true,
  singleQuote: true,
  tabWidth: 2,
  trailingComma: 'all',
  useTabs: true,
};
```

The `.prettierignore` file must also be defined at the root, as [only 1 ignore file](https://prettier.io/docs/en/ignore.html#ignoring-files-prettierignore) can exist in a repository. We ensure this ignore file is used by passing `--ignore-path` above.

.prettierignore

```
node_modules/
*.min.js
*.map
*.snap
```

### Project-level

We suggest *against* project-level configurations, as the entire repository should be formatted using the same standards. However, if you're migrating code and need an escape hatch, [overrides in the root](https://prettier.io/docs/en/configuration.html#configuration-overrides) will work.
