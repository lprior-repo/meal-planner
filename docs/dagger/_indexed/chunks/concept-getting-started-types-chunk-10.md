---
doc_id: concept/getting-started/types
chunk_id: concept/getting-started/types#chunk-10
heading_path: ["types", "GitRepository"]
chunk_type: table
tokens: 174
summary: "The `GitRepository` type represents a Git repository."
---
The `GitRepository` type represents a Git repository.

### Common operations

| Field | Description |
|-------|-------------|
| `branch` | Returns details of a branch |
| `commit` | Returns details of a commit |
| `head` | Returns details of the current HEAD |
| `ref` | Returns details of a ref |
| `tag` | Returns details of a tag |
| `tags` | Returns tags that match a given pattern |
| `branches` | Returns branches that match a given pattern |

> **Tip:** In addition to the default Dagger types, you can create and add your own custom types to Dagger. These custom types can be used in Dagger modules and can be composed with other types to create complex workflows. Learn more about [creating custom types and developing Dagger modules](/extending).
