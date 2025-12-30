---
doc_id: tutorial/reference/api-internals
chunk_id: tutorial/reference/api-internals#chunk-2
heading_path: ["api-internals", "Queries as Workflows"]
chunk_type: code
tokens: 124
summary: "Consider the following GraphQL query:

```graphql
query {
  container {
    from(address: \"alpine..."
---
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
