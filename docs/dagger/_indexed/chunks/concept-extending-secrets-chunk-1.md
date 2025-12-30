---
doc_id: concept/extending/secrets
chunk_id: concept/extending/secrets#chunk-1
heading_path: ["secrets"]
chunk_type: code
tokens: 255
summary: "> **Context**: Dagger has first-class support for \"secrets\", such as passwords, API keys, SSH key..."
---
# Secrets

> **Context**: Dagger has first-class support for "secrets", such as passwords, API keys, SSH keys and so on. These secrets can be securely used in Dagger functions...


Dagger has first-class support for "secrets", such as passwords, API keys, SSH keys and so on. These secrets can be securely used in Dagger functions without exposing them in plaintext logs, writing them into the filesystem of containers you're building, or inserting them into the cache.

Here is an example, which uses a secret in a Dagger function chain:

```bash
export API_TOKEN="guessme"
```

**System shell:**
```bash
dagger <<'EOF'
container |
  from alpine:latest |
  with-secret-variable MY_SECRET env://API_TOKEN |
  with-exec -- sh -c 'echo this is the secret: $MY_SECRET' |
  stdout
EOF
```

**Dagger Shell:**
```
container |
  from alpine:latest |
  with-secret-variable MY_SECRET env://API_TOKEN |
  with-exec -- sh -c 'echo this is the secret: $MY_SECRET' |
  stdout
```

**Dagger CLI:**
```bash
dagger core container \
  from --address=alpine:latest \
  with-secret-variable --name="MY_SECRET" --secret="env://API_TOKEN" \
  with-exec --args="sh","-c",'echo this is the secret: $MY_SECRET' \
  stdout
```

[Secret arguments](./concept-extending-arguments.md#secret-arguments) can be sourced from multiple providers: the host environment, the host filesystem, the result of host command execution, and external secret managers [1Password](https://1password.com/) and [Vault](https://www.hashicorp.com/products/vault).
