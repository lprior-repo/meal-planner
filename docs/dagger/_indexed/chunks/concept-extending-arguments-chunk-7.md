---
doc_id: concept/extending/arguments
chunk_id: concept/extending/arguments#chunk-7
heading_path: ["arguments", "Secret arguments"]
chunk_type: prose
tokens: 122
summary: "Dagger allows you to utilize confidential information, such as passwords, API keys, SSH keys and ..."
---
Dagger allows you to utilize confidential information, such as passwords, API keys, SSH keys and so on, in your Dagger [modules](./ops-features-reusability.md) and Dagger Functions, without exposing those secrets in plaintext logs, writing them into the filesystem of containers you're building, or inserting them into the cache.

Secrets can be passed to Dagger Functions as arguments using the `Secret` type. When invoking the Dagger Function using the Dagger CLI, secrets can be sourced from multiple providers:

- Host environment: `env://VARIABLE_NAME`
- Host filesystem: `file://./path/to/file`
- Host command execution: `cmd://"command"`
- 1Password: `op://VAULT-NAME/ITEM-NAME/FIELD-NAME`
- Vault: `vault://PATH/TO/SECRET.ITEM`
