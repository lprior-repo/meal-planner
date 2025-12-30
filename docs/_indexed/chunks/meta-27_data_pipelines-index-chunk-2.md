---
doc_id: meta/27_data_pipelines/index
chunk_id: meta/27_data_pipelines/index#chunk-2
heading_path: ["Data pipelines", "Windmill integration with an external object storage"]
chunk_type: prose
tokens: 609
summary: "Windmill integration with an external object storage"
---

## Windmill integration with an external object storage

In Windmill, a data pipeline is implemented using a [flow](./tutorial-flows-1-flow-editor.md), and each step of the pipeline is a script. One of the key features of Windmill flows is to easily [pass a step result to its dependent steps](./tutorial-flows-16-architecture.md). But
because those results are serialized to Windmill database and kept as long as the job is stored, this obviously won't work when the result is a dataset of millions of rows. The solution is to save the datasets to an external storage at the end of each script.

In most cases, S3 is a well-suited storage and Windmill now provides a basic yet very useful [integration with external S3 storage](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage) at the workspace level.

The first step is to define an [S3 resource](../../integrations/s3.mdx) in Windmill and assign it to be the Workspace S3 bucket in the workspace settings.

![S3 workspace settings](../../../blog/2023-11-24-data-pipeline-orchestrator/workspace_s3_settings.png 'S3 workspace settings')

From now on, Windmill will be connected to this bucket and you'll have easy access to it from the code editor and the job run details. If a script takes as input a `s3object`, you will see in the input form on the right a button helping you choose the file directly from the bucket.
Same for the result of the script. If you return an `s3object` containing a [key](./meta-19_rich_display_rendering-index.md#s3) `s3` pointing to a file inside your bucket, in the result panel there will be a button to open the bucket explorer to visualize the file.

S3 files in Windmill are just pointers to the S3 object using its key. As such, they are represented by a simple JSON:

```json
{
	"s3": "path/to/file"
}
```

![Windmill code editor](../../../blog/2023-11-24-data-pipeline-orchestrator/s3_object_code_editor.png 'Windmill code editor')

Clicking on the button will lead directly to a bucket explorer. You can browse the bucket content and even visualize file content without leaving Windmill.

![S3 bucket explorer](../../../blog/2023-11-24-data-pipeline-orchestrator/bucket_explorer.png 'S3 bucket explorer')

Clicking on one of those buttons, a drawer will open displaying the content of the workspace bucket. You can select any file to get its metadata and if the format is common, you'll see a preview. In the above picture, for example, we're showing a Parquet file, which is very convenient to quickly validate the result of a script.

From there you always have the possibility to use the S3 client library of your choice to read and write to S3.
That being said, Polars and DuckDB can read/write directly from/to files stored in S3 Windmill now ships with helpers to make the entire data processing mechanics very cohesive.

Find all details at:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workspace object storage"
		description="Connect your Windmill workspace to your S3 bucket, Azure Blob storage, or GCS bucket to enable users to read and write from S3 without having to have access to the credentials."
		href="/docs/core_concepts/object_storage_in_windmill#workspace-object-storage"
	/>
</div>
