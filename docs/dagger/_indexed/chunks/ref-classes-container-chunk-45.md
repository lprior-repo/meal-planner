---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-45
heading_path: ["container", "Methods", "withExposedPort()"]
chunk_type: prose
tokens: 77
summary: "> **withExposedPort**(`port`, `opts?"
---
> **withExposedPort**(`port`, `opts?`): `Container`

Expose a network port. Like EXPOSE in Dockerfile (but with healthcheck support)

Exposed ports serve two purposes:

- For health checks and introspection, when running services
    
- For setting the EXPOSE OCI field when publishing the container

#### Parameters

#### port

`number`

Port number to expose. Example: 8080

#### opts?

[`ContainerWithExposedPortOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithExposedPortOpts)

#### Returns

`Container`

---
