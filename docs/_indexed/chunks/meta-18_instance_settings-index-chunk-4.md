---
doc_id: meta/18_instance_settings/index
chunk_id: meta/18_instance_settings/index#chunk-4
heading_path: ["Instance settings", "Core"]
chunk_type: prose
tokens: 1201
summary: "Core"
---

## Core

![Core settings](./core_settings.png "Core settings")

### Base url

The base URL is the public base url of the instance.

If the base URL is not set correctly, some server-side generated URLs like resume URLs will be incorrect. Additionally, [OAuth and SSO](#authoauth) functionalities will not work properly.

### Email domain

Domain to display in webhooks for [email triggers](./meta-17_email_triggers-index.md) (should match the [MX record](https://www.cloudflare.com/learning/dns/dns-records/dns-mx-record/)).

### Request size limit in MB

Maximum size of HTTP requests in MB. Cloud only.

### Default timeout

Default timeout for individual [jobs](./meta-20_jobs-index.md#retention-policy), in seconds.

You will find a helper to convert days, hours, minutes, and seconds to seconds.

Note that you can set a [custom timeout for flow steps](./concept-flows-9-custom-timeout.md).

### Max timeout for sync endpoints

Maximum amount of time (measured in seconds) that a [sync endpoint](./meta-4_webhooks-index.md) is allowed to run before it is forcibly stopped or timed out.

You will find a helper to convert days, hours, minutes, and seconds to seconds.

### Keep job directories for debug

Toogle to keep Job directories after execution at `/tmp/windmill/<worker>/<job_id>`.

### License key

The license key is used to enable [Enterprise Edition](/pricing). You can get one by starting a free trial from the [pricing page](/pricing) or by contacting us at contact@windmill.dev

To see how to upgrade your instance to Enterprise Edition, see the [Upgrade to Enterprise Edition](../../misc/7_plans_details/index.mdx#self-host) docs.
A same key can also be used for non-prod instances. Just make sure to set the [`Non-prod instance`](#non-prod-instance) to true so that the computation usage is not counted in the billing.

From there you also have two buttons:
- `Renew key`: to renew the license key (as long as you have a valid subscription). Anyway, the key is automatically renewed everyday as long as your subscription is valid.
- `Open customer portal`: the recommended way to access the [Customer portal](../../misc/7_plans_details/index.mdx#windmill-customer-portal) where you can manage your subscription.

If your subscription is active, the key is automatically renewed everyday. A key is typically valid for 35 days.

### Non-prod instance

Whether we should consider the reported usage of this instance as non-prod.

Non-prod instances work the same as prod instances in terms of features, but their [computation usage](/pricing#worker-reporting) is not counted in the billing. Seats count, however, are across all instances. If all instances using the same key are 'Non-prod', the one using most Compute Units will be counted as Prod.

Alternatively, you can copy a development license key using the dedicated button from the [Customer portal](../../misc/7_plans_details/index.mdx#windmill-customer-portal). This provides an alternative to manually turning instances to Non-prod mode.

This setting is only available on [Enterprise Edition](/pricing).

### Retention period in secs

How long to keep the jobs data (especially the [audit logs](./meta-14_audit_logs-index.md)) in the database (max 30 days on [Community Edition](/pricing)).

You will find a helper to convert days, hours, minutes, and seconds to seconds.

This setting is only available on [Enterprise Edition](/pricing).

### Instance object storage

[Connect your instance](./meta-38_object_storage_in_windmill-index.md#instance-object-storage) to a S3 bucket to [store large logs](./meta-20_jobs-index.md#large-job-logs-management) and [global cache for Python and Go](../../misc/13_s3_cache/index.mdx).

This feature has no overlap with the [Workspace object storage](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage).

You can choose to use S3, Azure Blob Storage, AWS OIDC or Google Cloud Storage. For each you will find a button to test settings from a server or from a worker.

![S3/Azure for Python/Go cache & large logs](../../core_concepts/20_jobs/s3_azure_cache.png "S3/Azure for Python/Go cache & large logs")

#### S3

| Field | Description |
|-------|-------------|
| Bucket | The name of your S3 bucket |
| Region | If left empty, will be derived automatically from $AWS_REGION |
| Access key ID | If left empty, will be derived automatically from $AWS_ACCESS_KEY_ID, pod or ec2 profile |
| Secret key | If left empty, will be derived automatically from $AWS_SECRET_KEY, pod or ec2 profile |
| Endpoint | Only needed for non AWS S3 providers like R2 or MinIo |
| Allow http | Disable if using https only policy |

#### Azure Blob

| Field | Description |
|-------|-------------|
| Account name | The name of your Azure storage account |
| Container name | The name of your Azure blob container |
| Access key | Your Azure storage account access key |
| Tenant ID | (Optional) Your Azure tenant ID |
| Client ID | (Optional) Your Azure client ID |
| Endpoint | (Optional) Only needed for non Azure Blob providers like Azurite |

#### AWS OIDC

| Field | Description |
|-------|-------------|
| Bucket | The name of your S3 bucket |
| Region | The AWS region where your bucket is located |
| Role ARN | The ARN of the IAM role to assume (e.g., arn:aws:iam::123456789012:role/test) |

This setting is only available on [Enterprise Edition](/pricing).

#### Google Cloud Storage

| Field | Description |
|-------|-------------|
| Bucket | The name of your Google Cloud Storage bucket |
| Service Account Key | The service account key for your Google Cloud Storage bucket in JSON format |


### Private Hub base url

Base url of your [Private Hub](./meta-32_private_hub-index.md) instance, without trailing slash.

The url above will be used both when accesing the hub from the instance and from the user browser.
If end users cannot access the Private Hub with the url above, you can enable the toggle just below the field to set a different url for the Private Hub which is accessible to the users (Private Hub accessible url).

This setting is only available on [Enterprise Edition](/pricing).

### Private hub api secret

Private Hub api secret. Only required if access to your [Private Hub is restricted](./meta-32_private_hub-index.md#restricting-access-to-your-private-hub).

This setting is only available on [Enterprise Edition](/pricing).
