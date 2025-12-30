---
doc_id: ref/type-aliases/directoryexportopts
chunk_id: ref/type-aliases/directoryexportopts#chunk-2
heading_path: ["directoryexportopts", "Properties"]
chunk_type: prose
tokens: 100
summary: "> `optional` **wipe**: `boolean`

If true, then the host directory will be wiped clean before exp..."
---
### wipe?

> `optional` **wipe**: `boolean`

If true, then the host directory will be wiped clean before exporting so that it exactly matches the directory being exported; this means it will delete any files on the host that aren't in the exported dir. If false (the default), the contents of the directory will be merged with any existing contents of the host directory, leaving any existing files on the host that aren't in the exported directory alone.
