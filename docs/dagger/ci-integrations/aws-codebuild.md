# AWS CodeBuild

Dagger provides a programmable container engine that allows you to migrate most of your AWS CodeBuild specification into Dagger Functions. This allows you to execute your pipeline the same locally and in AWS CodeBuild, with the additional benefits of intelligent caching and portability.

## How it works

When running a CI pipeline with Dagger using AWS CodeBuild, the general workflow looks like this:

1. AWS CodeBuild receives a trigger based on a repository event.
2. AWS CodeBuild begins processing the build instructions in the `buildspec.yml` file.
3. AWS CodeBuild downloads the Dagger CLI.
4. AWS CodeBuild executes one (or more) Dagger CLI commands, such as `dagger call ...`.
5. The Dagger CLI attempts to find an existing Dagger Engine or spins up a new one inside the GitLab runner.
6. The Dagger CLI calls the specified Dagger Function and sends telemetry to Dagger Cloud if the `DAGGER_CLOUD_TOKEN` environment variable is set.
7. The AWS CodePipeline completes with success or failure. Logs appear in the AWS CodeBuild interface as usual.

## Prerequisites

- An AWS CodeBuild project connected with a source code repository in GitLab, GitHub, BitBucket or any other supported provider

## Example

The following example demonstrates how to call a Dagger Function in an AWS CodeBuild project.

```yaml
# buildspec.yml
version: 0.2

env:
  secrets-manager:
    # assumes that the Dagger Cloud token is
    # in a secret with key dagger_cloud_token
    # set in AWS Secrets Manager
    DAGGER_CLOUD_TOKEN: "arn:aws:secretsmanager:...:dagger_cloud_token"

phases:
  install:
    commands:
      - echo "Installing Dagger CLI"
      - curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=$HOME/.local/bin sh
      - echo "Adding Dagger CLI to $PATH"
      - export PATH=$PATH:$HOME/.local/bin/
  build:
    commands:
      - echo "Calling Dagger Function"
      - dagger -m github.com/shykes/daggerverse/hello@v0.1.2 call hello --greeting="bonjour" --name="monde"
```

The following is a more complex example demonstrating an AWS CodeBuild project that checks out source code, calls a Dagger Function to test the project, and then calls another Dagger Function to build and publish a container image of the project. This example uses a simple [Go application](https://github.com/kpenfound/greetings-api) and assumes that you have already forked it in the repository connected to the AWS CodeBuild project.

```yaml
# buildspec.yml
version: 0.2

env:
  secrets-manager:
    # assumes that the Dagger Cloud token is
    # in a secret with key dagger_cloud_token
    # set in AWS Secrets Manager
    DAGGER_CLOUD_TOKEN: "arn:aws:secretsmanager:...:dagger_cloud_token"

phases:
  install:
    commands:
      - echo "Installing Dagger CLI"
      - curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=$HOME/.local/bin sh
      - echo "Adding Dagger CLI to $PATH"
      - export PATH=$PATH:$HOME/.local/bin/
  pre_build:
    commands:
      - echo "Test"
      - dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.0 call test --source=.
  build:
    commands:
      - echo "Build"
      - dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.0 call build-container --source=. --args=. publish --address=ttl.sh/my-app-$RANDOM
```

## Resources

If you have any questions about additional ways to use AWS CodeBuild with Dagger, join our [Discord](https://discord.gg/dagger-io) and ask your questions in our [AWS channel](https://discord.com/channels/707636530424053791/1122940682714222752).

## About AWS CodeBuild

[AWS CodeBuild](https://aws.amazon.com/codebuild/) is a managed service to test, build and deploy applications in public or private repositories.
