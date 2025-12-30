---
doc_id: meta/2_variables_and_secrets/index
chunk_id: meta/2_variables_and_secrets/index#chunk-5
heading_path: ["Variables and secrets", "Secrets"]
chunk_type: prose
tokens: 180
summary: "Secrets"
---

## Secrets

Secrets are encrypted when stored on Windmill. From a usage standpoint, secrets
are kept safe in three different ways:

- Secrets can only be accessed by users with the right [permissions](./meta-16_roles_and_permissions-index.md), as defined
  by their path. In addition, secrets can be explicitly shared with users or
  groups. A secret in `u/alice/secret` will only be accessible by `alice`,
  unless explicitly shared. A secret in `f/devops/secret` will be accessible by anyone with read access to `f/devops`.
- Secrets cannot be viewed outside of scripts. Note that a user could still
  `print` a secret if they have access to it from a script.
- Accessing secrets generates `variables.decrypt_secret` event that ends up in
  the <a href="https://app.windmill.dev/audit_logs" rel="nofollow">Audit logs</a>. It means that you can audit who accesses secrets. Additionally you can audit results, logs and
  script code for every script run.
