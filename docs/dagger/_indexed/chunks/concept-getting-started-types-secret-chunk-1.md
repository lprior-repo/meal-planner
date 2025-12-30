---
doc_id: concept/getting-started/types-secret
chunk_id: concept/getting-started/types-secret#chunk-1
heading_path: ["types-secret"]
chunk_type: prose
tokens: 101
summary: "> **Context**: Dagger allows you to utilize confidential information (\"secrets\") such as password..."
---
# Secret

> **Context**: Dagger allows you to utilize confidential information ("secrets") such as passwords, API keys, SSH keys and so on, without exposing those secrets in p...


Dagger allows you to utilize confidential information ("secrets") such as passwords, API keys, SSH keys and so on, without exposing those secrets in plaintext logs, writing them into the filesystem of containers you're building, or inserting them into the cache. The `Secret` type is used to represent these secret values.
