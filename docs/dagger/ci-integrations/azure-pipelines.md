# Azure Pipelines

Dagger provides a programmable container engine that allows you to replace your YAML Azure Pipelines definitions with Dagger Functions written in a regular programming language. This allows you to execute your pipeline the same way locally and in CI, with the additional benefit of intelligent caching.

## How it works

When running a CI pipeline with Dagger using Azure Pipelines, the general workflow looks like this:

1. Azure Pipelines receives a trigger based on a repository event.
2. Azure Pipelines begins processing the steps in the `azure-pipelines.yml` file.
3. Azure Pipelines downloads the Dagger CLI.
4. Azure Pipelines executes one (or more) Dagger CLI commands, such as `dagger call ...`.
5. The Dagger CLI attempts to find an existing Dagger Engine or spins up a new one inside the Azure Pipelines runner.
6. The Dagger CLI calls the specified Dagger Function and sends telemetry to Dagger Cloud if the `DAGGER_CLOUD_TOKEN` environment variable is set.
7. The pipeline completes with success or failure. Logs appear in Azure Pipelines as usual.

## Prerequisites

- An Azure DevOps organization and project
- An Azure Pipelines agent to run jobs connected to the project

## Examples

### Docker executor

The following example demonstrates how to call a Dagger Function in an Azure Pipeline.

```yaml
# azure-pipelines.yml
trigger:
- main

pool:
  name: 'Azure Pipelines'
  vmImage: ubuntu-latest

steps:
# full clone checkout required to prevent azure pipeline traces from being orphaned in the Dagger Cloud UI
- checkout: self
  fetchDepth: 0
  displayName: 'Checkout Source Code, fetch full history'
# branch checkout required to prevent azure pipeline traces from being orphaned in the Dagger Cloud UI
- script: git checkout $(Build.SourceBranchName)
  displayName: 'Checkout Source Branch'
- script: curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=$HOME/.local/bin sh
  displayName: 'Install Dagger CLI'
- script: dagger -m github.com/shykes/daggerverse/hello@v0.1.2 call hello --greeting="bonjour" --name="monde"
  displayName: 'Call Dagger Function'
  env:
    # assumes the Dagger Cloud token is
    # in a secret named DAGGER_CLOUD_TOKEN
    # set via the Azure Pipeline settings UI/CLI
    # the secret is then explicitly mapped to the script env
    DAGGER_CLOUD_TOKEN: $(DAGGER_CLOUD_TOKEN)
```

The following is a more complex example demonstrating how to create an Azure Pipeline that checks out source code, calls a Dagger Function to test the project, and then calls another Dagger Function to build and publish a container image of the project. This example uses a simple [Go application](https://github.com/kpenfound/greetings-api) and assumes that you have already imported it into your Azure DevOps project repository.

```yaml
# azure-pipelines.yml
trigger:
- main

pool:
  name: 'Azure Pipelines'
  vmImage: ubuntu-latest

steps:
# full clone checkout required to prevent azure pipeline traces from being orphaned in the Dagger Cloud UI
- checkout: self
  fetchDepth: 0
  displayName: 'Checkout Source Code, fetch full history'
# branch checkout required to prevent azure pipeline traces from being orphaned in the Dagger Cloud UI
- script: git checkout $(Build.SourceBranchName)
  displayName: 'Checkout Source Branch'
- script: curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=$HOME/.local/bin sh
  displayName: 'Install Dagger CLI'
- script: dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.0 call test --source=.
  displayName: 'Test'
  env:
    # assumes the Dagger Cloud token is
    # in a secret named DAGGER_CLOUD_TOKEN
    # set via the Azure Pipeline settings UI/CLI
    # the secret is then explicitly mapped to the script env
    DAGGER_CLOUD_TOKEN: $(DAGGER_CLOUD_TOKEN)
- script: dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.0 call build-container --source=. --args=. publish --address=ttl.sh/my-app-$RANDOM
  displayName: 'Build'
  env:
    DAGGER_CLOUD_TOKEN: $(DAGGER_CLOUD_TOKEN)
```

## Resources

If you have any questions about additional ways to use Azure Pipelines with Dagger, join our [Discord](https://discord.gg/dagger-io) and ask your questions in our [help channel](https://discord.com/channels/707636530424053791/1030538312508776540).

## About Azure Pipelines

[Azure Pipelines](https://azure.microsoft.com/en-us/products/devops/pipelines) is the CI/CD service of Azure DevOps. It enables developers to quickly and easily build, test and deploy their applications, and works with multiple languages and platforms. It supports both self-hosted and managed agents.
