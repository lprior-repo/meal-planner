---
doc_id: tutorial/getting-started/quickstarts-basics
chunk_id: tutorial/getting-started/quickstarts-basics#chunk-7
heading_path: ["quickstarts-basics", "Write custom functions"]
chunk_type: code
tokens: 207
summary: "As your workflows become more complex, you can encapsulate them into custom Dagger Functions."
---
As your workflows become more complex, you can encapsulate them into custom Dagger Functions. These are just regular code consisting of a series of method/function calls.

Here's an example Dagger Function:

**Go:**
```go
func (m *Basics) Publish(ctx context.Context) (string, error) {
	return dag.Container().
		From("alpine:latest").
		WithNewFile("/hi.txt", "Hello from Dagger!").
		WithEntrypoint([]string{"cat", "/hi.txt"}).
		Publish(ctx, "ttl.sh/hello")
}
```

**Python:**
```python
@function
async def publish(self) -> str:
    return await (
        dag.container()
        .from_("alpine:latest")
        .with_new_file("/hi.txt", "Hello from Dagger!")
        .with_entrypoint(["cat", "/hi.txt"])
        .publish("ttl.sh/hello")
    )
```

**TypeScript:**
```typescript
@func()
async publish(): Promise<string> {
  return dag
    .container()
    .from("alpine:latest")
    .withNewFile("/hi.txt", "Hello from Dagger!")
    .withEntrypoint(["cat", "/hi.txt"])
    .publish("ttl.sh/hello")
}
```

To use this function, initialize a new Dagger module:

```bash
dagger init --sdk=go --name=basics  # or python, typescript
```

### Function Names

When calling Dagger Functions, all names (functions, arguments, fields, etc.) are converted into a shell-friendly "kebab-case" style. This is why a Dagger Function named `FooBar` in Go, `foo_bar` in Python and `fooBar` in TypeScript is called as `foo-bar` in Dagger Shell.
