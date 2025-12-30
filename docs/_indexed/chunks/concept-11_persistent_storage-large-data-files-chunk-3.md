---
doc_id: concept/11_persistent_storage/large-data-files
chunk_id: concept/11_persistent_storage/large-data-files#chunk-3
heading_path: ["Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage", "Windmill integration with Polars and DuckDB for data pipelines"]
chunk_type: code
tokens: 683
summary: "Windmill integration with Polars and DuckDB for data pipelines"
---

## Windmill integration with Polars and DuckDB for data pipelines

ETLs can be easily implemented in Windmill using its integration with Polars and DuckDB to facilitate working with tabular data. In this case, you don't need to manually interact with the S3 bucket, Polars/DuckDB does it natively and in a efficient way. Reading and Writing datasets to S3 can be done seamlessly.

<Tabs className="unique-tabs">
<TabItem value="duckdb-script" label="DuckDB" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```sql
-- $file1 (s3object)

-- Run queries directly on an S3 parquet file passed as an argument
SELECT * FROM read_parquet($file1)

-- Or using an explicit path in a workspace storage
SELECT * FROM read_json('s3:///demo/data.json')

-- You can also specify a secondary workspace storage
SELECT * FROM read_csv('s3://secondary_storage/demo/data.csv')

-- Write the result of a query to a different parquet file on S3
COPY (
    SELECT COUNT(*) FROM read_parquet($file1)
) TO 's3:///demo/output.pq' (FORMAT 'parquet');
```

</TabItem>
<TabItem value="polars" label="Polars" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
#requirements:
polars==0.20.2
#s3fs==2023.12.0
#wmill>=1.229.0

import wmill
from wmill import S3Object
import polars as pl
import s3fs


def main(input_file: S3Object):
    bucket = wmill.get_resource("<PATH_TO_S3_RESOURCE>")["bucket"]

    # this will default to the workspace S3 resource
    storage_options = wmill.polars_connection_settings().storage_options
    # this will use the designated resource
    # storage_options = wmill.polars_connection_settings("<PATH_TO_S3_RESOURCE>").storage_options

    # input is a parquet file, we use read_parquet in lazy mode.
    # Polars can read various file types, see
    # https://pola-rs.github.io/polars/py-polars/html/reference/io.html
    input_uri = "s3://{}/{}".format(bucket, input_file["s3"])
    input_df = pl.read_parquet(input_uri, storage_options=storage_options).lazy()

    # process the Polars dataframe. See Polars docs:
    # for dataframe: https://pola-rs.github.io/polars/py-polars/html/reference/dataframe/index.html
    # for lazy dataframe: https://pola-rs.github.io/polars/py-polars/html/reference/lazyframe/index.html
    output_df = input_df.collect()
    print(output_df)

    # To write back the result to S3, Polars needs an s3fs connection
    s3 = s3fs.S3FileSystem(**wmill.polars_connection_settings().s3fs_args)
    output_file = "output/result.parquet"
    output_uri = "s3://{}/{}".format(bucket, output_file)
    with s3.open(output_uri, mode="wb") as output_s3:
        # persist the output dataframe back to S3 and return it
        output_df.write_parquet(output_s3)

    return S3Object(s3=output_file)
```

</TabItem>
<TabItem value="duckdb" label="DuckDB (Python)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
#requirements:
wmill>=1.229.0
#duckdb==0.9.1

import wmill
from wmill import S3Object
import duckdb


def main(input_file: S3Object):
    bucket = wmill.get_resource("u/admin/windmill-cloud-demo")["bucket"]

    # create a DuckDB database in memory
    # see https://duckdb.org/docs/api/python/dbapi
    conn = duckdb.connect()

    # this will default to the workspace S3 resource
    args = wmill.duckdb_connection_settings().connection_settings_str
    # this will use the designated resource
    # args = wmill.duckdb_connection_settings("<PATH_TO_S3_RESOURCE>").connection_settings_str

    # connect duck db to the S3 bucket - this will default to the workspace S3 resource
    conn.execute(args)

    input_uri = "s3://{}/{}".format(bucket, input_file["s3"])
    output_file = "output/result.parquet"
    output_uri = "s3://{}/{}".format(bucket, output_file)

    # Run queries directly on the parquet file
    query_result = conn.sql(
        """
        SELECT * FROM read_parquet('{}')
    """.format(
            input_uri
        )
    )
    query_result.show()

    # Write the result of a query to a different parquet file on S3
    conn.execute(
        """
        COPY (
            SELECT COUNT(*) FROM read_parquet('{input_uri}')
        ) TO '{output_uri}' (FORMAT 'parquet');
    """.format(
            input_uri=input_uri, output_uri=output_uri
        )
    )

    conn.close()
    return S3Object(s3=output_file)
```

</TabItem>
</Tabs>

:::info

We recommend using the native DuckDB scripts integration, which uses the Windmill S3 proxy with no additional configuration needed.
When using Polars or DuckDB from Python, the S3 resource details need to be visible to the user, or [set to public in the workspace settings](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage).

:::

For more info on Data pipelines in Windmill, see [Data pipelines](./meta-27_data_pipelines-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Data pipelines"
		description="Windmill enables building fast, powerful, reliable, and easy-to-build data pipelines."
		href="/docs/core_concepts/data_pipelines"
	/>
</div>
