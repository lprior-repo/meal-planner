---
doc_id: concept/getting-started/concepts
chunk_id: concept/getting-started/concepts#chunk-3
heading_path: ["concepts", "Types"]
chunk_type: prose
tokens: 101
summary: "Like regular functions, Dagger functions can accept arguments."
---
Like regular functions, Dagger functions can accept arguments. You can see this in the previous example: the `from` function accepts a container image address (`--address`) as argument, the file function accepts a filesystem location (`--path`) as argument, and so on.

In addition to supporting basic types (string, boolean, integer, array...), the Dagger API also provides [powerful types](./concept-getting-started-types.md) for working with workflows, such as `Container`, `GitRepository`, `Directory`, `Service`, `Secret`. You can use these types as arguments to Dagger functions.
