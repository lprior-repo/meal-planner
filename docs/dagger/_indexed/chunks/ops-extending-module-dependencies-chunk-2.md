---
doc_id: ops/extending/module-dependencies
chunk_id: ops/extending/module-dependencies#chunk-2
heading_path: ["module-dependencies", "Installation"]
chunk_type: code
tokens: 473
summary: "You can call Dagger Functions from any other Dagger module in your own Dagger module simply by ad..."
---
You can call Dagger Functions from any other Dagger module in your own Dagger module simply by adding it as a module dependency with `dagger install`, as in the following example:

```bash
dagger install github.com/shykes/daggerverse/hello@v0.3.0
```

This module will be added to your `dagger.json`:

```json
...
"dependencies": [
  {
    "name": "hello",
    "source": "github.com/shykes/daggerverse/hello@54d86c6002d954167796e41886a47c47d95a626d"
  }
]
```

When you add a dependency to your module with `dagger install`, the dependent module will be added to the code-generation routines and can be accessed from your own module's code.

The entrypoint to accessing dependent modules from your own module's code is `dag`, the Dagger client, which is pre-initialized. It contains all the core types (like `Container`, `Directory`, etc.), as well as bindings to any dependencies your module has declared.

Here is an example of accessing the installed `hello` module from your own module's code:

**Go:**
```go
func (m *MyModule) Greeting(ctx context.Context) (string, error) {
  return dag.Hello().Hello(ctx)
}
```

**Python:**
```python
@function
async def greeting(self) -> str:
  return await dag.hello().hello()
```

**TypeScript:**
```typescript
@func()
async greeting(): Promise<string> {
  return await dag.hello().hello()
}
```

**PHP:**
```php
#[DaggerFunction]
public function greeting(): string
{
    return dag()->hello()->hello();
}
```

**Java:**
```java
@Function
public String greeting() throws ExecutionException, DaggerQueryException, InterruptedException {
    return dag().hello().hello();
}
```

You can also use local modules as dependencies, as long as they are in the same git repository. For example:

```bash
dagger install ./path/to/module
```

> **Note:** Installing a module using a local path (relative or absolute) is only possible if your module is within the repository root (for Git repositories) or the directory containing the `dagger.json` file (for all other cases).

### Private modules

You can also install private modules from remote repositories, as long as you have access to them. Dagger supports authentication via both HTTPS (using Git credential managers) and SSH (using `SSH_AUTH_SOCK`). For more information, see the [documentation on remote repositories](./tutorial-extending-remote-repositories.md).

When installing a private module, you can use either the normal ref style (preferred if possible, since it allows any available authentication method to be used), or explicitly specify the protocol. For example, the following commands all install the same private module:

```bash
dagger install github.com/username/private-repo/module
dagger install https://github.com/username/private-repo/module
dagger install ssh://git@github.com/username/private-repo/module
```
