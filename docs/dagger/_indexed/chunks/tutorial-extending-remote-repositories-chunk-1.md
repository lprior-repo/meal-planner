---
doc_id: tutorial/extending/remote-repositories
chunk_id: tutorial/extending/remote-repositories#chunk-1
heading_path: ["remote-repositories"]
chunk_type: prose
tokens: 273
summary: "> **Context**: Dagger supports the use of HTTP and SSH protocols for accessing directories, files..."
---
# Remote Repositories

> **Context**: Dagger supports the use of HTTP and SSH protocols for accessing directories, files, and Dagger modules in remote repositories. This feature is compati...


Dagger supports the use of HTTP and SSH protocols for accessing directories, files, and Dagger modules in remote repositories. This feature is compatible with all major Git hosting platforms such as GitHub, GitLab, BitBucket, Azure DevOps, Codeberg, and Sourcehut. Dagger supports authentication via both HTTPS (using Git credential managers) and SSH (using a unified authentication approach).

Dagger supports the following reference schemes for directory and file arguments:

| Protocol | Scheme | Authentication | Example |
|----------|--------|----------------|---------|
| HTTP(S) | Git HTTP | Git credential manager | `https://github.com/username/repo.git[#version[:subpath]]` |
| SSH | Explicit | SSH keys | `ssh://git@github.com/username/repo.git[#version[:subpath]]` |
| SSH | SCP-like | SSH keys | `git@github.com:username/repo.git[#version[:subpath]]` |

Dagger provides additional flexibility in referencing file and directory arguments through the following options:

- **Version specification**: Add `#version` to target a particular version of the repository. This can be a tag, branch name, or full commit hash. If omitted, the default branch is used.
- **Monorepo support**: Append `:subpath` after the version specification to access a specific subdirectory within the repository. Note that specifying a version is mandatory when including a subpath.
