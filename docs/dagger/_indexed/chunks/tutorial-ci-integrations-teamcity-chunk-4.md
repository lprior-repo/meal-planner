---
doc_id: tutorial/ci-integrations/teamcity
chunk_id: tutorial/ci-integrations/teamcity#chunk-4
heading_path: ["teamcity", "Example"]
chunk_type: code
tokens: 204
summary: "The following code sample demonstrates how to integrate Dagger with TeamCity."
---
The following code sample demonstrates how to integrate Dagger with TeamCity. The code is written using the [TeamCity Kotlin DSL](https://www.jetbrains.com/help/teamcity/kotlin-dsl.html).

```kotlin
// settings.kts
import jetbrains.buildServer.configs.kotlin.*

version = "2025.07"

project {
    buildType(Greeter)
}

object Greeter : BuildType({
    name = "say hi!"

    // to select agents with Docker
    requirements {
        exists("docker.server.version")
    }

    steps {
        step {
            id = "hello from dagger"
            // type consists of the "tc:recipe:" prefix followed by the recipe id
            type = "tc:recipe:jetbrains/dagger@1.0.0"
            // recipe inputs
            param("env.input_version", "0.19.2")
            param("env.input_command", """dagger call -m github.com/shykes/hello hello --greeting "bonjour"""")
        }
    }
})
```

The following is a more complex example demonstrating how to create a TeamCity build that checks out source code, calls a Dagger Function to test the project, and then calls another Dagger Function to build and publish a container image of the project. This example uses a simple [Go application](https://github.com/kpenfound/greetings-api) and assumes that you have already forked it in the repository connected to the TeamCity project.
