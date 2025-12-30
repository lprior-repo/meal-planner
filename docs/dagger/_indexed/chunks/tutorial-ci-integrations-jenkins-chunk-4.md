---
doc_id: tutorial/ci-integrations/jenkins
chunk_id: tutorial/ci-integrations/jenkins#chunk-4
heading_path: ["jenkins", "Example"]
chunk_type: code
tokens: 103
summary: "The following code sample demonstrates how to integrate Dagger with Jenkins."
---
The following code sample demonstrates how to integrate Dagger with Jenkins.

```groovy
// Jenkinsfile
pipeline {
  agent { label 'dagger' }

  // assumes that the Dagger Cloud token
  // is in a Jenkins credential named DAGGER_CLOUD_TOKEN
  environment {
    DAGGER_VERSION = "0.19.7"
    PATH = "/tmp/dagger/bin:$PATH"
    DAGGER_CLOUD_TOKEN =  credentials('DAGGER_CLOUD_TOKEN')
  }

  stages {
    stage("dagger") {
      steps {
        sh '''
          curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=/tmp/dagger/bin DAGGER_VERSION=$DAGGER_VERSION sh
          dagger call -m github.com/shykes/hello hello --greeting "bonjour" --name "from jenkins"
        '''
      }
    }
  }
}
```
