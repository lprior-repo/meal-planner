---
doc_id: concept/general/cheat-sheet
chunk_id: concept/general/cheat-sheet#chunk-2
heading_path: ["Cheat sheet", "Tasks"]
chunk_type: code
tokens: 106
summary: "Tasks"
---

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
