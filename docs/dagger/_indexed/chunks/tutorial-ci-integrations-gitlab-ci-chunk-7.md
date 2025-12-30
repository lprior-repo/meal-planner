---
doc_id: tutorial/ci-integrations/gitlab-ci
chunk_id: tutorial/ci-integrations/gitlab-ci#chunk-7
heading_path: ["gitlab-ci", ".gitlab-ci.yml"]
chunk_type: mixed
tokens: 150
summary: ".dagger:
  image: alpine:latest
  variables:
    # assumes the Dagger Cloud token is
    # in a mask"
---
.dagger:
  image: alpine:latest
  variables:
    # assumes the Dagger Cloud token is
    # in a masked/protected variable named DAGGER_CLOUD_TOKEN
    # set via the GitLab UI
    DAGGER_CLOUD_TOKEN: $DAGGER_CLOUD_TOKEN
  before_script:
    - apk add curl
    - curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=/tmp sh

hello:
  extends: [.dagger]
  script:
    - dagger -m github.com/shykes/daggerverse/hello@v0.1.2 call hello --greeting="bonjour" --name="monde"
```

The following is a more complex example demonstrating how to create a GitLab pipeline that checks out source code, calls a Dagger Function to test the project, and then calls another Dagger Function to build and publish a container image of the project. This example uses a simple [Go application](https://github.com/kpenfound/greetings-api) and assumes that you have already forked it in your own GitLab repository.

```yaml
