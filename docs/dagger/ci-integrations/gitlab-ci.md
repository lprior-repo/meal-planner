# GitLab CI

Dagger provides a programmable container engine that allows you to replace your YAML pipeline definitions in GitLab with Dagger Functions written in a regular programming language. This allows you to execute your pipeline the same locally and in GitLab, with the additional benefit of intelligent caching.

## How it works

When running a CI pipeline with Dagger using GitLab CI, the general workflow looks like this:

1. GitLab receives a trigger based on a repository event.
2. GitLab begins processing the stages and jobs in the `.gitlab-ci.yml` file.
3. GitLab downloads the Dagger CLI.
4. GitLab executes one (or more) Dagger CLI commands, such as `dagger call ...`.
5. The Dagger CLI attempts to find an existing Dagger Engine or spins up a new one inside the GitLab runner.
6. The Dagger CLI calls the specified Dagger Function and sends telemetry to Dagger Cloud if the `DAGGER_CLOUD_TOKEN` environment variable is set.
7. The pipeline completes with success or failure. Logs appear in GitLab as usual.

## Prerequisites

- A GitLab repository
- Any one of the following:
  - [GitLab-hosted runners](https://docs.gitlab.com/ee/ci/runners/index.html) using the (default) [Docker Machine executor](https://docs.gitlab.com/runner/executors/docker_machine.html)
  - [Self-managed GitLab Runners](https://docs.gitlab.com/runner/install/index.html) using the [Docker executor](https://docs.gitlab.com/runner/executors/docker.html).
  - [Self-managed GitLab Runners](https://docs.gitlab.com/runner/install/index.html) in a Kubernetes cluster and using the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/).

## Examples

### Docker executor

The following example demonstrates how to call a Dagger Function in a GitLab CI/CD pipeline using the (default) [Docker Machine executor](https://docs.gitlab.com/runner/executors/docker_machine.html) or the [Docker executor](https://docs.gitlab.com/runner/executors/docker.html). In both these cases, the Dagger Engine is provisioned "just in time" using a Docker-in-Docker (`dind`) service.

```yaml
# .gitlab-ci.yml
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
# .gitlab-ci.yml
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
# .gitlab-ci.yml
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
# .gitlab-ci.yml
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
# runner-config.yml
kind: ConfigMap
apiVersion: v1
metadata:
  name: dagger-custom-config-toml
data:
  config.toml: |
    concurrent = 10
    [[runners]]
      environment = ["HOME=/tmp","FF_GITLAB_REGISTRY_HELPER_IMAGE=1", "_EXPERIMENTAL_DAGGER_RUNNER_HOST=unix:///run/dagger/engine.sock"]
      pre_build_script = "export PATH=\"/tmp/:$PATH\""
      name = "GitLab Runner with Dagger"
      url = YOUR-GITLAB-URL
      executor = "kubernetes"
      [runners.kubernetes]
        namespace = "dagger"
        pull_policy = "always"
        privileged = true
      [runners.kubernetes.affinity]
      [runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution]
        [[runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution.node_selector_terms]]
          [[runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution.node_selector_terms.match_expressions]]
            key = "dagger-node"
            operator = "In"
            values = ["true"]
      [runners.kubernetes.node_tolerations]
        "dagger-node" = ""
      [runners.kubernetes.pod_security_context]
        run_as_non_root = false
        run_as_user = 0
        [[runners.kubernetes.volumes.host_path]]
          name = "dagger"
          mount_path = "/run/dagger"
          host_path = "/run/dagger"
```

```yaml
# runner.yml
apiVersion: apps.gitlab.com/v1beta2
kind: Runner
metadata:
  name: dagger-runner
  namespace: dagger
spec:
  config: dagger-custom-config-toml
  gitlabUrl: YOUR-GITLAB-URL
  tags: dagger
  token: YOUR-GITLAB-RUNNER-TOKEN-REFERENCE
  runUntagged: false
```

## Resources

If you have any questions about additional ways to use GitLab with Dagger, join our [Discord](https://discord.gg/dagger-io) and ask your questions in our [GitLab channel](https://discord.com/channels/707636530424053791/1122940615806685296).

## About GitLab

[GitLab](https://gitlab.com/) is a popular Web-based platform used for version control and collaboration. It allows developers to store and manage their code in repositories, track changes over time, and collaborate with other developers on projects.
