# Cheat sheet

Don't have time to read the docs? Here's a quick cheat sheet to get you started.

## Tasks

Learn more about tasks and targets.

### Run all build and test tasks for all projects

```
moon check --all
```

### Run all build and test tasks in a project

```
moon check project
```

### Run all build and test tasks for closest project based on working directory

```
moon check
```

### Run a task in all projects

```
moon run :task
```

### Run a task in all projects with a tag

```
moon run '#tag:task'
# OR
moon run \#tag:task
# OR
moon run :task --query "tag=tag"
```

### Run a task in a project

```
moon run project:task
```

### Run multiple tasks in all projects

```
moon run :task1 :task2
```

### Run multiple tasks in any project

```
moon run projecta:task1 projectb:task2
```

### Run a task in applications, libraries, or tools

```
moon run :task --query "projectType=application"
```

### Run a task in projects of a specific language

```
moon run :task --query "language=typescript"
```

### Run a task in projects matching a keyword

```
moon run :task --query "project~react-*"
```

### Run a task in projects based on file path

```
moon run :task --query "projectSource~packages/*"
```

## Task configuration

Learn more about available options.

### Disable caching

moon.yml

```yaml
tasks:
  example:
    # ...
    options:
      cache: false
```

### Re-run flaky tasks

moon.yml

```yaml
tasks:
  example:
    # ...
    options:
      retryCount: 3
```

### Depend on tasks from parent project's dependencies

moon.yml

```yaml
# Also inferred from the language
dependsOn:
  - 'project-a'
  - 'project-b'

tasks:
  example:
    # ...
    deps:
      - '^:build'
```

### Depend on tasks from arbitrary projects

moon.yml

```yaml
tasks:
  example:
    # ...
    deps:
      - 'other-project:task'
```

### Run dependencies serially

moon.yml

```yaml
tasks:
  example:
    # ...
    deps:
      - 'first'
      - 'second'
      - 'third'
    options:
      runDepsInParallel: false
```

### Run multiple watchers/servers in parallel

moon.yml

```yaml
tasks:
  example:
    command: 'noop'
    deps:
      - 'app:watch'
      - 'backend:start'
      - 'tailwind:watch'
    local: true
```

> The `local` or `persistent` settings are required for this to work.

## Languages

### Run system binaries available on `PATH`

moon.yml

```yaml
language: 'bash' # batch, etc

tasks:
  example:
    command: 'printenv'
```

moon.yml

```yaml
tasks:
  example:
    command: 'printenv'
    toolchain: 'system'
```

### Run language binaries not supported in moon's toolchain

moon.yml

```yaml
language: 'ruby'

tasks:
  example:
    command: 'rubocop'
    toolchain: 'system'
```

### Run npm binaries (Node.js)

moon.yml

```yaml
language: 'javascript' # typescript

tasks:
  example:
    command: 'eslint'
```

moon.yml

```yaml
tasks:
  example:
    command: 'eslint'
    toolchain: 'node'
```
