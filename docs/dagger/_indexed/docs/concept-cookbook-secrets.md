---
id: concept/cookbook/secrets
title: "Secrets"
category: concept
tags: ["docker", "module", "function", "container", "concept"]
---

# Secrets

> **Context**: This page contains practical examples for working with secrets in Dagger. Each section below provides code examples in multiple languages and demonstr...


This page contains practical examples for working with secrets in Dagger. Each section below provides code examples in multiple languages and demonstrates different approaches to secret management and usage.

## Use secret variables

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

## Mount files as secrets

The following Dagger Function accepts a GitHub hosts configuration file as a `Secret`, and mounts the file as a `Secret` to a container to authorize a request to GitHub.

### Go

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

### Python

```python
from typing import Annotated

import dagger
from dagger import Doc, dag, function, object_type

@object_type
class MyModule:
    @function
    async def github_auth(
        self,
        gh_creds: Annotated[dagger.Secret, Doc("GitHub Hosts configuration file")],
    ) -> str:
        """Query the GitHub API"""
        return await (
            dag.container()
            .from_("alpine:3.17")
            .with_exec(["apk", "add", "github-cli"])
            .with_mounted_secret("/root/.config/gh/hosts.yml", gh_creds)
            .with_workdir("/root")
            .with_exec(["gh", "auth", "status"])
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
  async githubAuth(
    /**
     * GitHub Hosts configuration File
     */
    ghCreds: Secret,
  ): Promise<string> {
    return await dag
      .container()
      .from("alpine:3.17")
      .withExec(["apk", "add", "github-cli"])
      .withMountedSecret("/root/.config/gh/hosts.yml", ghCreds)
      .withExec(["gh", "auth", "status"])
      .stdout()
  }
}
```

### Mounting files

To mount a file as a secret, you can use the following:

```bash
dagger call github-auth --gh-creds=file://$HOME/.config/gh/hosts.yml
```

## Use secret in Dockerfile build

The following code listing demonstrates how to inject a secret into a Dockerfile build. The secret is automatically mounted in the build container at `/run/secrets/SECRET-ID`.

### Go

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

### Python

```python
from typing import Annotated

import dagger
from dagger import Doc, dag, function, object_type

@object_type
class MyModule:
    @function
    async def build(
        self,
        source: Annotated[dagger.Directory, Doc("The source code to build")],
        secret: Annotated[dagger.Secret, Doc("The secret to use in the Dockerfile")],
    ) -> dagger.Container:
        """Build a Container from a Dockerfile"""
        # Ensure the Dagger secret's name matches what the Dockerfile
        # expects as the id for the secret mount.
        build_secret = dag.set_secret("gh-secret", await secret.plaintext())
        return source.docker_build(secrets=[build_secret])
```

### TypeScript

```typescript
import { dag, object, func, Secret } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Build a Container from a Dockerfile
   */
  @func()
  async build(
    /**
     * The source code to build
     */
    source: Directory,
    /**
     * The secret to use in the Dockerfile
     */
    secret: Secret,
  ): Promise<Container> {
    // Ensure the Dagger secret's name matches what the Dockerfile
    // expects as the id for the secret mount.
    const buildSecret = dag.setSecret("gh-secret", await secret.plaintext())
    return source.dockerBuild({ secrets: [buildSecret] })
  }
}
```

The sample Dockerfile below demonstrates the process of mounting the secret using a secret filesystem mount type and using it in the Dockerfile build process:

```dockerfile
FROM alpine:3.17
RUN apk add curl
RUN --mount=type=secret,id=gh-secret \
    curl "https://api.github.com/repos/dagger/dagger/issues" \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer $(cat /run/secrets/gh-secret)"
```

### Dockerfile build with mounted secret

Build from a Dockerfile with a mounted secret from the host environment:

```bash
dagger call build --source=. --secret=env://GITHUB_API_TOKEN
```

## Customize secret caching behavior

By default, the layer cache entries for operations that include a secret will be based on the plaintext value of the secret. Operations that include secrets with the same plaintext value may share cache entries, but if the plaintext differs then the operation will not share cache entries.

In some cases, users may desire that operations share the layer cache entries even if the secret plaintext value is different. For example, a secret may often rotate in plaintext value but not be meaningfully different; in these cases, it should still be possible to reuse the cache for operations that include that secret.

For these use cases, the optional `cacheKey` argument to `Secret` construction can be used to specify the "cache key" of the secret. Secrets that share the same `cacheKey` will be considered equivalent when checking the layer cache for operations that include them, even if their plaintext value differs.

### Example

Use a secret with a specified cache key:

```bash
dagger call github-api --token=env://GITHUB_API_TOKEN?cacheKey=my-cache-key
```

## See Also

- [Documentation Overview](./COMPASS.md)
