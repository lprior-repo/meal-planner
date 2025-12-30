---
doc_id: tutorial/getting-started/quickstarts-basics
chunk_id: tutorial/getting-started/quickstarts-basics#chunk-5
heading_path: ["quickstarts-basics", "Add files and directories"]
chunk_type: mixed
tokens: 114
summary: "You can modify containers by adding files or directories:

```
container | from alpine | with-dir..."
---
You can modify containers by adding files or directories:

```
container | from alpine | with-directory /src https://github.com/dagger/dagger
```

Here's another example, creating a new file in the container:

```
container | from alpine | with-new-file /hi.txt "Hello from Dagger!"
```

To look inside, request an interactive terminal session:

```
container | from alpine | with-new-file /hi.txt "Hello from Dagger!" | terminal
```

> **Tip:** The `terminal` function is very useful for debugging and experimenting, since it allows you to interact directly with containers and inspect their state.
