---
doc_id: tutorial/getting-started/quickstarts-basics
chunk_id: tutorial/getting-started/quickstarts-basics#chunk-10
heading_path: ["quickstarts-basics", "Speed things up"]
chunk_type: code
tokens: 74
summary: "Dagger provides powerful caching features:

- **Layers**: Build instructions and the results of s..."
---
Dagger provides powerful caching features:

- **Layers**: Build instructions and the results of some API calls.
- **Volumes**: Contents of Dagger filesystem volumes.

Example using a cache volume for `apt` packages:

**Go:**
```go
func (m *Basics) Env(ctx context.Context) *dagger.Container {
	aptCache := dag.CacheVolume("apt-cache")
	return dag.Container().
		From("debian:latest").
		WithMountedCache("/var/cache/apt/archives", aptCache).
		WithExec([]string{"apt-get", "update"}).
		WithExec([]string{"apt-get", "install", "--yes", "maven", "mariadb-server"})
}
```
