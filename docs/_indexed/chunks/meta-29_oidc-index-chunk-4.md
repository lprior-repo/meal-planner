---
doc_id: meta/29_oidc/index
chunk_id: meta/29_oidc/index#chunk-4
heading_path: ["OpenID Connect (OIDC)", "Settings discovery"]
chunk_type: code
tokens: 31
summary: "Settings discovery"
---

## Settings discovery

Windmill's OIDC settings are available at the following discovery URL:

```
<base_url>/api/oidc/.well-known/openid-configuration
```

Jwks are available directly at:

```
<base_url>/api/oidc/jwks
```
