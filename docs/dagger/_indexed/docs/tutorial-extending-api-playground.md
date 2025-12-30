---
id: tutorial/extending/api-playground
title: "GraphQL Playground"
category: tutorial
tags: ["graphql", "api", "tutorial", "test", "ai"]
---

# GraphQL Playground

> **Context**: The API Playground was an in-browser tool for testing, running and sharing Dagger API queries. It has since been decommissioned.


The API Playground was an in-browser tool for testing, running and sharing Dagger API queries. It has since been decommissioned.

The recommended approach is to use the [`dagger query`](/getting-started/api/cli) sub-command, which provides an easy way to send raw GraphQL queries to the Dagger API from the command line.

## Running the GraphQL API locally

In order to run the GraphQL API locally and explore, you can follow these steps:

> **Note:** This will start the Dagger GraphQL server and allow CORS requests on `http://127.0.0.1:8080/query`.
>
> You can then use a GraphQL client like [Altair](https://altairgraphql.dev) to connect to the API server and explore the Dagger API/schema.

1. Install Dagger CLI and a container runtime (e.g. Docker)
2. Clone or create a Dagger module repository (you can use the [CI quickstart](/getting-started/quickstarts/ci) as a starting point)
3. Open a terminal and navigate to the root of your Dagger module repository (the directory with the `dagger.json` file)
4. Set the `DAGGER_SESSION_TOKEN` environment variable to `test` (or your desired token)
5. Run the following command: `env DAGGER_SESSION_TOKEN=test dagger listen --allow-cors`
6. Use Basic Authentication with the `DAGGER_SESSION_TOKEN` value as the username and password (e.g. `test` would be the header `Authorization: Basic dGVzdDo=`)

## See Also

- [Documentation Overview](./COMPASS.md)
