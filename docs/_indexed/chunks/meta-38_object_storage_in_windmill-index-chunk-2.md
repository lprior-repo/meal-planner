---
doc_id: meta/38_object_storage_in_windmill/index
chunk_id: meta/38_object_storage_in_windmill/index#chunk-2
heading_path: ["Object storage in Windmill (S3)", "Workspace object storage"]
chunk_type: prose
tokens: 334
summary: "Workspace object storage"
---

## Workspace object storage

Connect your Windmill workspace to your S3 bucket, Azure Blob storage, or GCS bucket to enable users to read and write from S3 without having to have access to the credentials. When you reference S3 objects in your code, Windmill automatically tracks these data flows through the [Assets](./meta-52_assets-index.md) feature for better pipeline visibility.

![Workspace object storage infographic](../11_persistent_storage/s3_infographics.png 'Workspace object storage infographic')

Windmill S3 bucket browser will not work for buckets containing more than 20 files and uploads are limited to files < 50MB. Consider upgrading to Windmill [Enterprise Edition](/pricing) to use this feature with large buckets.

Once you've created an [S3, Azure Blob, or Google Cloud Storage resource](../../integrations/s3.mdx) in Windmill, go to the workspace settings > S3 Storage. Select the resource and click Save.

![S3 storage workspace settings](../11_persistent_storage/workspace_settings.png)

From now on, Windmill will be connected to this bucket and you'll have easy access to it from the code editor and the job run details. If a script [takes as input](#take-a-file-as-input) a `s3object`, you will see in the input form on the right a button helping you choose the file directly from the bucket.
Same for the result of the script. If you return an `s3object` containing a [key](./meta-19_rich_display_rendering-index.md#s3) `s3` pointing to a file inside your bucket, in the result panel there will be a button to open the bucket explorer to visualize the file.

S3 files in Windmill are just pointers to the S3 object using its key. As such, they are represented by a simple JSON:

```json
{
	"s3": "path/to/file"
}
```
