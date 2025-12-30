---
doc_id: meta/29_oidc/index
chunk_id: meta/29_oidc/index#chunk-5
heading_path: ["OpenID Connect (OIDC)", "Use OIDC with AWS"]
chunk_type: code
tokens: 494
summary: "Use OIDC with AWS"
---

## Use OIDC with AWS

### Create an identity provider with AWS for OIDC

1. Search for the `Identity Providers` tab in the console search or IAM.
2. Add provider
3. Select OpenID Connect
4. Provider Url: `<base_url>/api/oidc/`, audience: `sts.amazonaws.com`

### Create a role

1. IAM -> Roles -> Create Role
2. Web Identity
3. Pick provider created above, audience: `sts.amazonaws.com`
4. Pick the permission policy to attach to this role. You can create as many roles as needed so it's best to be specific.
5. fill the Trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Principal": {
              "Federated": "arn:aws:iam::976079455550:oidc-provider/<base_url>/api/oidc/"
          },
          "Condition": {
              "StringEquals": {
                  "<base_url>/api/oidc/:aud": "sts.amazonaws.com",
                  "<base_url>/api/oidc/:email": "example@example.com",
                  ...
              }
          }
      }
  ]
}
```

Note that [AWS only supports conditions on the `aud`, `sub`, and `email` claims](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html#condition-keys-wif). You can use `StringLike` on the `sub` claim to limit by job, flow, or workspace:

```text
"StringLike": {
  "<base_url>/api/oidc/:sub": "*::<workspace>",
  "<base_url>/api/oidc/:sub": "*::<script_path>::*::*",
  "<base_url>/api/oidc/:sub": "*::*::<flow_path>::*"
}
```

For instance level AWS OIDC for [instance object storage](./meta-18_instance_settings-index.md#instance-object-storage), the sub claim is "instance". For [workspace level object storage](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage), and SQS oidc triggersthe sub claim is "&lt;workspace_id&gt;".

### Get AWS credentials

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

You can now get the ephemeral access key, secret key, and session token from it to use with any AWS API.

```bash
credentials = credentials["Credentials"]

aws_access_key_id=credentials["AccessKeyId"]
aws_secret_access_key=credentials["SecretAccessKey"]
aws_session_token=credentials["SessionToken"]
```
