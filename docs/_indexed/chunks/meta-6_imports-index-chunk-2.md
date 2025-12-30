---
doc_id: meta/6_imports/index
chunk_id: meta/6_imports/index#chunk-2
heading_path: ["Dependency management & imports", "Lockfile per script inferred from imports (Standard)"]
chunk_type: code
tokens: 154
summary: "Lockfile per script inferred from imports (Standard)"
---

## Lockfile per script inferred from imports (Standard)

In Windmill, you can run scripts without having to [manage a package.json](./meta-14_dependencies_in_typescript-index.md#lockfile-per-script-inferred-from-a-packagejson) / [requirements.txt](./meta-15_dependencies_in_python-index.md#lockfile-per-script-inferred-from-a-requirementstxt) directly. This is achieved by automatically parsing the imports and resolving the dependencies. This method works for all languages in Windmill.

When using Bun or Deno as the runtime for TypeScript in Windmill, dependencies are resolved directly from the script imports and their imports when using [sharing common logic](./meta-5_sharing_common_logic-index.md). The TypeScript runtime Bun ensures 100% compatibility with Node.js without requiring any code modifications.

Here is what it would give for Bun:

```ts
// unpinned import
import { toWords } from 'number-to-words';

// versioned import
import * as wmill from 'windmill-client@1.147.3';
```
and for Python:

```python
import os
