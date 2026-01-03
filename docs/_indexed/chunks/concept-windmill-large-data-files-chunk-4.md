---
doc_id: concept/windmill/large-data-files
chunk_id: concept/windmill/large-data-files#chunk-4
heading_path: ["Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage", "Use Amazon S3, R2, MinIO, Azure Blob, and Google Cloud Storage directly"]
chunk_type: prose
tokens: 117
summary: "Use Amazon S3, R2, MinIO, Azure Blob, and Google Cloud Storage directly"
---

## Use Amazon S3, R2, MinIO, Azure Blob, and Google Cloud Storage directly

Amazon S3, Cloudflare R2 and MinIO all follow the same API schema and therefore have a [common Windmill resource type](https://hub.windmill.dev/resource_types/42/). Azure Blob and Google Cloud Storage have slightly different APIs than S3 but work with Windmill as well using their dedicated resource types ([Azure Blob](https://hub.windmill.dev/resource_types/137/), [Google Cloud Storage](https://hub.windmill.dev/resource_types/268))

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="S3 APIs integrations"
		description="Use Amazon S3, Cloudflare R2, MinIO, Azure Blob, and Google Cloud Storage directly within scripts and flows."
		href="/docs/integrations/s3"
	/>
</div>
