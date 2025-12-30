---
doc_id: ref/fatsecret/api-profile-create
chunk_id: ref/fatsecret/api-profile-create#chunk-4
heading_path: ["Profile Create", "Response"]
chunk_type: prose
tokens: 59
summary: "Response"
---

## Response

| Field | Description |
|-------|-------------|
| `auth_token` | OAuth token for the created profile |
| `auth_secret` | OAuth secret for the created profile |

> **Security Note:** Store `auth_token` and `auth_secret` securely. These credentials allow API calls on behalf of the user.
