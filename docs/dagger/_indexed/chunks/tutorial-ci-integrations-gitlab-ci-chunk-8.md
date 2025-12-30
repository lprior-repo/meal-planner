---
doc_id: tutorial/ci-integrations/gitlab-ci
chunk_id: tutorial/ci-integrations/gitlab-ci#chunk-8
heading_path: ["gitlab-ci", ".gitlab-ci.yml"]
chunk_type: mixed
tokens: 216
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

test:
  extends: [.dagger]
  script:
    - dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.0 call test --source=.

build:
  extends: [.dagger]
  needs: ["test"]
  script:
    - dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.0 call build-container --source=. --args=. publish --address=ttl.sh/my-app-$RANDOM
```

In both cases, each GitLab Runner must be configured to only run on nodes with pre-provisioned instances of the Dagger Engine. This is achieved using taints and tolerations on the nodes, and pod affinity.

The following code listings illustrate the configuration to be applied to each GitLab Runner, with taints, tolerations and pod affinity set via the `dagger-node` key. For an example of the corresponding node configuration, refer to the [OpenShift](/reference/deployment/openshift) integration page.

To use this configuration, replace the YOUR-GITLAB-URL placeholder with the URL of your GitLab instance and replace the YOUR-GITLAB-RUNNER-TOKEN-REFERENCE placeholder with your [GitLab Runner authentication token](https://docs.gitlab.com/ee/ci/runners/runners_scope.html#create-a-shared-runner-with-a-runner-authentication-token).

```yaml
