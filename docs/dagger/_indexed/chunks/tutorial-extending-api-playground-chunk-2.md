---
doc_id: tutorial/extending/api-playground
chunk_id: tutorial/extending/api-playground#chunk-2
heading_path: ["api-playground", "Running the GraphQL API locally"]
chunk_type: prose
tokens: 187
summary: "In order to run the GraphQL API locally and explore, you can follow these steps:

> **Note:** Thi..."
---
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
