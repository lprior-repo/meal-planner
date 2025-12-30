---
doc_id: ref/classes/terminal
chunk_id: ref/classes/terminal#chunk-4
heading_path: ["terminal", "Methods"]
chunk_type: prose
tokens: 56
summary: "> **id**(): `Promise`<[`TerminalID`](/reference/typescript/api/client."
---
### id()

> **id**(): `Promise`<[`TerminalID`](/reference/typescript/api/client.gen/type-aliases/TerminalID)\>

A unique identifier for this Terminal.

#### Returns

`Promise`<[`TerminalID`](/reference/typescript/api/client.gen/type-aliases/TerminalID)\>

---

### sync()

> **sync**(): `Promise`<`Terminal`\>

Forces evaluation of the pipeline in the engine.

It doesn't run the default command if no exec has been set.

#### Returns

`Promise`<`Terminal`\>
