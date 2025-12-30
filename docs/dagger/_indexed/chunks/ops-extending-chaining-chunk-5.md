---
doc_id: ops/extending/chaining
chunk_id: ops/extending/chaining#chunk-5
heading_path: ["chaining", "Publish containers"]
chunk_type: mixed
tokens: 138
summary: "Every `Container` object exposes a `Container."
---
Every `Container` object exposes a `Container.publish()` API method, which publishes the container as a new image to a specified container registry. The registry address is passed to the function using the `--address` argument, and the return value is a string referencing the container image address in the registry.

Here is an example of publishing the container returned by a Wolfi container builder Dagger Function to the `ttl.sh` registry, by chaining a `Container.publish()` call:

**System shell:**
```bash
dagger -c 'github.com/dagger/dagger/modules/wolfi@v0.16.2 | container | publish ttl.sh/my-wolfi'
```

**Dagger Shell:**
```
github.com/dagger/dagger/modules/wolfi@v0.16.2 | container | publish ttl.sh/my-wolfi
```

**Dagger CLI:**
```bash
dagger -m github.com/dagger/dagger/modules/wolfi@v0.16.2 call container publish --address=ttl.sh/my-wolfi
```
