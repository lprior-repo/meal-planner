---
doc_id: concept/getting-started/types-secret
chunk_id: concept/getting-started/types-secret#chunk-3
heading_path: ["types-secret", "Examples"]
chunk_type: code
tokens: 503
summary: "The following Dagger Function accepts a GitHub personal access token as a `Secret`, and uses the ..."
---
### Use secret variables

The following Dagger Function accepts a GitHub personal access token as a `Secret`, and uses the `Secret` to authorize a request to the GitHub API.

**Go:**
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

#### Using Environment Variables

```bash
dagger call github-api --token=env://GITHUB_API_TOKEN
```

#### Passing Files

```bash
dagger call github-api --token=file://./github.txt
```

#### Secrets from command output

```bash
dagger call github-api --token=cmd://"gh auth token"
```

#### 1Password

> **Note:** If using a 1Password service account, ensure that the `OP_SERVICE_ACCOUNT_TOKEN` environment variable is set.

```bash
dagger call github-api --token=op://infra/github/credential
```

#### Hashicorp Vault

> **Note:** Ensure that the `VAULT_ADDR` and either the `VAULT_TOKEN` or `VAULT_APPROLE_ROLE_ID` environment variables are set.

```bash
dagger call github-api --token=vault://credentials.github
```

### Mount files as secrets

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Query the GitHub API
func (m *MyModule) GithubAuth(
	ctx context.Context,
	// GitHub Hosts configuration file
	ghCreds *dagger.Secret,
) (string, error) {
	return dag.Container().
		From("alpine:3.17").
		WithExec([]string{"apk", "add", "github-cli"}).
		WithMountedSecret("/root/.config/gh/hosts.yml", ghCreds).
		WithWorkdir("/root").
		WithExec([]string{"gh", "auth", "status"}).
		Stdout(ctx)
}
```

#### Mounting files

```bash
dagger call github-auth --gh-creds=file://$HOME/.config/gh/hosts.yml
```

### Use secret in Dockerfile build

The following demonstrates how to inject a secret into a Dockerfile build. The secret is automatically mounted in the build container at `/run/secrets/SECRET-ID`.

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Build a Container from a Dockerfile
func (m *MyModule) Build(
	ctx context.Context,
	// The source code to build
	source *dagger.Directory,
	// The secret to use in the Dockerfile
	secret *dagger.Secret,
) (*dagger.Container, error) {
	// Ensure the Dagger secret's name matches what the Dockerfile
	// expects as the id for the secret mount.
	secretVal, err := secret.Plaintext(ctx)
	if err != nil {
		return nil, err
	}
	buildSecret := dag.SetSecret("gh-secret", secretVal)

	return source.
		DockerBuild(dagger.DirectoryDockerBuildOpts{
			Secrets: []*dagger.Secret{buildSecret},
		}), nil
}
```

**Sample Dockerfile:**
```dockerfile
FROM alpine:3.17
RUN apk add curl
RUN --mount=type=secret,id=gh-secret \
    curl "https://api.github.com/repos/dagger/dagger/issues" \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer $(cat /run/secrets/gh-secret)"
```

#### Dockerfile build with mounted secret

```bash
dagger call build --source=. --secret=env://GITHUB_API_TOKEN
```
