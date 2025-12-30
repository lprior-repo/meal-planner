---
id: tutorial/ci-integrations/teamcity
title: "TeamCity"
category: tutorial
tags: ["tutorial", "ci", "module", "function", "docker"]
---

# TeamCity

> **Context**: TeamCity provides a Dagger Recipe that can be used in any build configuration to call one or more Dagger Functions. The recipe is taken from the [JetB...


TeamCity provides a Dagger Recipe that can be used in any build configuration to call one or more Dagger Functions. The recipe is taken from the [JetBrains Marketplace](https://plugins.jetbrains.com/teamcity_recipe).

## How it works

When running a CI pipeline with Dagger using TeamCity, the general workflow looks like this:

1. A new build is triggered.
2. The build is sent to an available TeamCity agent.
3. The Dagger Recipe installs the required version of Dagger CLI on the agent.
4. The Dagger CLI attempts to find an existing Dagger Engine or spins up a new one.
5. The Dagger CLI executes the specified command and sends telemetry to Dagger Cloud if the `DAGGER_CLOUD_TOKEN` environment variable is set.
6. The build completes successfully or fails. Logs appear in TeamCity as usual.

## Prerequisites

Running the examples shown below requires:

1. A running TeamCity server.
2. At least one TeamCity agent with Docker installed.
3. A repository for storing build configurations as code.

## Example

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

```kotlin
// settings.kts
import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.vcs.GitVcsRoot

version = "2025.07"

object Conf {
    const val DAGGER_VERSION = "0.19.2"
    const val DAGGER_TEAMCITY_RECIPE = "tc:recipe:jetbrains/dagger@1.0.0"
    const val DAGGER_MODULE = "github.com/kpenfound/dagger-modules/golang@v0.2.0"

    val address
        get() = "ttl.sh/my-app-%env.BUILD_NUMBER%"
}

project {
    vcsRoot(TestVscRoot)
    buildType(Build)
}

object Build : BuildType({
    name = "Build"

    requirements {
        exists("docker.server.version")
    }

    vcs {
        root(TestVscRoot)
    }

    steps {
        step {
            id = "run tests"
            type = Conf.DAGGER_TEAMCITY_RECIPE
            param("env.input_version", Conf.DAGGER_VERSION)
            param("env.input_command", """dagger -m ${Conf.DAGGER_MODULE} call test --source=.""")
        }
        step {
            id = "build and publish"
            type = Conf.DAGGER_TEAMCITY_RECIPE
            param("env.input_version", Conf.DAGGER_VERSION)
            param(
                "env.input_command",
                """dagger -m ${Conf.DAGGER_MODULE} call build-container --source=. --args=. publish --address=${Conf.address}"""
            )
        }
    }
})

object TestVscRoot : GitVcsRoot({
    name = "greetings-api"
    url = "https://github.com/kpenfound/greetings-api.git"
    branchSpec = "+:refs/heads/*"
    branch = "refs/heads/main"
})
```

## Resources

- [Working with Recipes](https://www.jetbrains.com/help/teamcity/working-with-meta-runner.html): This guide provides useful information about TeamCity recipes.

## About TeamCity

[TeamCity](https://www.jetbrains.com/teamcity/) is a popular CI/CD tool developed by JetBrains.

## See Also

- [Documentation Overview](./COMPASS.md)
