---
doc_id: tutorial/ci-integrations/gitlab-ci
chunk_id: tutorial/ci-integrations/gitlab-ci#chunk-6
heading_path: ["gitlab-ci", ".gitlab-ci.yml"]
chunk_type: prose
tokens: 139
summary: ".docker:
  image: docker:latest
  services:
    - docker:${DOCKER_VERSION}-dind
  variables:
    DOC"
---
.docker:
  image: docker:latest
  services:
    - docker:${DOCKER_VERSION}-dind
  variables:
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_VERIFY: '1'
    DOCKER_TLS_CERTDIR: '/certs'
    DOCKER_CERT_PATH: '/certs/client'
    DOCKER_DRIVER: overlay2
    DOCKER_VERSION: '27.2.0'
    # assumes the Dagger Cloud token is
    # in a masked/protected variable named DAGGER_CLOUD_TOKEN
    # set via the GitLab UI
    DAGGER_CLOUD_TOKEN: $DAGGER_CLOUD_TOKEN

.dagger:
  extends: [.docker]
  before_script:
    - apk add curl
    - curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=/usr/local/bin sh

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

### Kubernetes executor

The following example demonstrates how to call a Dagger Function in a GitLab CI/CD pipeline using the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/).

```yaml
