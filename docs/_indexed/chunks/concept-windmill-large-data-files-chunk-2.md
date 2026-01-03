---
doc_id: concept/windmill/large-data-files
chunk_id: concept/windmill/large-data-files#chunk-2
heading_path: ["Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage", "Workspace object storage"]
chunk_type: prose
tokens: 159
summary: "Workspace object storage"
---

## Workspace object storage

Connect your Windmill workspace to your S3 bucket, Azure Blob storage, or Google Cloud Storage to enable users to read and write from S3 without having to have access to the credentials.

Windmill S3 bucket browser will not work for buckets containing more than 20 files and uploads are limited to files < 50MB. Consider upgrading to Windmill [Enterprise Edition](/pricing) to use this feature with large buckets.

![Workspace object storage infographic](../11_persistent_storage/s3_infographics.png 'Workspace object storage infographic')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workspace object storage"
		description="Connect your Windmill workspace to your S3 bucket, Azure Blob storage, or Google Cloud Storage to enable users to read and write from S3 without having to have access to the credentials."
		href="/docs/core_concepts/object_storage_in_windmill#workspace-object-storage"
	/>
</div>
