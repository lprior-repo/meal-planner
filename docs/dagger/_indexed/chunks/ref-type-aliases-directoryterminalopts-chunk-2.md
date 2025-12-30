---
doc_id: ref/type-aliases/directoryterminalopts
chunk_id: ref/type-aliases/directoryterminalopts#chunk-2
heading_path: ["directoryterminalopts", "Properties"]
chunk_type: prose
tokens: 138
summary: "> `optional` **cmd**: `string`[]

If set, override the container's default terminal command and i..."
---
### cmd?

> `optional` **cmd**: `string`[]

If set, override the container's default terminal command and invoke these command arguments instead.

---

### container?

> `optional` **container**: [`Container`](/reference/typescript/api/client.gen/classes/Container)

If set, override the default container used for the terminal.

---

### experimentalPrivilegedNesting?

> `optional` **experimentalPrivilegedNesting**: `boolean`

Provides Dagger access to the executed command.

---

### insecureRootCapabilities?

> `optional` **insecureRootCapabilities**: `boolean`

Execute the command with all root capabilities. This is similar to running a command with "sudo" or executing "docker run" with the "--privileged" flag. Containerization does not provide any security guarantees when using this option. It should only be used when absolutely necessary and only with trusted commands.
