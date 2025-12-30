---
doc_id: ops/extending/module-dependencies
chunk_id: ops/extending/module-dependencies#chunk-1
heading_path: ["module-dependencies"]
chunk_type: prose
tokens: 217
summary: "> **Context**: A module reference follows the format: `[proto://]host/repo[/subpath][@version]`, ..."
---
# Module Dependencies

> **Context**: A module reference follows the format: `[proto://]host/repo[/subpath][@version]`, where:


A module reference follows the format: `[proto://]host/repo[/subpath][@version]`, where:

- `host` is the domain name of the Git hosting service, e.g. `github.com`.
- `repo` is the repository path, typically in the format `owner/name`.
- `proto://` is optional and can be either `ssh://` or `https://` if you want to be explicit about the protocol. If omitted, Dagger will automatically choose the protocol based on available authentication methods.
- `/subpath` is optional and specifies a subdirectory within the repository, useful for monorepos.
- `@version` can be a tag, branch, or commit. If omitted, the default branch is used.

For example, in the reference `github.com/shykes/daggerverse/hello@v0.3.0`:

- `github.com` is the host
- `shykes/daggerverse` is the repository
- `hello` is the subpath within the repository
- `v0.3.0` is the version tag

The `.git` extension for the repository is optional for HTTP refs or explicit SSH refs, except for [GitLab, when referencing modules stored on a private repo or private subgroup](https://gitlab.com/gitlab-org/gitlab-foss/-/blob/master/lib/gitlab/middleware/go.rb#L229-237).
