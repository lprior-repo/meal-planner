---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-13
heading_path: ["Workers and worker groups", "Interactive SSH REPL for worker host"]
chunk_type: prose
tokens: 237
summary: "Interactive SSH REPL for worker host"
---

## Interactive SSH REPL for worker host

Windmill includes a built-in interactive SSH-like REPL for each worker. This allows you to execute bash commands directly on the machine running the worker, making it significantly easier to debug, explore the filesystem, or run quick system-level commands.

### How to use

- Go to the **Workers** page in the Windmill.
- Find the worker you want to connect to in the table.
- Click the **Command** button in the "Live Shell" column.
- A drawer will open with an interactive bash shell.
- Type and run bash commands directly in the terminal.

> This feature is especially useful for debugging init scripts, verifying pre-installed binaries, inspecting the file system, or quickly running bash commands without needing to deploy a script.
<br />
**Note:**  
- Use `cd` to navigate directories — the REPL remembers your working directory across commands.  
- You can press `Ctrl+C` or use the **Cancel** button to stop a running job.  
- If no command has run in the past 2 minutes, the first one may take up to ~15 seconds to start.
