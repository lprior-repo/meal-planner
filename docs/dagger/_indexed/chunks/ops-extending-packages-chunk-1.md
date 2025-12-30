---
doc_id: ops/extending/packages
chunk_id: ops/extending/packages#chunk-1
heading_path: ["packages"]
chunk_type: mixed
tokens: 547
summary: "> **Context**: Dagger Functions are just regular code, written in your usual programming language."
---
# Third-Party Packages

> **Context**: Dagger Functions are just regular code, written in your usual programming language. One of the key advantages of this approach is that it opens up acc...


Dagger Functions are just regular code, written in your usual programming language. One of the key advantages of this approach is that it opens up access to your language's existing ecosystem of packages or modules. You can easily import these packages/modules in your Dagger module via your language's package manager.

**Go:**

To add a Go module, add it to your `go.mod` file using `go get`. For example:

```bash
go get github.com/spf13/cobra
```

Dagger lets you import [private Go modules](https://go.dev/ref/mod#private-modules) in your Dagger module. To do this, add the URL to the private repository(ies) hosting the module(s) in a `config.goprivate` key in the module's `dagger.json` file, as shown below:

```json
{
  "sdk": {
    "source": "go",
    "config": {
      "goprivate": "github.com/user/repository",
    },
  },
}
```

Multiple URLs can be specified as comma-separated values. The repository name is optional; if left unspecified, all modules under the specified prefix will be included.

Note that this feature requires a `.gitconfig` file entry to use SSH instead of HTTPS for the host. Use the command `git config --global url."git@github.com:".insteadOf "https://github.com/"` to create the necessary `.gitconfig` entry.

**Python:**

To add a Python package, add it to your `pyproject.toml` file using your chosen package manager.

Using uv:
```bash
uv add requests
```

Using poetry:
```bash
poetry add requests
```

Or add the dependency manually to `pyproject.toml`:

```toml
[project]
dependencies = [
    "requirements>=2.32.3",
]
```

> **Tip:** If you haven't setup your local environment yet, see [IDE Integration](./ops-reference-ide-setup.md).

**TypeScript:**

To add TypeScript packages, use the package manager for your chosen runtime. For example:

Using Node.js:
```bash
npm install pm2
```

Using Bun:
```bash
bun install pm2
```

Using Deno:
```bash
deno add jsr:@celusion/simple-validation
```

Pinning a specific dependency version or adding local dependencies are supported, in the same way as any Node.js project.

**PHP:**

To add a PHP package, add it to the `composer.json` file, the same way as any PHP project. For example:

```bash
composer require phpunit/phpunit
```

> **Note:** Dagger modules installed as packages via Composer are not registered with Dagger. You can access its code, like any other PHP package, but this is not the intended use-case of a Dagger module. Use Composer for standard third-party packages. Use Dagger to [install Dagger modules](./ops-extending-module-dependencies.md).

**Java:**

To add a Java package, add it to your `pom.xml` file using Maven. For example:

```xml
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-simple</artifactId>
    <scope>runtime</scope>
    <version>2.0.16</version>
</dependency>
```
