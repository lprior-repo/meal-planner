---
id: ops/moonrepo/create-task
title: "Create a task"
category: ops
tags: ["operations", "create", "advanced", "moonrepo"]
---

# Create a task

> **Context**: The primary focus of moon is a task runner, and for it to operate in any capacity, it requires tasks to run. In moon, a task is a binary or system com

The primary focus of moon is a task runner, and for it to operate in any capacity, it requires tasks to run. In moon, a task is a binary or system command that is ran as a child process within the context of a project (is the current working directory). Tasks are defined per project with `moon.yml`, or inherited by many projects with `.moon/tasks.yml`, but can also be inferred from a language's ecosystem (we'll talk about this later).

## Configuring a task

Most — if not all projects — utilize the same core tasks: linting, testing, code formatting, typechecking, and *building*. Because these are so universal, let's implement the build task within a project using `moon.yml`.

Begin by creating the `moon.yml` file at the root of a project and add `build` to the `tasks` field, with a `command` parameter.

<project>/moon.yml

```yaml
language: 'javascript'

tasks:
  build:
    command: 'webpack build'
```

By itself, this isn't doing much, so let's add some arguments. Arguments can also be defined with the `args` setting.

<project>/moon.yml

```yaml
language: 'javascript'

tasks:
  build:
    command: 'webpack build --mode production --no-stats'
```

With this, the task can be ran from the command line with `moon run <project>:build`! This is tasks in its most simplest form, but continue reading on how to take full advantage of our task runner.

### Inputs

Our task above works, but isn't very efficient as it *always* runs, regardless of what has changed since the last time it has ran. This becomes problematic in continuous integration environments, not just locally.

To mitigate this problem, moon provides a system known as inputs, which are file paths, globs, and environment variables that are used by the task when it's ran. moon will use and compare these inputs to calculate whether to run, or to return the previous run state from the cache.

If you're a bit confused, let's demonstrate this by expanding the task with the `inputs` setting.

<project>/moon.yml

```yaml
language: 'javascript'

tasks:
  build:
    command: 'webpack build --mode production --no-stats'
    inputs:
      - 'src/**/*'
      - 'webpack.config.js'
      - '/webpack-shared.config.js'
```

This list of inputs may look complicated, but they are merely run checks. For example, when moon detects a change in...

-   Any files within the `src` folder, relative from the project's root.
-   A config file in the project's root.
-   A shared config file in the workspace root (denoted by the leading `/`).

...the task will be ran! If the change occurs *outside* of the project or *outside* the list of inputs, the task will *not* be ran.

> Inputs are a powerful feature that can be fine-tuned to your project's need. Be as granular or open as you want, the choice is yours!

### Outputs

Outputs are the opposite of inputs, as they are files and folders that are created as a result of running the task. With that being said, outputs are *optional*, as not all tasks require them, and the ones that do are typically build related.

Now why is declaring outputs important? For incremental builds and smart caching! When moon encounters a build that has already been built, it hydrates all necessary outputs from the cache, then immediately exits. No more waiting for long builds!

Continuing our example, let's route the built files and expand our task with the `outputs` setting.

<project>/moon.yml

```yaml
language: 'javascript'

tasks:
  build:
    command: 'webpack build --mode production --no-stats --output-path @out(0)'
    inputs:
      - 'src/**/*'
      - 'webpack.config.js'
      - '/webpack-shared.config.js'
    outputs:
      - 'build'
```

## Depending on other tasks

For scenarios where you need run a task *before* another task, as you're expecting some repository state or artifact to exist, can be achieved with the `deps` setting, which requires a list of targets:

-   `<project>:<task>` - Full canonical target.
-   `~:<task>` or `<task>` - A task within the current project.
-   `^:<task>` - A task from all depended on projects.

<project>/moon.yml

```yaml
dependsOn:
  # ...

tasks:
  build:
    # ...
    deps:
      - '^:build'
```

## Using file groups

Once you're familiar with configuring tasks, you may notice certain inputs being repeated constantly, like source files, test files, and configuration. To reduce the amount of boilerplate required, moon provides a feature known as file groups, which enables grouping of similar file types within a project using file glob patterns or literal file paths.

File groups are defined with the `fileGroups` setting, which maps a list of file paths/globs to a group, like so.

<project>/moon.yml

```yaml
fileGroups:
  configs:
    - '*.config.js'
  sources:
    - 'src/**/*'
    - 'types/**/*'
  tests:
    - 'tests/**/*'
```

We can then replace the inputs in our task above with these new file groups using a syntax known as tokens, specifically the `@globs` and `@files` token functions. Tokens are an advanced feature, so please refer to their documentation for more information!

<project>/moon.yml

```yaml
language: 'javascript'

fileGroups:
  # ...

tasks:
  build:
    command: 'webpack build --mode production --no-stats --output-path @out(0)'
    inputs:
      - '@globs(sources)'
      - 'webpack.config.js'
      - '/webpack-shared.config.js'
    outputs:
      - 'build'
```

With file groups (and tokens), you're able to reduce the amount of configuration required *and* encourage certain file structures for consuming projects!

## Next steps

- [Run a task](/docs/run-task)
- [Configure `.moon/tasks.yml` further](/docs/config/tasks)
- [Configure `moon.yml` further](/docs/config/project)
- [Learn about tasks](/docs/concepts/task)
- [Learn about tokens](/docs/concepts/token)


## See Also

- [Run a task](/docs/run-task)
- [Configure `.moon/tasks.yml` further](/docs/config/tasks)
- [Configure `moon.yml` further](/docs/config/project)
- [Learn about tasks](/docs/concepts/task)
- [Learn about tokens](/docs/concepts/token)
