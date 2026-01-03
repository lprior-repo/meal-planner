---
doc_id: ops/moonrepo/create-task
chunk_id: ops/moonrepo/create-task#chunk-2
heading_path: ["Create a task", "Configuring a task"]
chunk_type: code
tokens: 642
summary: "Configuring a task"
---

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
