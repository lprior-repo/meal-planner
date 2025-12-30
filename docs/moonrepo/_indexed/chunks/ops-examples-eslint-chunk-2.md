---
doc_id: ops/examples/eslint
chunk_id: ops/examples/eslint#chunk-2
heading_path: ["ESLint example", "Setup"]
chunk_type: code
tokens: 326
summary: "Setup"
---

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
