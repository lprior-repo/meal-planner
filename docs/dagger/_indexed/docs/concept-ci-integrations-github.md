---
id: concept/ci-integrations/github
title: "GitHub"
category: concept
tags: ["docker", "module", "function", "container", "concept"]
---

# GitHub

> **Context**: Dagger can directly interact with GitHub pull requests, making it easy to test the functionality of specific forks or branches of a GitHub repository.


Dagger can directly interact with GitHub pull requests, making it easy to test the functionality of specific forks or branches of a GitHub repository.

Dagger also supports publishing container images to [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

## How it works

GitHub contains a shorthand redirect at the `/merge` endpoint that allows you to reference the correct branch of a repository from a pull request (PR), without needing to know anything about the fork or branch where the PR came from.

By default, the Dagger `Directory` type works with both local directories and [remote Git repositories](./tutorial-extending-remote-repositories.md). This makes it possible to work with the directory tree at the root of a Git repository or a given branch.

By combining these two features, Dagger users can write Dagger Functions that directly use GitHub pull requests as arguments.

## Prerequisites

- A GitHub repository

## Examples

Given a Dagger Function called `foo` that accepts a `Directory` as argument, you can pass it a GitHub pull request URL as argument like this:

```
dagger call foo --directory=https://github.com/ORGANIZATION/REPOSITORY#pull/NUMBER/merge
```

If your GitHub repository contains a Dagger module, you can test the functionality of a specific branch by calling the Dagger module with the corresponding pull request URL, as shown below:

```
dagger call -m github.com/ORGANIZATION/REPOSITORY@pull/NUMBER/merge --help
```

You can also use a Dagger Function in a GitHub Actions workflow to publish a container image to GitHub Container Registry.

```yaml
## .github/workflows/dagger.yml
name: dagger

on:
  push:
    branches: [main]

jobs:
  build-publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Call Dagger Function to build and publish to ghcr.io
        uses: dagger/dagger-for-github@v8.2.0
        with:
          version: "latest"
          verb: call
          module: github.com/daggerverse/dagger-ghcr-demo@v0.1.5
          args: build-and-push --registry=$DOCKER_REGISTRY --image-name=$DOCKER_IMAGE_NAME --username=$DOCKER_USERNAME --password=env://DOCKER_PASSWORD --build-context=github.com/daggerverse/dagger-ghcr-demo
          # assumes the Dagger Cloud token is in
          # a repository secret named DAGGER_CLOUD_TOKEN
          # set via the GitHub UI/CLI
          cloud-token: ${{ secrets.DAGGER_CLOUD_TOKEN }}
        env:
          DOCKER_REGISTRY: ghcr.io
          DOCKER_IMAGE_NAME: ${{ github.repository }}
          DOCKER_USERNAME: ${{ github.actor }}
          # assumes the container registry password is in
          # a repository secret named REGISTRY_PASSWORD
          # set via the GitHub UI/CL
          DOCKER_PASSWORD: ${{ secrets.REGISTRY_PASSWORD }}
```

## Resources

If you have any questions about additional ways to use GitHub with Dagger, join our [Discord](https://discord.gg/dagger-io) and ask your questions in our [GitHub channel](https://discord.com/channels/707636530424053791/1117139064274034809).

## About GitHub

[GitHub](https://github.com/) is a popular Web-based platform used for version control and collaboration. It allows developers to store and manage their code in repositories, track changes over time, and collaborate with other developers on projects.

## See Also

- [remote Git repositories](./tutorial-extending-remote-repositories.md)
