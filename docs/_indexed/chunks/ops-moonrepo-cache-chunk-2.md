---
doc_id: ops/moonrepo/cache
chunk_id: ops/moonrepo/cache#chunk-2
heading_path: ["Cache", "Hashing"]
chunk_type: prose
tokens: 296
summary: "Hashing"
---

## Hashing

Incremental builds are possible through a concept known as hashing, where in multiple sources are aggregated to generate a unique hash. In the context of moon, each time a target is ran we generate a hash, and if this hash already exists we abort early (cache hit), otherwise we continue the run (cache miss).

The tiniest change may trigger a different hash, for example, changing a line of code (when an input), or updating a package version, so don't worry if you see *a lot* of hashes.

Our smart hashing currently takes the following sources into account:

-   Command (`command`) being ran and its arguments (`args`).
-   Input sources (`inputs`).
-   Output targets (`outputs`).
-   Environment variables (`env`).
-   Dependencies between projects (`dependsOn`) and tasks (`deps`).
-   **For Deno tasks**:
    -   Deno version.
    -   `deno.json`/`deps.ts` imports, import maps, and scopes.
    -   `tsconfig.json` compiler options (when applicable).
-   **For Bun and Node.js tasks**:
    -   Bun/Node.js version.
    -   `package.json` dependencies (including development and peer).
    -   `tsconfig.json` compiler options (when applicable).

> **Caution**: Be aware that greedy inputs (`**/*`, the default) will include *everything* in the target directory as a source. We do our best to filter out VCS ignored files, and `outputs` for the current task, but files may slip through that you don't expect. We suggest using explicit `inputs` and routinely auditing the hash files for accuracy!
