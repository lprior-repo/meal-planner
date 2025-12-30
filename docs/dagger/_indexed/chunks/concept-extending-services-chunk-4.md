---
doc_id: concept/extending/services
chunk_id: concept/extending/services#chunk-4
heading_path: ["services", "Expose services returned by functions to the host"]
chunk_type: mixed
tokens: 182
summary: "Services returned by Dagger Functions can also be exposed directly to the host."
---
Services returned by Dagger Functions can also be exposed directly to the host. This enables clients on the host to communicate with services running in Dagger.

Here is another example call for the Dagger Function shown previously, this time exposing the HTTP service on the host:

```bash
dagger call http-service up
```

By default, each service port maps to the same port on the host - in this case, port 8080. The service can then be accessed by clients on the host:

```bash
curl localhost:8080
```

The result will be:

```
Hello, world!
```

To specify a different mapping, use the additional `--ports` argument with a list of host/service port mappings. Here's an example, which exposes the service on host port 9000:

```bash
dagger call http-service up --ports 9000:8080
```

> **Note:** To bind ports randomly, use the `--random` argument.
