---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-44
heading_path: ["container", "Methods", "withExec()"]
chunk_type: prose
tokens: 107
summary: "> **withExec**(`args`, `opts?"
---
> **withExec**(`args`, `opts?`): `Container`

Execute a command in the container, and return a new snapshot of the container state after execution.

#### Parameters

#### args

`string`\[\]

Command to execute. Must be valid exec() arguments, not a shell command. Example: \["go", "run", "main.go"\].

To run a shell command, execute the shell and pass the shell command as argument. Example: \["sh", "-c", "ls -l | grep foo"\]

Defaults to the container's default arguments (see "defaultArgs" and "withDefaultArgs").

#### opts?

[`ContainerWithExecOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithExecOpts)

#### Returns

`Container`

---
