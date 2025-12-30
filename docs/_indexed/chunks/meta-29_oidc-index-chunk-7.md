---
doc_id: meta/29_oidc/index
chunk_id: meta/29_oidc/index#chunk-7
heading_path: ["OpenID Connect (OIDC)", "Read-only permission on 'secret/data/production/*' path"]
chunk_type: code
tokens: 221
summary: "Read-only permission on 'secret/data/production/*' path"
---

## Read-only permission on 'secret/data/production/*' path

path "secret/data/production/*" {
  capabilities = [ "read" ]
}
EOF
```

### Test it

Write a secret at production/foo:

```bash
vault kv put -mount=secret production/foo foo=world
```

<Tabs className="unique-tabs">
<TabItem value="basb" label="Bash" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```bash
export VAULT_ADDR='http://127.0.0.1:8200'

export VAULT_JWT=$(curl -s -X POST -H "Authorization: Bearer $WM_TOKEN" "$BASE_INTERNAL_URL/api/w/$WM_WORKSPACE/oidc/token/MY_AUDIENCE")
export VAULT_TOKEN=$(vault write -field=token auth/jwt/login role=myproject-production jwt=$VAULT_JWT)

vault kv get -mount=secret production/foo
```

</TabItem>
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill
import hvac

def main():

    token = wmill.get_id_token("MY_AUDIENCE")

    client = hvac.Client()

    response = client.auth.jwt.jwt_login(
        role="myproject-production",
        jwt=token,
    )
    print('Client token returned: %s' % response['auth']['client_token'])
    print(client.secrets.kv.read_secret_version(path='production/foo'))
```

</TabItem>
<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```typescript
import * as wmill from 'windmill-client';

export async function main() {
	const jwt = await wmill.getIdToken('MY_AUDIENCE');
	const res = await fetch('http://127.0.0.1:8200/v1/auth/jwt/login', {
		method: 'POST',
		body: JSON.stringify({ jwt, role: 'myproject-production' })
	});
	const token = (await res.json()).auth.client_token;

	const password = await fetch('http://127.0.0.1:8200/v1/secret/data/production/foo', {
		headers: { 'X-Vault-Token': token }
	});

	return password.json();
}
```

</TabItem>
</Tabs>
