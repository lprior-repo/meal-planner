---
doc_id: tutorial/getting-started/quickstarts-agent-in-project
chunk_id: tutorial/getting-started/quickstarts-agent-in-project#chunk-4
heading_path: ["quickstarts-agent-in-project", "Create a workspace for the agent"]
chunk_type: mixed
tokens: 233
summary: "The goal of this quickstart is to create an agent to interact with the existing codebase and add ..."
---
The goal of this quickstart is to create an agent to interact with the existing codebase and add features to it. This means that the agent needs the ability to list, read and write files in the project directory.

To give the agent these tools, create a Dagger submodule called `workspace`. This module will have Dagger Functions to list, read, and write files.

Start by creating the submodule:

**Go:**
```bash
dagger init --sdk=go .dagger/workspace
```

**Python:**
```bash
dagger init --sdk=python .dagger/workspace
```

**TypeScript:**
```bash
dagger init --sdk=typescript .dagger/workspace
```

In this Dagger module, each Dagger Function performs a different operation:

- The `read-file` Dagger Function reads a file in the workspace.
- The `write-file` Dagger Function writes a file to the workspace.
- The `list-files` Dagger Function lists all the files in the workspace.
- The `test` Dagger Function runs the tests on the files in the workspace.

See the functions of the new workspace module:

```bash
dagger -m .dagger/workspace functions
```

Now install the new submodule as a dependency to the main module:

```bash
dagger install ./.dagger/workspace
```
