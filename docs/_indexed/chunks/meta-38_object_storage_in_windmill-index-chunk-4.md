---
doc_id: meta/38_object_storage_in_windmill/index
chunk_id: meta/38_object_storage_in_windmill/index#chunk-4
heading_path: ["Object storage in Windmill (S3)", "Rest of the code"]
chunk_type: code
tokens: 952
summary: "Rest of the code"
---

## Rest of the code
```

</TabItem>
</Tabs>

The [auto-generated UI](./meta-6_auto_generated_uis-index.md) will display a file uploader:

![S3 file uploader](./s3_file_input.png 'S3 file uploader')

or you can fill path manually if you enable 'Raw S3 object input':

![S3 Raw Object Input](./s3_raw_object_input.png 'S3 Raw Object Input')

and access bucket explorer if [resource permissions](#resources-permissions) allow it:

![S3 Bucket Explorer](./s3_bucket_explorer.png 'S3 Bucket Explorer')

That's also the recommended way to [pass](./tutorial-flows-16-architecture.md) S3 files as input to steps within [flows](./tutorial-flows-1-flow-editor.md).

![S3 file input in flow](./s3_file_input_in_flow.png 'S3 file input in flow')

![S3 file input in flow 1](./s3_file_input_in_flow_1.png 'S3 file input in flow 1')

![S3 file input in flow 2](./s3_file_input_in_flow_2.png 'S3 file input in flow 2')

### Create a file from S3 or object storage within a script

You can create a file from S3 or object storage within a script using the `writeS3File` function from the [TypeScript client](./ops-2_clients-ts-client.md) and the `wmill.write_s3_file` function from the [Python client](./ops-2_clients-python-client.md).

<Tabs className="unique-tabs">

<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'windmill-client';
import { S3Object } from 'windmill-client';

export async function main(s3_file_path: string) {
	const s3_file_output: S3Object = {
		s3: s3_file_path
	};

	const file_content = 'Hello Windmill!';
	// file_content can be either a string or ReadableStream<Uint8Array>
	await wmill.writeS3File(s3_file_output, file_content);
	return s3_file_output;
}
```

</TabItem>

<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'npm:windmill-client@1.253.7';
import { S3Object } from 'npm:windmill-client@1.253.7';

export async function main(s3_file_path: string) {
	const s3_file_output: S3Object = {
		s3: s3_file_path
	};

	const file_content = 'Hello Windmill!';
	// file_content can be either a string or ReadableStream<Uint8Array>
	await wmill.writeS3File(s3_file_output, file_content);
	return s3_file_output;
}
```

</TabItem>

<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill
from wmill import S3Object

def main(s3_file_path: str):
    s3_file_output = S3Object(s3=s3_file_path)

    file_content = b"Hello Windmill!"
	# file_content can be either bytes or a BufferedReader
    file_content = wmill.write_s3_file(s3_file_output, file_content)
    return s3_file_output
```

</TabItem>
</Tabs>

![Write to S3 file](../18_files_binary_data/s3_file_output.png)

For more info on how to use files and S3 files in Windmill, see [Handling files and binary data](./meta-18_files_binary_data-index.md).

### Secondary storage

Read and write from a storage that is not your main storage by specifying it in the S3 object as "secondary_storage" with the name of it.

From the workspace settings, in tab "S3 Storage", just click on "Add secondary storage", give it a name, and pick a resource from type "S3", "Azure Blob", "Google Cloud Storage", "AWS OIDC" or "Azure Workload Identity". You can save as many additional storages as you want as long as you give them a different name.

Then from script, you can specify the secondary storage with an object with properties `s3` (path to the file) and `storage` (name of the secondary storage).

```ts
const file = { s3: 'folder/hello.txt', storage: 'storage_1' };
```

Here is an example of the [Create](#create-a-file-from-s3-or-object-storage-within-a-script) then [Read](#read-a-file-from-s3-or-object-storage-within-a-script) a file from S3 within a script with secondary storage named "storage_1":

```ts
import * as wmill from 'windmill-client';

export async function main() {
	await wmill.writeS3File({ s3: 'data.csv', storage: 'storage_1' }, 'fooo\n1');

	const res = await wmill.loadS3File({ s3: 'data.csv', storage: 'storage_1' });

	const text = new TextDecoder().decode(res);

	console.log(text);
	return { s3: 'data.csv', storage: 'storage_1' };
}
```

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/-nJs6E_1E8Y"
	title="Secondary Storage"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

### Windmill integration with Polars and DuckDB for data pipelines

ETLs can be easily implemented in Windmill using its integration with Polars and DuckDB to facilitate working with tabular data. In this case, you don't need to manually interact with the S3 bucket, Polars/DuckDB does it natively and in a efficient way. Reading and Writing datasets to S3 can be done seamlessly.

Learn more about it in the [Data pipelines](./meta-27_data_pipelines-index.md) section.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Data pipelines"
		description="Windmill enables building fast, powerful, reliable, and easy-to-build data pipelines."
		href="/docs/core_concepts/data_pipelines"
	/>
</div>

### Dynamic S3 object access in public apps

For security reasons, dynamic S3 objects are not accessible by default in public apps when users aren't logged in.
To make them publicly accessible, you need to sign S3 objects using Windmill's built-in helpers:

- TypeScript: `wmill.signS3Object()` (single) / `wmill.signS3Objects()` (multiple)
- Python: `wmill.sign_s3_object()` (single) / `wmill.sign_s3_objects()` (multiple)

These functions take an `S3Object` as input and return an `S3Object` with an additional `presigned` property containing a signature that makes the object publicly accessible.

Signed S3 objects are supported by the [Image](../../apps/4_app_configuration_settings/image.mdx), [Rich result](../../apps/4_app_configuration_settings/rich_result.mdx) and [Rich result by job id](../../apps/4_app_configuration_settings/rich_result_by_job_id.mdx) app components.
