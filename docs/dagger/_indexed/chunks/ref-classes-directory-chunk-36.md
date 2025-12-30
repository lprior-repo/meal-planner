---
doc_id: ref/classes/directory
chunk_id: ref/classes/directory#chunk-36
heading_path: ["directory", "Methods", "withPatch()"]
chunk_type: prose
tokens: 48
summary: "> **withPatch**(`patch`): `Directory`

**`Experimental`**

Retrieves this directory with the give..."
---
> **withPatch**(`patch`): `Directory`

**`Experimental`**

Retrieves this directory with the given Git-compatible patch applied.

#### Parameters

#### patch

`string`

Patch to apply (e.g., "diff --git a/file.txt b/file.txt\\nindex 1234567..abcdef8 100644\\n--- a/file.txt\\n+++ b/file.txt\\n@@ -1,1 +1,1 @@\\n-Hello\\n+World\\n").

#### Returns

`Directory`

---
