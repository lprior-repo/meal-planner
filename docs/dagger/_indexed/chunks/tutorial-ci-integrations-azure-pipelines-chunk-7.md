---
doc_id: tutorial/ci-integrations/azure-pipelines
chunk_id: tutorial/ci-integrations/azure-pipelines#chunk-7
heading_path: ["azure-pipelines", "branch checkout required to prevent azure pipeline traces from being orphaned in the Dagger Cloud UI"]
chunk_type: mixed
tokens: 176
summary: "- script: git checkout $(Build."
---
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
