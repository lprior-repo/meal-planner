---
doc_id: meta/29_oidc/index
chunk_id: meta/29_oidc/index#chunk-6
heading_path: ["OpenID Connect (OIDC)", "Use OIDC with Hashicorp Vault"]
chunk_type: prose
tokens: 58
summary: "Use OIDC with Hashicorp Vault"
---

## Use OIDC with Hashicorp Vault

```text
vault auth enable jwt

vault write auth/jwt/config \
  bound_issuer="<base_url>/api/oidc/" \
  oidc_discovery_url="<base_url>/api/oidc/"

vault write auth/jwt/role/myproject-production -<<EOF
{
  "role_type": "jwt",
  "bound_audiences": ["MY_AUDIENCE"],
  "bound_claims": { "email": "admin@windmill.dev"},
  "user_claim": "sub",
  "policies": ["myproject-production"],
  "ttl": "10m"
}
EOF

 vault policy write myproject-production - <<EOF
