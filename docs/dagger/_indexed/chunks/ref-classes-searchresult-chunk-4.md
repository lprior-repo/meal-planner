---
doc_id: ref/classes/searchresult
chunk_id: ref/classes/searchresult#chunk-4
heading_path: ["searchresult", "Methods"]
chunk_type: prose
tokens: 121
summary: "> **absoluteOffset**(): `Promise`<`number`\>

The byte offset of this line within the file."
---
### absoluteOffset()

> **absoluteOffset**(): `Promise`<`number`\>

The byte offset of this line within the file.

#### Returns

`Promise`<`number`\>

---

### filePath()

> **filePath**(): `Promise`<`string`\>

The path to the file that matched.

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`SearchResultID`](/reference/typescript/api/client.gen/type-aliases/SearchResultID)\>

A unique identifier for this SearchResult.

#### Returns

`Promise`<[`SearchResultID`](/reference/typescript/api/client.gen/type-aliases/SearchResultID)\>

---

### lineNumber()

> **lineNumber**(): `Promise`<`number`\>

The first line that matched.

#### Returns

`Promise`<`number`\>

---

### matchedLines()

> **matchedLines**(): `Promise`<`string`\>

The line content that matched.

#### Returns

`Promise`<`string`\>

---

### submatches()

> **submatches**(): `Promise`<[`SearchSubmatch`](/reference/typescript/api/client.gen/classes/SearchSubmatch)\[\]>

Sub-match positions and content within the matched lines.

#### Returns

`Promise`<[`SearchSubmatch`](/reference/typescript/api/client.gen/classes/SearchSubmatch)\[\]>
