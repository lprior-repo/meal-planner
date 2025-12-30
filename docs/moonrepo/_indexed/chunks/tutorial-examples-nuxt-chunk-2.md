---
doc_id: tutorial/examples/nuxt
chunk_id: tutorial/examples/nuxt#chunk-2
heading_path: ["Nuxt example", "Setup"]
chunk_type: code
tokens: 196
summary: "Setup"
---

## Setup

Since Nuxt is per-project, the associated moon tasks should be defined in each project's [`moon.yml`](/docs/config/project) file.

<project>/moon.yml

```yaml
fileGroups:
  nuxt:
    - 'assets/**/*'
    - 'components/**/*'
    - 'composables/**/*'
    - 'content/**/*'
    - 'layouts/**/*'
    - 'middleware/**/*'
    - 'pages/**/*'
    - 'plugins/**/*'
    - 'public/**/*'
    - 'server/**/*'
    - 'utils/**/*'
    - '.nuxtignore'
    - 'app.config.*'
    - 'app.vue'
    - 'nuxt.config.*'

tasks:
  nuxt:
    command: 'nuxt'
    local: true

  # Production build
  build:
    command: 'nuxt build'
    inputs:
      - '@group(nuxt)'
    outputs:
      - '.nuxt'
      - '.output'

  # Development server
  dev:
    command: 'nuxt dev'
    local: true

  # Preview production build locally
  preview:
    command: 'nuxt preview'
    deps:
      - '~:build'
    local: true
```

Be sure to keep the `postinstall` script in your project's `package.json`.

<project>/package.json

```json
{
  // ...
  "scripts": {
    "postinstall": "nuxt prepare"
  }
}
```

### ESLint integration

Refer to our [Vue documentation](/docs/guides/examples/vue#eslint-integration) for more information on linting.

### TypeScript integration

Nuxt requires `vue-tsc` for typechecking, so refer to our [Vue documentation](/docs/guides/examples/vue#typescript-integration) for more information.
