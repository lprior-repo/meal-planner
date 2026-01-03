---
doc_id: concept/moonrepo/cheat-sheet
chunk_id: concept/moonrepo/cheat-sheet#chunk-4
heading_path: ["Cheat sheet", "OR"]
chunk_type: code
tokens: 145
summary: "OR"
---

## OR
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
