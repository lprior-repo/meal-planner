---
doc_id: tutorial/ci-integrations/gitlab-ci
chunk_id: tutorial/ci-integrations/gitlab-ci#chunk-10
heading_path: ["gitlab-ci", "runner.yml"]
chunk_type: prose
tokens: 27
summary: "apiVersion: apps."
---
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
