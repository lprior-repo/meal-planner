---
doc_id: ops/moonrepo/astro
chunk_id: ops/moonrepo/astro#chunk-5
heading_path: ["Astro example", "Disable project references"]
chunk_type: code
tokens: 408
summary: "Disable project references"
---

## Disable project references
toolchain:
  typescript:
    syncProjectReferences: false
```

### ESLint integration

When using a [`lint`](/docs/guides/examples/eslint) task, the [`eslint-plugin-astro`](https://ota-meshi.github.io/eslint-plugin-astro/user-guide/) package must be installed to lint `.astro` files.

```
yarn workspace <app> add --dev eslint-plugin-astro
```

Once the dependency has been installed in the application's `package.json`. We can then enable this configuration by creating an `.eslintrc.js` file in the project root. Be sure this file is listed in your lint task's inputs!

<project>/.eslintrc.js

```js
module.exports = {
  extends: ['plugin:astro/recommended'],
  overrides: [
    {
      files: ['*.astro'],
      parser: 'astro-eslint-parser',
      // If using TypeScript
      parserOptions: {
        parser: '@typescript-eslint/parser',
        extraFileExtensions: ['.astro'],
        project: 'tsconfig.json',
        tsconfigRootDir: __dirname,
      },
    },
  ],
};
```

And lastly, when linting through moon's command line, you'll need to include the `.astro` extension within the `lint` task. This can be done by extending the top-level task within the project (below), or by adding it to the top-level entirely.

<project>/moon.yml

```yaml
tasks:
  lint:
    args:
      - '--ext'
      - '.ts,.tsx,.astro'
```

### Prettier integration

When using a [`format`](/docs/guides/examples/prettier) task, the `prettier-plugin-astro` package must be installed to format `.astro` files. View the official [Astro docs](https://docs.astro.build/en/editor-setup/#prettier) for more information.

```
yarn workspace <app> add --dev prettier-plugin-astro
```

### TypeScript integration

Since Astro utilizes custom `.astro` files, it requires a specialized TypeScript integration, and luckily Astro provides an [in-depth guide](https://docs.astro.build/en/guides/typescript/). With that being said, we do have a few requirements and pointers!

- Use the official [Astro `tsconfig.json`](https://docs.astro.build/en/guides/typescript/#setup) as a basis.
- From our internal testing, the `astro check` command (that typechecks `.astro` files) *does not support project references*. If the `composite` compiler option is enabled, the checker will fail to find `.astro` files. To work around this, we disable `workspace.typescript` in our moon config above.
- Since typechecking requires 2 commands, one for `.astro` files, and the other for `.ts`, `.tsx` files, we've added the [`typecheck`](/docs/guides/examples/typescript) task as a dependency for the `check` task. This will run both commands through a single task!
