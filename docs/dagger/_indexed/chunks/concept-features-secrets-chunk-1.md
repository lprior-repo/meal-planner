---
doc_id: concept/features/secrets
chunk_id: concept/features/secrets#chunk-1
heading_path: ["secrets"]
chunk_type: code
tokens: 428
summary: "> **Context**: Dagger natively supports reading confidential information (\"secrets\"), such as pas..."
---
# Secrets Integration

> **Context**: Dagger natively supports reading confidential information ("secrets"), such as passwords, API keys, SSH keys, and access tokens, from multiple secret...


Dagger natively supports reading confidential information ("secrets"), such as passwords, API keys, SSH keys, and access tokens, from multiple secret providers and has built-in safeguards to ensure that secrets do not leak into the open.

These secrets can be sourced from different secret providers, including the host environment, the host filesystem, the result of host command execution, and external secret managers [1Password](https://1password.com/) and [Vault](https://www.hashicorp.com/products/vault).

> **Important:** Dagger has built-in safeguards to ensure that secrets are used without exposing them in plaintext logs, writing them into the filesystem of containers you're building, or inserting them into the cache. This ensures that sensitive data does not leak - for example, in the event of a crash.

Here's an example of a workflow that receives and uses a GitHub personal access token as a secret (Go):

```go
package main

import (
    "context"
    "dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) GithubApi(
    ctx context.Context,
    token *dagger.Secret,
) (string, error) {
    return dag.Container().
        From("alpine:3.17").
        WithSecretVariable("GITHUB_API_TOKEN", token).
        WithExec([]string{"apk", "add", "curl"}).
        WithExec([]string{"sh", "-c", `curl "https://api.github.com/repos/dagger/dagger/issues" --header "Accept: application/vnd.github+json" --header "Authorization: Bearer $GITHUB_API_TOKEN"`}).
        Stdout(ctx)
}
```

### Host environment

The secret can be passed from the host environment via the `env` provider:

```bash
dagger call github-api --token=env:GITHUB_API_TOKEN
```

### Files

Secrets can also be passed from host files via the `file` provider (shown below) or from host command output via the `cmd` provider:

```bash
dagger call github-api --token=file:./github-token.txt
```

### Hashicorp Vault and 1Password

Secrets can also be read from external secret managers, such as Vault (`vault`):

```bash
dagger call github-api --token=vault://credentials.github
```

Here is the same example, but using 1Password as the secret provider. The secret is passed from 1Password via the `op` provider. This requires the Dagger CLI to be authenticated with 1Password, which can be done by running `op signin` in the terminal.

```bash
dagger call github-api --token=op://infra/github/credential
```
