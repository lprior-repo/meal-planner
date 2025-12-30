---
doc_id: meta/extending/modules
chunk_id: meta/extending/modules#chunk-5
heading_path: ["modules", "Remote modules"]
chunk_type: code
tokens: 157
summary: "Dagger can use [remote repositories](."
---
Dagger can use [remote repositories](./tutorial-extending-remote-repositories.md) as Dagger [modules](./ops-features-reusability.md). This feature is compatible with all major Git hosting platforms such as GitHub, GitLab, BitBucket, Azure DevOps, Codeberg, and Sourcehut. Dagger supports authentication via both HTTPS (using Git credential managers) and SSH (using a unified authentication approach).

Here is an example of using a Go builder Dagger module from a public repository over HTTPS:

```bash
dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.0 call \
  build --source=https://github.com/dagger/dagger --args=./cmd/dagger \
  export --path=./build
```

Here is the same example using SSH authentication. Note that this requires [SSH authentication to be properly configured](./tutorial-extending-remote-repositories.md#ssh-authentication) on your Dagger host.

```bash
dagger -m git@github.com:kpenfound/dagger-modules/golang@v0.2.0 call \
  build --source=https://github.com/dagger/dagger --args=./cmd/dagger \
  export --path=./build
```

For more information, refer to the documentation on [remote repository access](./tutorial-extending-remote-repositories.md).
