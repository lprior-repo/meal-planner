---
doc_id: tutorial/ci-integrations/gitlab-ci
chunk_id: tutorial/ci-integrations/gitlab-ci#chunk-4
heading_path: ["gitlab-ci", "Examples"]
chunk_type: prose
tokens: 60
summary: "The following example demonstrates how to call a Dagger Function in a GitLab CI/CD pipeline using..."
---
### Docker executor

The following example demonstrates how to call a Dagger Function in a GitLab CI/CD pipeline using the (default) [Docker Machine executor](https://docs.gitlab.com/runner/executors/docker_machine.html) or the [Docker executor](https://docs.gitlab.com/runner/executors/docker.html). In both these cases, the Dagger Engine is provisioned "just in time" using a Docker-in-Docker (`dind`) service.

```yaml
