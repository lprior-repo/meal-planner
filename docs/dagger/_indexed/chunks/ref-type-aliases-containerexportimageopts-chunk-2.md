---
doc_id: ref/type-aliases/containerexportimageopts
chunk_id: ref/type-aliases/containerexportimageopts#chunk-2
heading_path: ["containerexportimageopts", "Properties"]
chunk_type: prose
tokens: 170
summary: "> `optional` **forcedCompression**: [`ImageLayerCompression`](/reference/typescript/api/client."
---
### forcedCompression?

> `optional` **forcedCompression**: [`ImageLayerCompression`](/reference/typescript/api/client.gen/enumerations/ImageLayerCompression)

Force each layer of the exported image to use the specified compression algorithm.

If this is unset, then if a layer already has a compressed blob in the engine's cache, that will be used (this can result in a mix of compression algorithms for different layers). If this is unset and a layer has no compressed blob in the engine's cache, then it will be compressed using Gzip.

---

### mediaTypes?

> `optional` **mediaTypes**: [`ImageMediaTypes`](/reference/typescript/api/client.gen/enumerations/ImageMediaTypes)

Use the specified media types for the exported image's layers.

Defaults to OCI, which is largely compatible with most recent container runtimes, but Docker may be needed for older runtimes without OCI support.

---

### platformVariants?

> `optional` **platformVariants**: [`Container`](/reference/typescript/api/client.gen/classes/Container)[]

Identifiers for other platform specific containers.

Used for multi-platform image.
