---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-3
heading_path: ["Rich display rendering", "S3"]
chunk_type: code
tokens: 248
summary: "S3"
---

## S3

The `s3` key renders S3 files as a downloadable file and a bucket explorer, when Windmill is [connected to a S3 storage](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage).

```ts
return { "s3": "path/to/file" }
```

When a script outputs a S3 file, it can be downloaded or previewed directly in Windmill's UI (for displayable files like text files, CSVs, images, PDFs or parquet files).

![S3 file download](../18_files_binary_data/s3_file_output.png "S3 file download")

Even though the whole file is downloadable, the backend only sends the rows that the frontend needs for the preview. This means that you can manipulate objects of infinite size, and the backend will only return what is necessary.

You can even display several S3 files through an array of S3 objects:

```ts
export async function main() {
  return [{s3: "path/to/file_1"}, {s3: "path/to/file_2", {s3: "path/to/file_3"}}];
}
```

![S3 list of files download](./s3_array.png "S3 list of files download")

Learn more at:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workspace object storage"
		description="Connect your Windmill workspace to your S3 bucket, your Azure Blob storage or your GCS bucket to enable users to read and write from S3 without having to have access to the credentials."
		href="/docs/core_concepts/object_storage_in_windmill#workspace-object-storage"
	/>
</div>
