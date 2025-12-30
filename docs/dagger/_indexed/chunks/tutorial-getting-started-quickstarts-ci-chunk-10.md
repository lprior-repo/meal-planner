---
doc_id: tutorial/getting-started/quickstarts-ci
chunk_id: tutorial/getting-started/quickstarts-ci#chunk-10
heading_path: ["quickstarts-ci", "Run a container as a local service"]
chunk_type: mixed
tokens: 98
summary: "The `build` Dagger Function returns a `Container` type."
---
The `build` Dagger Function returns a `Container` type. Use `as-service` to start a container as a local service:

```
build | as-service | up --ports=8080:80
```

By default, Dagger will map each exposed container service port to the same port on the host. Since NGINX operates on port 80, the additional `--ports 8080:80` argument re-maps container port 80 to host port 8080.

You should now be able to access the application by browsing to `http://localhost:8080`.
