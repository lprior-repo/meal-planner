---
id: tutorial/examples/angular
title: "Angular example"
category: tutorial
tags: ["examples", "angular", "beginner", "tutorial"]
---

# Angular example

> **Context**: In this guide, you'll learn how to integrate [Angular](https://angular.io/) into moon.

In this guide, you'll learn how to integrate [Angular](https://angular.io/) into moon.

Begin by creating a new Angular project in the root of an existing moon project (this should not be created in the workspace root, unless a polyrepo).

```
cd apps && npx -p @angular/cli@latest ng new angular-app
```

> View the [official Angular docs](https://angular.io/start) for a more in-depth guide to getting started!

## Setup

Since Angular is per-project, the associated moon tasks should be defined in each project's [`moon.yml`](/docs/config/project) file.

<project>/moon.yml

```yaml
fileGroups:
  app:
    - 'src/**/*'
    - 'angular.*'

tasks:
  dev:
    command: 'ng serve'
    local: true
  build:
    command: 'ng build'
    inputs:
      - '@group(app)'
      - '@group(sources)'
    outputs:
      - 'dist'
  # Extends the top-level lint
  lint:
    args:
      - '--ext'
      - '.ts'
```

### ESLint integration

Angular does not provide a built-in linting abstraction, but instead there is an [ESLint package](https://github.com/angular-eslint/angular-eslint), which is great, but complicates things a bit. Because of this, you have two options for moving forward:

- Use a [global `lint` task](/docs/guides/examples/eslint) and bypass Angular's solution (preferred).
- Use Angular's ESLint package solution only.

Regardless of which option is chosen, the following changes are applicable to all options and should be made. Begin be installing the dependencies that the [`@angular-eslint`](https://nextjs.org/docs/basic-features/eslint#eslint-config) package need in the application's `package.json`.

```
yarn workspace <project> add --dev @angular-eslint/builder @angular-eslint/eslint-plugin @angular-eslint/eslint-plugin-template @angular-eslint/schematics @angular-eslint/template-parser
```

Since Angular has some specific rules, we'll need to tell the ESLint package to overrides the default ones. This can be achieved with a project-level `.eslintrc.json` file.

<project>/.eslintrc.json

```json
{
  "root": true,
  "ignorePatterns": ["projects/**/*"],
  "overrides": [
    {
      "files": ["*.ts"],
      "extends": [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended",
        "plugin:@angular-eslint/recommended",
        "plugin:@angular-eslint/template/process-inline-templates"
      ],
      "rules": {
        "@angular-eslint/directive-selector": [
          "error",
          { "type": "attribute", "prefix": "app", "style": "camelCase" }
        ],
        "@angular-eslint/component-selector": [
          "error",
          { "type": "element", "prefix": "app", "style": "kebab-case" }
        ]
      }
    },
    {
      "files": ["*.html"],
      "extends": [
        "plugin:@angular-eslint/template/recommended",
        "plugin:@angular-eslint/template/accessibility"
      ],
      "rules": {}
    }
  ]
}
```

**Global lint approach:**

We encourage using the global `lint` task for consistency across all projects within the repository. With this approach, the `eslint` command itself will be ran and the `ng lint` command will be ignored, but the `@angular-eslint` rules will still be used.

**Angular lint approach:**

If you'd prefer to use the `ng lint` command, add it as a task to the project's [`moon.yml`](/docs/config/project).

<project>/moon.yml

```yaml
tasks:
  lint:
    command: 'ng lint'
    inputs:
      - '@group(angular)'
```

Furthermore, if a global `lint` task exists, be sure to exclude it from being inherited.

<project>/moon.yml

```yaml
workspace:
  inheritedTasks:
    exclude: ['lint']
```

In addition to configuring `moon.yml`, you also need to add a lint target in the `angular.json` file for linting to work properly.

<project>/angular.json

```json
{
  "projects": {
    "angular-app": {
      "architect": {
        "lint": {
          "builder": "@angular-eslint/builder:lint",
          "options": {
            "lintFilePatterns": ["src/**/*.ts", "src/**/*.html"]
          }
        }
      }
    }
  }
}
```

### TypeScript integration

Angular has [built-in support for TypeScript](https://angular.io/guide/typescript-configuration), so there is no need for additional configuration to enable TypeScript support.

At this point we'll assume that a `tsconfig.json` has been created in the application, and typechecking works. From here we suggest utilizing a [global `typecheck` task](/docs/guides/examples/typescript) for consistency across all projects within the repository.

## Configuration

### Root-level

We suggest *against* root-level configuration, as Angular should be installed per-project, and the `ng` command expects the configuration to live relative to the project root.

### Project-level

When creating a new Angular project, a [`angular.json`](https://angular.io/guide/workspace-config) is created, and *must* exist in the project root. This allows each project to configure Angular for their needs.

<project>/angular.json

```json
{
  "$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "projects": {
    "angular-app": {
      "projectType": "application",
      ...
    }
  },
  ...
}
```


## See Also

- [`moon.yml`](/docs/config/project)
- [global `lint` task](/docs/guides/examples/eslint)
- [`moon.yml`](/docs/config/project)
- [global `typecheck` task](/docs/guides/examples/typescript)
