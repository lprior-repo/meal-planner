---
doc_id: tutorial/moonrepo/next
chunk_id: tutorial/moonrepo/next#chunk-4
heading_path: ["Next example", "https://github.com/moonrepo/moon-configs"]
chunk_type: code
tokens: 497
summary: "https://github.com/moonrepo/moon-configs"
---

## https://github.com/moonrepo/moon-configs
tags: ['next']
```

### ESLint integration

Next.js has [built-in support for ESLint](https://nextjs.org/docs/basic-features/eslint), which is great, but complicates things a bit. Because of this, you have two options for moving forward:

- Use a [global `lint` task](/docs/guides/examples/eslint) and bypass Next.js's solution (preferred).
- Use Next.js's solution only.

Regardless of which option is chosen, the following changes are applicable to all options and should be made. Begin be installing the [`eslint-config-next`](https://nextjs.org/docs/basic-features/eslint#eslint-config) dependency in the application's `package.json`.

```
yarn workspace <project> add --dev eslint-config-next
```

Since the Next.js app is located within a subfolder, we'll need to tell the ESLint plugin where to locate it. This can be achieved with a project-level `.eslintrc.js` file.

<project>/.eslintrc.js

```js
module.exports = {
  extends: 'next', // or 'next/core-web-vitals'
  settings: {
    next: {
      rootDir: __dirname,
    },
  },
};
```

**Global lint approach:**

We encourage using the global `lint` task for consistency across all projects within the repository. With this approach, the `eslint` command itself will be ran and the `next lint` command will be ignored, but the `eslint-config-next` rules will still be used.

Additionally, we suggest disabling the linter during the build process, but is not a requirement. As a potential alternative, add the `lint` task as a dependency for the `build` task.

<project>/next.config.js

```js
module.exports = {
  eslint: {
    ignoreDuringBuilds: true,
  },
};
```

**Next.js lint approach:**

If you'd prefer to use the `next lint` command, add it as a task to the project's [`moon.yml`](/docs/config/project).

<project>/moon.yml

```yaml
tasks:
  lint:
    command: 'next lint'
    inputs:
      - '@group(next)'
```

Furthermore, if a global `lint` task exists, be sure to exclude it from being inherited.

<project>/moon.yml

```yaml
workspace:
  inheritedTasks:
    exclude: ['lint']
```

### TypeScript integration

Next.js also has [built-in support for TypeScript](https://nextjs.org/docs/basic-features/typescript), but has similar caveats to the [ESLint integration](#eslint-integration). TypeScript itself is a bit involved, so we suggest reading the official Next.js documentation before continuing.

At this point we'll assume that a `tsconfig.json` has been created in the application, and typechecking works. From here we suggest utilizing a [global `typecheck` task](/docs/guides/examples/typescript) for consistency across all projects within the repository.

Additionally, we suggest disabling the typechecker during the build process, but is not a requirement. As a potential alternative, add the `typecheck` task as a dependency for the `build` task.

<project>/next.config.js

```js
module.exports = {
  typescript: {
    ignoreBuildErrors: true,
  },
};
```
