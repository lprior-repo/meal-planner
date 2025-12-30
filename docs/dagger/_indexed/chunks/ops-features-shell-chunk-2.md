---
doc_id: ops/features/shell
chunk_id: ops/features/shell#chunk-2
heading_path: ["shell", "Behavior"]
chunk_type: prose
tokens: 221
summary: "Dagger Shell uses the Bash syntax as a frontend, but its behavior is quite different in the backe..."
---
Dagger Shell uses the Bash syntax as a frontend, but its behavior is quite different in the backend:

- Instead of executing UNIX commands, you execute Dagger Functions
- Instead of passing text streams from command to command, you pass typed objects from function to function
- Instead of available commands being the same everywhere in the pipeline, each command is executed in the context of the previous command's output object. For example, `foo | bar` really means `foo().bar()`
- Instead of using the local host as an execution environment, you use containerized runtimes
- Instead of being mixed with regular commands, shell builtins are prefixed with `.` (similar to SQLite)

Besides these differences, all the features of the Bash syntax are available in Dagger Shell, including:

- **Shell variables**: `container=$(container | from alpine)`
- **Shell functions**: `container() { container | from alpine; }`
- **Job control**: `frontend | test & backend | test & .wait`
- **Quoting**: single quotes and double quotes have the same meaning as in Bash
