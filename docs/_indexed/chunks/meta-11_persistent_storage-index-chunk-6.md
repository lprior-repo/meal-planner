---
doc_id: meta/11_persistent_storage/index
chunk_id: meta/11_persistent_storage/index#chunk-6
heading_path: ["Persistent storage & databases", "Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage"]
chunk_type: prose
tokens: 195
summary: "Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage"
---

## Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage

On heavier data objects & unstructured data storage, [Amazon S3](https://aws.amazon.com/s3/) (Simple Storage Service) and its alternatives [Cloudflare R2](https://www.cloudflare.com/developer-platform/r2/) and [MinIO](https://min.io/) as well as [Azure Blob Storage](https://azure.microsoft.com/en-us/products/storage/blobs) and [Google Cloud Storage](https://cloud.google.com/storage) are highly scalable and durable object storage services that provide secure, reliable, and cost-effective storage for a wide range of data types and use cases.

Windmill comes with a [native integration with S3, Azure Blob, and Google Cloud Storage](./concept-11_persistent_storage-large-data-files.md), making them the recommended storage for large objects like files and binary data.

![Workspace object storage Infographic](./s3_infographics.png 'Workspace object storage Infographic')

All details at:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage"
		description="Windmill comes with a native integration with S3, Azure Blob, and Google Cloud Storage, making them the recommended storage for large objects like files and binary data."
		href="/docs/core_concepts/persistent_storage/large_data_files"
	/>
</div>
