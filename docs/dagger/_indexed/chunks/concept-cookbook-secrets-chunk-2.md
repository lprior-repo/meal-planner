---
doc_id: concept/cookbook/secrets
chunk_id: concept/cookbook/secrets#chunk-2
heading_path: ["secrets", "Use secret variables"]
chunk_type: code
tokens: 493
summary: "The following Dagger Function accepts a GitHub personal access token as a `Secret`, and uses the ..."
---
The following Dagger Function accepts a GitHub personal access token as a `Secret`, and uses the `Secret` to authorize a request to the GitHub API. The secret may be sourced from the host (via an environment variable, host file, or host command) or from an external secrets manager (1Password or Vault):

### Go

```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Query the GitHub API
func (m *MyModule) GithubApi(
	ctx context.Context,
	// GitHub API token
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

### Python

```python
from typing import Annotated

import dagger
from dagger import Doc, dag, function, object_type

@object_type
class MyModule:
    @function
    async def github_api(
        self,
        token: Annotated[dagger.Secret, Doc("GitHub API token")],
    ) -> str:
        """Query the GitHub API"""
        return await (
            dag.container(platform=dagger.Platform("linux/amd64"))
            .from_("alpine:3.17")
            .with_secret_variable("GITHUB_API_TOKEN", token)
            .with_exec(["apk", "add", "curl"])
            .with_exec(
                [
                    "sh",
                    "-c",
                    (
                        'curl "https://api.github.com/repos/dagger/dagger/issues"'
                        ' --header "Authorization: Bearer $GITHUB_API_TOKEN"'
                        ' --header "Accept: application/vnd.github+json"'
                    ),
                ]
            )
            .stdout()
        )
```

### TypeScript

```typescript
import { dag, object, func, Secret } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Query the GitHub API
   */
  @func()
  async githubApi(
    /**
     * GitHub API token
     */
    token: Secret,
  ): Promise<string> {
    return await dag
      .container()
      .from("alpine:3.17")
      .withSecretVariable("GITHUB_API_TOKEN", token)
      .withExec(["apk", "add", "curl"])
      .withExec([
        "sh",
        "-c",
        `curl "https://api.github.com/repos/dagger/dagger/issues" --header "Accept: application/vnd.github+json" --header "Authorization: Bearer $GITHUB_API_TOKEN"`,
      ])
      .stdout()
  }
}
```

### Using Environment Variables

You can use a secret sourced from an environment variable by running the following command:

```bash
dagger call github-api --token=env://GITHUB_API_TOKEN
```

### Passing Files

You can also pass files to secrets by following the example below:

```bash
dagger call github-api --token=file://./github.txt
```

### Secrets from command output

Secrets also support capturing data from running commands.

```bash
dagger call github-api --token=cmd://"gh auth token"
```

### 1Password

Use a secret from 1Password:

> **Note**: If using a 1Password service account, ensure that the `OP_SERVICE_ACCOUNT_TOKEN` environment variable is set.

```bash
export OP_SERVICE_ACCOUNT_TOKEN="mytoken"
dagger call github-api --token=op://infra/github/credential
```

### Hashicorp Vault

You can retrieve secrets from Hashicorp Vault.

> **Note**: Ensure that the `VAULT_ADDR` and either the `VAULT_TOKEN` or `VAULT_APPROLE_ROLE_ID` (for Vault AppRole authentication) environment variables are set.

```bash
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_TOKEN="gue55me7"
export VAULT_APPROLE_ROLE_ID="roleid-xxx-yyy-zzz"
dagger call github-api --token=vault://credentials.github
```
