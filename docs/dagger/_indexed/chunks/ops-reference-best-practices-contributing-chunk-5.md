---
doc_id: ops/reference/best-practices-contributing
chunk_id: ops/reference/best-practices-contributing#chunk-5
heading_path: ["best-practices-contributing", "Contribution Workflow"]
chunk_type: prose
tokens: 233
summary: "Find or [report an issue on GitHub](https://github."
---
### 1. Claim an issue

Find or [report an issue on GitHub](https://github.com/dagger/dagger/issues). Write a comment to declare your intention to contribute a solution.

### 2. Communicate

For bigger contributions, communicate upfront your plan and design. Communicate early and often!

### 3. Develop

#### Manual testing

```bash
dagger call playground terminal
```

#### Integration testing

- Run all core tests: `dagger call test all`
- Run available core tests: `dagger call test list`
- Run SDK tests: `dagger call test-sdks`

#### Linting

```bash
dagger call lint
```

#### Local docs server

```bash
dagger -m docs call server up
```

### 4. Prepare your pull request

- Generate API docs: `dagger call generate`
- Run all linters: `dagger call lint`
- Add a release note: `changie new`
- Sign-off commits with `git commit -s`

### 5. Submit your pull request

Push your feature branch to your fork and create a new pull request.

### 6. Review process

- A maintainer will review your pull request
- Make changes if requested
- Rebase on top of latest `main` if there are conflicts
