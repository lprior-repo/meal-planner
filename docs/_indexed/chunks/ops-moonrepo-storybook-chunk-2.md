---
doc_id: ops/moonrepo/storybook
chunk_id: ops/moonrepo/storybook#chunk-2
heading_path: ["Storybook example", "Setup"]
chunk_type: code
tokens: 484
summary: "Setup"
---

## Setup

This section assumes Storybook is being used with Vite, and is integrated on a per-project basis.

After setting up Storybook, ensure [`moon.yml`](/docs/config/project) has the following tasks:

<project>/moon.yml

```yaml
fileGroups:
  storybook:
    - 'src/**/*'
    - 'stories/**/*'
    - 'tests/**/*'
    - '.storybook/**/*'

tasks:
  buildStorybook:
    command: 'build-storybook --output-dir @out(0)'
    inputs:
      - '@group(storybook)'
    outputs:
      - 'build'

  storybook:
    local: true
    command: 'start-storybook'
    inputs:
      - '@group(storybook)'
```

To run the Storybook development server:

```
moon run <project>:storybook
```

### Vite integration

Storybook 7 uses Vite out of the box, and as such, no configuration is required, but should you choose to extend the Vite config, you can do so by passing in `viteFinal`:

.storybook/main.ts

```ts
import { mergeConfig } from 'vite';

export default {
  stories: ['../stories/**/*.stories.mdx', '../stories/**/*.stories.@(js|jsx|ts|tsx)'],
  addons: ['@storybook/addon-links', '@storybook/addon-essentials'],
  core: {
    builder: '@storybook/builder-vite',
  },
  async viteFinal(config) {
    // Merge custom configuration into the default config
    return mergeConfig(config, {
      // Use the same "resolve" configuration as your app
      resolve: (await import('../vite.config.js')).default.resolve,
      // Add dependencies to pre-optimization
      optimizeDeps: {
        include: ['storybook-dark-mode'],
      },
    });
  },
};
```

For more information on how to integrate Vite with Storybook see the [relevant documentation](https://storybook.js.org/docs/7.0/react/builders/vite#configuration).

### Webpack integration

If you want to use Webpack with your Storybook project, you can do so by installing the relevant package and updating configuration.

```
yarn workspace <project> add --dev @storybook/builder-webpack5
```

.storybook/main.ts

```ts
export default {
  core: {
    builder: '@storybook/builder-webpack5',
  },
};
```

For more information on how to integrate Webpack with Storybook, see the [relevant documentation](https://storybook.js.org/docs/7.0/react/builders/webpack).

### Jest integration

You can use Jest to test your stories, but isn't a requirement. Storybook ships with first-party plugins for improved developer experience.

Install the test runner and any relevant packages:

```
yarn workspace <project> add --dev @storybook/addon-interactions @storybook/addon-coverage @storybook/jest@next @storybook/testing-library@next @storybook/test-runner@next
```

Add the test task to your project:

<project>/moon.yml

```yaml
tasks:
  testStorybook:
    command: 'test-storybook'
    inputs:
      - '@group(storybook)'
```

Then enable plugins and interactions in your Storybook project:

.storybook/main.ts

```ts
export default {
  stories: ['../src/**/*.stories.mdx', '../src/**/*.stories.@(js|jsx|ts|tsx)'],
  addons: [
    // Other Storybook addons
    '@storybook/addon-interactions', // Addon is registered here
    '@storybook/addon-coverage',
  ],
  features: {
    interactionsDebugger: true, // Enable playback controls
  },
};
```

You can now start writing your tests. For an extended guide on how to write tests within your stories, see [writing an interaction test](https://storybook.js.org/docs/react/writing-tests/interaction-testing#write-an-interaction-test) on the Storybook docs.
