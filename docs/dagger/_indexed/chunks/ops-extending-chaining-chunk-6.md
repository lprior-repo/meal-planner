---
doc_id: ops/extending/chaining
chunk_id: ops/extending/chaining#chunk-6
heading_path: ["chaining", "Start containers as services"]
chunk_type: mixed
tokens: 169
summary: "Every `Container` object exposes a `Container."
---
Every `Container` object exposes a `Container.asService()` API method, which turns the container into a `Service`. These services can then be spun up for use by other Dagger Functions or by clients on the Dagger host by forwarding their ports. This is akin to a "programmable docker-compose".

To start a `Service` returned by a Dagger Function and have it forward traffic to a specified address via the host, chain a call to the `Service.up()` API method.

Here is an example of starting an NGINX service on host port 80 by chaining calls to `Container.asService()` and `Service.up()`:

**System shell:**
```bash
dagger -c 'github.com/kpenfound/dagger-modules/nginx@v0.1.0 | container | as-service | up'
```

**Dagger Shell:**
```
github.com/kpenfound/dagger-modules/nginx@v0.1.0 | container | as-service | up
```

**Dagger CLI:**
```bash
dagger -m github.com/dagger/dagger/modules/wolfi@v0.16.2 call container as-service up
```
