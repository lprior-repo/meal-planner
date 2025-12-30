---
doc_id: meta/18_files_binary_data/index
chunk_id: meta/18_files_binary_data/index#chunk-2
heading_path: ["Handling files and binary data", "Workspace object storage"]
chunk_type: prose
tokens: 475
summary: "Workspace object storage"
---

## Workspace object storage

The recommended way to store binary data is to upload it to S3, Azure Blob Storage, or Google Cloud Storage leveraging [Windmill's workspace object storage](./meta-38_object_storage_in_windmill-index.md).

Instance and workspace object storage are different from using [S3 resources](../../integrations/s3.mdx) within scripts, flows, and apps, which is free and unlimited. What is exclusive to the [Enterprise](/pricing) version is using the integration of Windmill with S3 that is a major convenience layer to enable users to read and write from S3 without having to have access to the credentials.

:::info

Windmill's integration with S3, Azure Blob Storage, and Google Cloud Storage works exactly the same and the features described below work in all cases. The only difference is that you need to select an `azure_blob` resource for Azure Blob or a `gcloud_storage` resource for Google Cloud Storage when setting up the storage in the Workspace settings.

:::

By [setting a S3 resource for the workspace](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage), you can have an easy access to your bucket from the script editor. It becomes easy to consume S3 files as input, and write back to S3 anywhere in a script.

S3 files in Windmill are just pointers to the S3 object using its key. As such, they are represented by a simple JSON:

```json
{
	"s3": "path/to/file"
}
```

When a script accepts a S3 file as input, it can be directly uploaded or chosen from the bucket explorer.

![S3 file uploader](../11_persistent_storage/file_upload.png)

![S3 bucket browsing](../11_persistent_storage/bucket_browsing.png)

When a script outputs a S3 file, it can be downloaded or previewed directly in Windmill's UI (for displayable files like text files, CSVs or parquet files).

![S3 file download](s3_file_output.png)

Windmill provides helpers in its SDKs to consume and produce S3 file seamlessly.

All details on Workspace object storage, and how to [read](./meta-38_object_storage_in_windmill-index.md#read-a-file-from-s3-or-object-storage-within-a-script) and [write](./meta-38_object_storage_in_windmill-index.md#create-a-file-from-s3-or-object-storage-within-a-script) files to S3 as well as [Windmill embedded integration with Polars and DuckDB](./meta-27_data_pipelines-index.md#windmill-integration-with-polars-and-duckdb-for-data-pipelines) for data pipelines, can be found in the [Object storage in Windmill](./meta-38_object_storage_in_windmill-index.md) page.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workspace object storage"
		description="Connect your Windmill workspace to your S3 bucket, your Azure Blob storage or your GCS bucket to enable users to read and write from S3 without having to have access to the credentials."
		href="/docs/core_concepts/object_storage_in_windmill#workspace-object-storage"
	/>
</div>
