---
doc_id: tutorial/ci-integrations/aws-codebuild
chunk_id: tutorial/ci-integrations/aws-codebuild#chunk-5
heading_path: ["aws-codebuild", "buildspec.yml"]
chunk_type: prose
tokens: 174
summary: "version: 0."
---
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
