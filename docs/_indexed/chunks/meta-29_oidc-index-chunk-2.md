---
doc_id: meta/29_oidc/index
chunk_id: meta/29_oidc/index#chunk-2
heading_path: ["OpenID Connect (OIDC)", "Generating OIDC/JWT tokens"]
chunk_type: code
tokens: 466
summary: "Generating OIDC/JWT tokens"
---

## Generating OIDC/JWT tokens

OIDC tokens are generated at runtime and are scoped to the script that generated them. Tokens can be generated with Windmill's SDKs or from the REST API directly.
Your token must be associated with an audience which identifies the intended recipient of the token. The audience is provided as a parameter when generating the token. If the audience is incorrect, the consumer will reject the token. (For AWS, this audience is sts.amazonaws.com. For your own APIs, you can specify an audience such as auth.yourcompany.com.)
If you are using a TypeScript or Python scripts, you can use the Windmill SDK to generate tokens. For other like REST or shell, you should use the REST api directly:

```bash
curl -s -X POST -H "Authorization: Bearer $WM_TOKEN" "$BASE_INTERNAL_URL/api/w/$WM_WORKSPACE/oidc/token/MY_AUDIENCE"
```

The default expiry time is 48 hours. You can specify a custom expiry time in seconds when generating the token using the `expires_in` query parameter.
You can also set the default expiry time for the token using the `OIDC_TOKEN_EXPIRY_SECS` environment variable.

### Generate the token

Tokens can be generated at runtime with Windmill's SDKs. For example, to generate an OIDC token with audience sts.amazonaws.com to assume an AWS role:

<Tabs className="unique-tabs">
<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```typescript
import { STSClient } from 'npm:@aws-sdk/client-sts';
import { AssumeRoleWithWebIdentityCommand } from 'npm:@aws-sdk/client-sts';
import * as wmill from 'npm:windmill-client';

export async function main() {
	const token = await wmill.getIdToken('sts.amazonaws.com');

	const command = new AssumeRoleWithWebIdentityCommand({
		RoleArn: 'arn:aws:iam::000000000000:role/my_aws_role',
		WebIdentityToken: token,
		RoleSessionName: 'my_session'
	});

	const client = new STSClient({ region: 'us-east-1' });
	console.log(await client.send(command));
}
```

</TabItem>
<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```typescript
import { STSClient } from '@aws-sdk/client-sts';
import { AssumeRoleWithWebIdentityCommand } from '@aws-sdk/client-sts';
import * as wmill from 'windmill-client';

export async function main() {
	const token = await wmill.getIdToken('sts.amazonaws.com');

	const command = new AssumeRoleWithWebIdentityCommand({
		RoleArn: 'arn:aws:iam::000000000000:role/my_aws_role',
		WebIdentityToken: token,
		RoleSessionName: 'my_session'
	});

	const client = new STSClient({ region: 'us-east-1' });
	console.log(await client.send(command));
}
```

</TabItem>
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill
import boto3

def main():

    sts = boto3.client("sts")
    token = wmill.get_id_token("sts.amazonaws.com")

    credentials = sts.assume_role_with_web_identity(
        RoleArn="arn:aws:iam::000000000000:role/my_aws_role",
        WebIdentityToken=token,
        RoleSessionName="my_session",
    )

    print(credentials)
```

</TabItem>
</Tabs>
