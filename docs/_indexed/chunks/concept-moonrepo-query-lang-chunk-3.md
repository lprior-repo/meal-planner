---
doc_id: concept/moonrepo/query-lang
chunk_id: concept/moonrepo/query-lang#chunk-3
heading_path: ["Query language", "Fields"]
chunk_type: code
tokens: 257
summary: "Fields"
---

## Fields

The following fields can be used as criteria, and are related to [task tokens](/docs/concepts/token#variables).

### `language`

Programming language the project is written in, as defined in [`moon.yml`](/docs/config/project#language).

```
language=rust
```

### `project`

Name OR alias of the project.

```
project=server
```

### `projectAlias`

Alias of the project. For example, the `package.json` name.

```
projectAlias~@scope/*
```

### `projectLayer` (v1.39.0)

The project layer, as defined in [`moon.yml`](/docs/config/project#layer).

```
projectLayer=application
```

### `projectName`

Name of the project, as defined in [`.moon/workspace.yml`](/docs/config/workspace), or `id` in [`moon.yml`](/docs/config/project#id).

```
project=server
```

### `projectSource`

Relative file path from the workspace root to the project root, as defined in [`.moon/workspace.yml`](/docs/config/workspace).

```
projectSource~packages/*
```

### `projectStack` (v1.22.0)

The project stack, as defined in [`moon.yml`](/docs/config/project#stack).

```
projectStack=frontend
```

### `projectType`

> This field is deprecated, use `projectLayer` instead.

The type of project, as defined in [`moon.yml`](/docs/config/project#layer).

```
projectType=application
```

### `tag`

A tag within the project, as defined in [`moon.yml`](/docs/config/project#tags).

```
tag~react-*
```

### `task`

ID/name of a task within the project.

```
task=[build,test]
```

### `taskToolchain` (v1.31.0)

The toolchain a task will run against, as defined in [`moon.yml`](/docs/config/project).

```
taskToolchain=node
```

### `taskType`

The [type of task](/docs/concepts/task#types), based on its configured settings.

```
taskType=build
```
