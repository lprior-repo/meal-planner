---
id: tutorial/reference/api-internals
title: "API Internals"
category: tutorial
tags: ["graphql", "api", "tutorial", "module", "container"]
---

# API Internals

> **Context**: How Dagger uses GraphQL and the internal workings of the Dagger API.


How Dagger uses GraphQL and the internal workings of the Dagger API.

## Queries as Workflows

Consider the following GraphQL query:

```graphql
query {
  container {
    from(address: "alpine:latest") {
      withExec(args: ["apk", "info"]) {
        stdout
      }
    }
  }
}
```

This query represents a Dagger workflow. In plain English, it instructs Dagger to "download the latest `alpine` container image, run the command `apk info` in that image, and print the results."

Each field in a query resolves to a build operation:

1. `from(address: "alpine:latest")` - Initialize a container from the image
2. `withExec(args: ["apk", "info"])` - Define the command for execution
3. `stdout` - Return the output of the last executed command

## State Representation

In Dagger's GraphQL API, objects expose an ID that represents the object's state at a given time. Objects like `Container` and `Directory` should be thought of as collections of state.

You can save this state and reference it elsewhere (even in a different Dagger Function), then continue updating the state from the point you left off.

## Lazy Evaluation

GraphQL query resolution is triggered only when a leaf value (scalar) is requested. Dagger uses this feature to evaluate workflows "lazily."

In practice, this means that if you create a Dagger object but never access its state, Dagger automatically skips it as part of its optimization process.

There are cases where this behavior causes unexpected results, such as when the command has external effects. Use the `sync` field to forcefully execute the step:

```graphql
query {
  container {
    from(address: "alpine:latest") {
      withExec(args: ["curl", "YOUR-WEBHOOK-URL"]) {
        sync
      }
    }
  }
}
```

## Dynamic API Extension

1. When you execute a Dagger CLI command, it connects to an existing engine or provisions one on-the-fly.

2. Each session is associated with its own GraphQL server instance. The core API provides basic functionality like running containers, interacting with files and directories.

3. When a module is loaded into the session, the GraphQL API is dynamically extended with new APIs served by that module.

4. Dagger modules are themselves also Dagger clients connected back to the same session.

## See Also

- [Documentation Overview](./COMPASS.md)
