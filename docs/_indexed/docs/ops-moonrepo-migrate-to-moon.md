---
id: ops/moonrepo/migrate-to-moon
title: "Migrate to moon"
category: ops
tags: ["moonrepo", "operations", "advanced", "migrate"]
---

# Migrate to moon

> **Context**: Now that we've talked about the workspace, projects, tasks, and more, we must talk about something important... Should you embrace moon tasks? Or keep

Now that we've talked about the workspace, projects, tasks, and more, we must talk about something important... Should you embrace moon tasks? Or keep using language/ecosystem specific scripts? Or both (incremental adoption)?

## Migrate to moon tasks

We suggest using moon tasks (of course), as they provide far more granular control and configurable options than scripts, and a `moon.yml` is a better source of truth. Scripts aren't powerful enough to scale for large codebases.

An example of what this may look like can be found below. This *may* look like a lot, but it pays dividends in the long run.

<project>/moon.yml

```yaml
language: 'javascript'

fileGroups:
  sources:
    - 'src/**/*'
  tests:
    - 'tests/**/*'

tasks:
  build:
    command: 'webpack build --output-path @out(0)'
    inputs:
      - '@globs(sources)'
      - 'webpack.config.js'
    outputs:
      - 'build'

  dev:
    command: 'webpack server'
    inputs:
      - '@globs(sources)'
      - 'webpack.config.js'
    local: true

  format:
    command: 'prettier --check .'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
      - '/prettier.config.js'

  lint:
    command: 'eslint .'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
      - '.eslintignore'
      - '.eslintrc.js'
      - '/.eslintrc.js'

  test:
    command: 'jest .'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
      - 'jest.config.js'

  typecheck:
    command: 'tsc --build'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
      - 'tsconfig.json'
      - '/tsconfig.json'
```

To ease the migration process, we offer the `moon migrate from-package-json` command, which will convert a project's `package.json` scripts into `moon.yml` tasks, while also determining project dependencies (`dependsOn`). This needs to be ran *per project*.

```
$ moon migrate from-package-json <project>
```

This command will do its best to parse and convert scripts, but this isn't always a simple 1:1 conversion, especially when determining dependency chains. For this reason alone, we suggest *manually curating* tasks, but the migrate command well get you most of the way!

## Continue using scripts

As a frontend developer you're already familiar with the Node.js ecosystem, specifically around defining and using `package.json` scripts, and you may not want to deviate from this. Don't worry, simply enable the `node.inferTasksFromScripts` setting to automatically create moon tasks from a project's scripts! These can then be ran with `moon run`.

This implementation is a simple abstraction that runs `npm run <script>` (or pnpm/yarn) in the project directory as a child process. While this works, relying on `package.json` scripts incurs the following risks and disadvantages:

-   Inputs default to `**/*`:
    -   A change to every project relative file will mark the task as affected, even those not necessary for the task. Granular input control is lost.
    -   A change to workspace relative files *will not* mark the task as affected. For example, a change to `/prettier.config.js` would not be detected for a `npm run format` script.
-   Outputs default to an empty list unless:
    -   moon will attempt to extract outputs from arguments, by looking for variations of `--out`, `--outFile`, `--dist-dir`, etc.
    -   If no output could be determined, builds will not be cached and hydrated.
-   Tasks will always run in CI unless:
    -   moon will attempt to determine invalid CI tasks by looking for popular command usage, for example: `webpack serve`, `next dev`, `--watch` usage, and more. This *is not* an exhaustive check.
    -   The script name contains variations of `dev`, `start`, or `serve`.

## Next steps

By this point, you should have a better understanding behind moon's fundamentals! Why not adopt incrementally next? Jump into guides for advanced use cases or concepts for a deeper understanding.

- [Community help & support](https://discord.gg/qCh9MEynv2)
- [Releases & updates](https://twitter.com/tothemoonrepo)


## See Also

- [Documentation Index](./COMPASS.md)
