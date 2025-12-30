---
doc_id: meta/20_jobs/index
chunk_id: meta/20_jobs/index#chunk-10
heading_path: ["Jobs", "Large job logs management"]
chunk_type: prose
tokens: 709
summary: "Large job logs management"
---

## Large job logs management

To optimize log storage and performance, Windmill leverages S3 for log management. This approach minimizes database load by treating the database as a temporary buffer for up to 5000 characters of logs per job.

For jobs with extensive logging needs, Windmill [Enterprise Edition](/pricing) users benefit from seamless log streaming to S3. This ensures logs, regardless of size, are stored efficiently without overwhelming local resources.

This allows the handling of large-scale logs with minimal database impact, supporting more efficient and scalable workflows.

For large logs storage (and display) and cache for distributed Python jobs, you can [connect your instance to a bucket](./meta-38_object_storage_in_windmill-index.md#instance-object-storage) from the [instance settings](./meta-18_instance_settings-index.md#instance-object-storage).

![S3/Azure for Python Cache & Large Logs](./s3_azure_cache.png "S3/Azure for Python Cache & Large Logs")

This feature has no overlap with the [Workspace object storage](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage).

You can choose to use S3, Azure Blob Storage, AWS OIDC or Google Cloud Storage. For each you will find a button to test settings from a server or from a worker.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Instance object storage"
		description="Connect instance to S3 for large-scale log management and distributed dependency caching."
		href="/docs/core_concepts/object_storage_in_windmill"
	/>
</div>

### S3

| Name         | Type       | Description                                                                   |
| ------------ | ---------- | ----------------------------------------------------------------------------- |
| Bucket       | string     | Name of your S3 bucket.                                                       |
| Region       | string     | If left empty, will be derived automatically from $AWS_REGION.   			    |
| Access key ID       | string     | If left empty, will be derived automatically from $AWS_ACCESS_KEY_ID, pod or ec2 profile.   	    |
| Secret key       | string     | If left empty, will be derived automatically from $AWS_SECRET_KEY, pod or ec2 profile.   	    |
| Endpoint       | string     | Only needed for non AWS S3 providers like R2 or MinIo.   	    |
| Allow http       | boolean     | Disable if using https only policy.   	    |

### Azure Blob

| Name           | Type       | Description                                                                   |
| -------------- | ---------- | ----------------------------------------------------------------------------- |
| Account name   | string     | The name of your Azure Storage account. It uniquely identifies your Azure Storage account within Azure and is required to authenticate with Azure Blob Storage. |
| Container name | string     | The name of the specific blob container within your storage account. Blob containers are used to organize blobs, similar to a directory structure. |
| Access key     | string     | The primary or secondary access key for the storage account. This key is used to authenticate and provide access to Azure Blob Storage. |
| Tenant ID      | string     | (optional) The unique identifier (GUID) for your Azure Active Directory (AAD) tenant. Required if using Azure Active Directory for authentication. |
| Client ID      | string     | (optional) The unique identifier (GUID) for your application registered in Azure AD. Required if using service principal authentication via Azure AD. |
| Endpoint       | string     | (optional) The specific endpoint for Azure Blob Storage, typically used when interacting with non-Azure Blob providers like Azurite or other emulators. For Azure Blob Storage, this is auto-generated and not usually needed. |

#### Google Cloud Storage

| Field | Description |
|-------|-------------|
| Bucket | The name of your Google Cloud Storage bucket |
| Service Account Key | The service account key for your Google Cloud Storage bucket in JSON format |
