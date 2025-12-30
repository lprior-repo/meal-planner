---
id: ref/type-aliases/containerastarballopts
title: "Type Alias: ContainerAsTarballOpts"
category: ref
tags: ["ref", "api", "ci", "typescript", "container"]
---

# Type Alias: ContainerAsTarballOpts

> **Context**: > **ContainerAsTarballOpts** = `object`


> **ContainerAsTarballOpts** = `object`

## Properties

### forcedCompression?

> `optional` **forcedCompression**: [`ImageLayerCompression`](/reference/typescript/api/client.gen/enumerations/ImageLayerCompression)

Force each layer of the image to use the specified compression algorithm.

If this is unset, then if a layer already has a compressed blob in the engine's cache, that will be used (this can result in a mix of compression algorithms for different layers). If this is unset and a layer has no compressed blob in the engine's cache, then it will be compressed using Gzip.

---

### mediaTypes?

> `optional` **mediaTypes**: [`ImageMediaTypes`](/reference/typescript/api/client.gen/enumerations/ImageMediaTypes)

Use the specified media types for the image's layers.

Defaults to OCI, which is largely compatible with most recent container runtimes, but Docker may be needed for older runtimes without OCI support.

---

### platformVariants?

> `optional` **platformVariants**: [`Container`](/reference/typescript/api/client.gen/classes/Container)[]

Identifiers for other platform specific containers.

Used for multi-platform images.

## See Also

- [Documentation Overview](./COMPASS.md)
