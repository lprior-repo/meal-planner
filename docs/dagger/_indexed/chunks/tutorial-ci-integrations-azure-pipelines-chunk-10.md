---
doc_id: tutorial/ci-integrations/azure-pipelines
chunk_id: tutorial/ci-integrations/azure-pipelines#chunk-10
heading_path: ["azure-pipelines", "branch checkout required to prevent azure pipeline traces from being orphaned in the Dagger Cloud UI"]
chunk_type: prose
tokens: 108
summary: "- script: git checkout $(Build."
---
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
