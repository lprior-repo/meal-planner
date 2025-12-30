---
doc_id: ref/classes/sourcemap
chunk_id: ref/classes/sourcemap#chunk-4
heading_path: ["sourcemap", "Methods"]
chunk_type: prose
tokens: 135
summary: "> **column**(): `Promise`<`number`\>

The column number within the line."
---
### column()

> **column**(): `Promise`<`number`\>

The column number within the line.

#### Returns

`Promise`<`number`\>

---

### filename()

> **filename**(): `Promise`<`string`\>

The filename from the module source.

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`SourceMapID`](/reference/typescript/api/client.gen/type-aliases/SourceMapID)\>

A unique identifier for this SourceMap.

#### Returns

`Promise`<[`SourceMapID`](/reference/typescript/api/client.gen/type-aliases/SourceMapID)\>

---

### line()

> **line**(): `Promise`<`number`\>

The line number within the filename.

#### Returns

`Promise`<`number`\>

---

### module\_()

> **module\_**(): `Promise`<`string`\>

The module dependency this was declared in.

#### Returns

`Promise`<`string`\>

---

### url()

> **url**(): `Promise`<`string`\>

The URL to the file, if any. This can be used to link to the source map in the browser.

#### Returns

`Promise`<`string`\>
