---
doc_id: meta/38_object_storage_in_windmill/index
chunk_id: meta/38_object_storage_in_windmill/index#chunk-3
heading_path: ["Object storage in Windmill (S3)", "Resources permissions"]
chunk_type: code
tokens: 1361
summary: "Resources permissions"
---

## Resources permissions

:::info

Advanced S3 permissions are only available on [Enterprise Edition](/pricing). Without advanced permissions, all users have R/W to all files on an S3 workspace storage, but they cannot list them

:::

When you configure a workspace storage, you can enable advanced permissions to finely control which users can access which files in the bucket.
The default rules enforce that users can only access files in S3 in paths that they would have access to in Windmill.

For example, user `alice` can access files in the path `u/alice/**/*` and files shared with her in `g/group1/**/*` if she is part of `group1`. If she has read-only access to `folder1`, and she tries to access the s3 object at path, `f/folder1/file.csv`, she will only be able to read the file, not write or delete it.

These rules are enforced when accessing data with the Windmill client (e.g in Typescript or Python), or from the Windmill S3 Proxy (used by DuckDB scripts).

![Advanced S3 permissions](./advanced_permissions.jpg 'Advanced S3 permissions')

You can customise these rules however you'd like. The rules are read in order, and the first one to match decides of the access. If no rules match, the access is denied. We support the unix glob syntax (`**`, `*`, `?`, `{a,b}` ...)

You can use interpolated variables like `{username}`, which will be replaced by the current user's username. A rule might get transformed to multiple ones, for example, for a user in group1 and group2, the rule `g/{group}/**/*` will expand to `['g/group1/**/*', 'g/group2/**/*']`.

Admins can always access everything.

All interactions with the S3 bucket are proxied through Windmill's backend. We guarantee that users who don't have access to the resource won't be able to retrieve any of its details (access key and secret key), unless the lecacy public mode is enabled (see below).

:::note Legacy

The resource can be set to be public by disabling advanced permissions which will show the "S3 resource details can be accessed by all users of this workspace" toggle.

In this case, permissions will be ignored when users interact with the S3 bucket via Windmill. Note that when the resource is public, the users might be able to access all of its details (including access keys and secrets) via some Windmill endpoints.

:::

### S3 input and output UI

When a script accepts a S3 file as input, it can be directly uploaded or chosen from the bucket explorer.

![S3 file uploader](../11_persistent_storage/file_upload.png)

![S3 bucket browsing](../11_persistent_storage/bucket_browsing.png)

When a script outputs a S3 file, it can be downloaded or previewed directly in Windmill's UI (for displayable files like text files, CSVs, images, PDFs, and parquet files).

![S3 file download](../18_files_binary_data/s3_file_output.png)

Even though the whole file is downloadable, the backend only sends the rows that the frontend needs for the preview. This means that you can manipulate objects of infinite size, and the backend will only return what is necessary.

You can even display several S3 files through an array of S3 objects:

```ts
export async function main() {
  return [{s3: "path/to/file_1"}, {s3: "path/to/file_2", {s3: "path/to/file_3"}}];
}
```

![S3 list of files download](../19_rich_display_rendering/s3_array.png 'S3 list of files download')

:::warning

Rendering JSON files straight from S3 is not supported. Instead you can load the file and parse it as a JSON object and return it as a [rich result](./meta-19_rich_display_rendering-index.md).

:::

### Read a file from S3 or object storage within a script

`S3Object` is a type that represents a file in S3 or object storage.

S3 files in Windmill are just pointers to the S3 object using its key. As such, they are represented by a simple JSON:

```json
{
	"s3": "path/to/file"
}
```

You can read a file from S3 or object storage within a script using the `loadS3File` and `loadS3FileStream` functions from the [TypeScript client](./ops-2_clients-ts-client.md) and the `wmill.load_s3_file` and `wmill.load_s3_file_stream` functions from the [Python client](./ops-2_clients-python-client.md). When writing or manipulating file content, consider using `Blob` objects to efficiently handle binary data and ensure compatibility across different file types.

- **`loadS3File`**: This function loads the entire file content into memory as a single unit, which is useful for smaller files where you need immediate access to all data.
- **`loadS3FileStream`**: This function provides a stream of the file content, allowing you to process large files incrementally without loading the entire file into memory, which is ideal for handling large datasets or files.

<Tabs className="unique-tabs">

<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'windmill-client';
import { S3Object } from 'windmill-client';

export async function main() {
	const example_file: S3Object = {
		s3: 'path/to/file'
	};

	// Load the entire file_content as a Uint8Array
	const file_content = await wmill.loadS3File(example_file);

	const decoder = new TextDecoder();
	const file_content_str = decoder.decode(file_content);
	console.log(file_content_str);

	// Or load the file lazily as a Blob
	let fileContentBlob = await wmill.loadS3FileStream(example_file);
	console.log(await fileContentBlob.text());
}
```

</TabItem>

<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'npm:windmill-client@1.253.7';
import { S3Object } from 'npm:windmill-client@1.253.7';

export async function main() {
	const example_file: S3Object = {
		s3: 'path/to/file'
	};

	// Load the entire file_content as a Uint8Array
	const file_content = await wmill.loadS3File(example_file);

	const decoder = new TextDecoder();
	const file_content_str = decoder.decode(file_content);
	console.log(file_content_str);

	// Or load the file lazily as a Blob
	let fileContentBlob = await wmill.loadS3FileStream(example_file);
	console.log(await fileContentBlob.text());
}
```

</TabItem>

<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill
from wmill import S3Object

def main():

	example_file = S3Object(s3='path/to/file')

	# Load the entire file_content as a bytes array
    file_content = wmill.load_s3_file(example_file)
    print(file_content.decode('utf-8'))

    # Or load the file lazily as a Buffered reader:
    with wmill.load_s3_file_reader(example_file) as file_reader:
        print(file_reader.read())
```

</TabItem>
</Tabs>

![Read S3 file](../18_files_binary_data/s3_file_input.png)

Certain file types, typically parquet files, can be [directly rendered by Windmill](./meta-19_rich_display_rendering-index.md).

### Take a file as input

Scripts can accept a S3Object as input.

<Tabs className="unique-tabs">

<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'windmill-client';
import { S3Object } from 'windmill-client';

export async function main(input_file: S3Object) {
	// rest of the code
}
```

</TabItem>

<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'npm:windmill-client@1.253.7';
import { S3Object } from 'npm:windmill-client@1.253.7';

export async function main(input_file: S3Object) {
	// rest of the code
}
```

</TabItem>

<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill
from wmill import S3Object

def main(input_file: S3Object):
