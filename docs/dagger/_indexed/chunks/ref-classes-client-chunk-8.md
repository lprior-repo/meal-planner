---
doc_id: ref/classes/client
chunk_id: ref/classes/client#chunk-8
heading_path: ["client", "Methods", "currentEnv()"]
chunk_type: prose
tokens: 117
summary: "> **currentEnv**(): [`Env`](/reference/typescript/api/client."
---
> **currentEnv**(): [`Env`](/reference/typescript/api/client.gen/classes/Env)

**`Experimental`**

Returns the current environment

When called from a function invoked via an LLM tool call, this will be the LLM's current environment, including any modifications made through calling tools. Env values returned by functions become the new environment for subsequent calls, and Changeset values returned by functions are applied to the environment's workspace.

When called from a module function outside of an LLM, this returns an Env with the current module installed, and with the current module's source directory as its workspace.

#### Returns

[`Env`](/reference/typescript/api/client.gen/classes/Env)

---
