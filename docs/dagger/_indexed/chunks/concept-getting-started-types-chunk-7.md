---
doc_id: concept/getting-started/types
chunk_id: concept/getting-started/types#chunk-7
heading_path: ["types", "Secret"]
chunk_type: prose
tokens: 104
summary: "Dagger allows you to utilize confidential information (\"secrets\") such as passwords, API keys, SS..."
---
Dagger allows you to utilize confidential information ("secrets") such as passwords, API keys, SSH keys and so on, without exposing those secrets in plaintext logs, writing them into the filesystem of containers you're building, or inserting them into the cache. The `Secret` type is used to represent these secret values.

### Common operations

| Field | Description |
|-------|-------------|
| `name` | Returns the name of the secret |
| `plaintext` | Returns the plaintext value of the secret |
