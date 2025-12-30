---
doc_id: tutorial/ci-integrations/gitlab-ci
chunk_id: tutorial/ci-integrations/gitlab-ci#chunk-5
heading_path: ["gitlab-ci", ".gitlab-ci.yml"]
chunk_type: prose
tokens: 173
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

hello:
  extends: [.dagger]
  script:
    - dagger -m github.com/shykes/daggerverse/hello@v0.1.2 call hello --greeting="bonjour" --name="monde"
```

The following is a more complex example demonstrating how to create a GitLab pipeline that checks out source code, calls a Dagger Function to test the project, and then calls another Dagger Function to build and publish a container image of the project. This example uses a simple [Go application](https://github.com/kpenfound/greetings-api) and assumes that you have already forked it in your own GitLab repository.

```yaml
