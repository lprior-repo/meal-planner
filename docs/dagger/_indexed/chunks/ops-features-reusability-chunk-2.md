---
doc_id: ops/features/reusability
chunk_id: ops/features/reusability#chunk-2
heading_path: ["reusability", "Interoperability"]
chunk_type: code
tokens: 282
summary: "Modern development takes place in a mix of languages, tools and platforms."
---
Modern development takes place in a mix of languages, tools and platforms. In these environments, no one language or tool can "win"; every component must be interoperable with every other. Dagger is ideally suited to these polyglot environments, because Dagger modules are portable and reusable across languages. For example, a Python function can call a Go function, which can call a TypeScript function, and so on.

This feature immediately unlocks cross-team collaboration: even though different teams might prefer different languages, the Dagger modules they create are instantly compatible and usable by other teams. It also means that you no longer need to care which language your CI tooling is written in; you can use the one that you're most comfortable with or that best suits your requirements.

Here's an example, where a Dagger Function written in Python calls both core functions and third-party Dagger Functions written in Go:

```python
@function
async def ci(self, source: dagger.Directory) -> str:
    # Use third-party Golang module to configure project
    go_project = dag.golang().with_project(source)

    # Run Go tests using Golang module
    await go_project.test()

    # Get container with built binaries using Golang module
    image = await go_project.build_container()

    # Push image to a registry using core Dagger API
    ref = await image.publish("ttl.sh/demoapp:1h")

    # Scan image for vulnerabilites using third-party Trivy module
    return await dag.trivy().scan_container(dag.container().from_(ref))
```
