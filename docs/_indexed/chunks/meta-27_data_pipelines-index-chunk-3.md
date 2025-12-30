---
doc_id: meta/27_data_pipelines/index
chunk_id: meta/27_data_pipelines/index#chunk-3
heading_path: ["Data pipelines", "Windmill integration with Polars and DuckDB for data pipelines"]
chunk_type: code
tokens: 1417
summary: "Windmill integration with Polars and DuckDB for data pipelines"
---

## Windmill integration with Polars and DuckDB for data pipelines

ETLs can be easily implemented in Windmill using its integration with Polars and DuckDB to facilitate working with tabular data. In this case, you don't need to manually interact with the S3 bucket, Polars/DuckDB does it natively and in a efficient way. Reading and Writing datasets to S3 can be done seamlessly.

<Tabs className="unique-tabs">
<TabItem value="polars (AWS S3)" label="Polars (AWS S3)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
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

    # To write back the result to S3
    output_file = "output/result.parquet"
    output_uri = "s3://{}/{}".format(bucket, output_file)
    output_df.write_parquet(output_uri, storage_options=storage_options)

    return S3Object(s3=output_file)
```

</TabItem>
<TabItem value="polars (Azure Blob Storage)" label="Polars (Azure Blob Storage)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill
from wmill import S3Object
import polars as pl


def main(input_file: S3Object):
    # this will default to the workspace Azure Blob Storage resource
    endpoint_url = wmill.polars_connection_settings().s3fs_args["endpoint_url"]
    storage_options = wmill.polars_connection_settings().storage_options

    # this will use the designated resource
    # storage_options = wmill.polars_connection_settings("<PATH_TO_S3_RESOURCE>").storage_options

    # input is a parquet file, we use read_parquet in lazy mode.
    # Polars can read various file types, see
    # https://pola-rs.github.io/polars/py-polars/html/reference/io.html
    input_uri = "{}/{}".format(endpoint_url, input_file["s3"])

    input_df = pl.read_parquet(input_uri, storage_options=storage_options).lazy()

    # process the Polars dataframe. See Polars docs:
    # for dataframe: https://pola-rs.github.io/polars/py-polars/html/reference/dataframe/index.html
    # for lazy dataframe: https://pola-rs.github.io/polars/py-polars/html/reference/lazyframe/index.html
    output_df = input_df.collect()
    print(output_df)

    # To write back the result to Azure Blob Storage, Polars needs an s3fs connection
    output_file = "output/result.parquet"
    output_uri = "{}/{}".format(endpoint_url, output_file)
    output_df.write_parquet(output_uri, storage_options=storage_options)

    return S3Object(s3=output_file)
```

</TabItem>
<TabItem value="polars (Google Cloud Storage)" label="Polars (Google Cloud Storage)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill
from wmill import S3Object
import polars as pl


def main(input_file: S3Object):
    # this will default to the workspace Google Cloud Storage resource
    endpoint_url = wmill.polars_connection_settings().s3fs_args["endpoint_url"]
    storage_options = wmill.polars_connection_settings().storage_options

    # this will use the designated resource
    # storage_options = wmill.polars_connection_settings("<PATH_TO_S3_RESOURCE>").storage_options

    # input is a parquet file, we use read_parquet in lazy mode.
    # Polars can read various file types, see
    # https://pola-rs.github.io/polars/py-polars/html/reference/io.html
    input_uri = "{}/{}".format(endpoint_url, input_file["s3"])

    input_df = pl.read_parquet(input_uri, storage_options=storage_options).lazy()

    # process the Polars dataframe. See Polars docs:
    # for dataframe: https://pola-rs.github.io/polars/py-polars/html/reference/dataframe/index.html
    # for lazy dataframe: https://pola-rs.github.io/polars/py-polars/html/reference/lazyframe/index.html
    output_df = input_df.collect()
    print(output_df)

    # To write back the result to Google Cloud Storage, Polars needs an s3fs connection
    output_file = "output/result.parquet"
    output_uri = "{}/{}".format(endpoint_url, output_file)
    output_df.write_parquet(output_uri, storage_options=storage_options)

    return S3Object(s3=output_file)
```

</TabItem>
<TabItem value="duckdb (Python / AWS S3)" label="DuckDB (Python / AWS S3)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
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
<TabItem value="duckdb (Python / Azure Blob Storage)" label="DuckDB (Python / Azure Blob Storage)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill
from wmill import S3Object
import duckdb


def main(input_file: S3Object):
    # this will default to the workspace S3 resource
    connection_str = wmill.duckdb_connection_settings().connection_settings_str
    root_path = wmill.duckdb_connection_settings().azure_container_path
    print(root_path)

    # this will use the designated resource
    # args = wmill.duckdb_connection_settings("<PATH_TO_S3_RESOURCE>").connection_settings_str

    # create a DuckDB database in memory
    # see https://duckdb.org/docs/api/python/dbapi
    conn = duckdb.connect()

    # connect duck db to the S3 bucket - this will default to the workspace S3 resource
    conn.execute(connection_str)

    input_uri = "{}/{}".format(root_path, input_file["s3"])
    output_file = "output/result.parquet"
    output_uri = "{}/{}".format(root_path, output_file)

    # Run queries directly on the parquet file
    query_result = conn.sql(
        """
        SELECT * FROM read_parquet('{}')
    """.format(input_uri)
    )
    query_result.show()

    # NOTE: DuckDB doesn't support writing to Azure Blob Storage as of Jan 30 2025
    # Write the result of a query to a different parquet file on Azure Blob Storage
    # using Polars
    storage_options = wmill.polars_connection_settings().storage_options
    query_result.pl().write_parquet(output_uri, storage_options=storage_options)
    conn.close()
    return S3Object(s3=output_file)
```

</TabItem>
<TabItem value="duckdb" label="DuckDb (AWS S3)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>
```sql
-- $file1 (s3object)

-- Run queries directly on an S3 parquet file passed as an argument
SELECT \* FROM read_parquet($file1);

-- Or using an explicit path in a workspace storage
SELECT \* FROM read_json('s3:///demo/data.json');

-- You can also specify a secondary workspace storage
SELECT \* FROM read_csv('s3://secondary_storage/demo/data.csv');

-- Write the result of a query to a different parquet file on S3
COPY (
SELECT COUNT(\*) FROM read_parquet($file1)
) TO 's3:///demo/output.pq' (FORMAT 'parquet');

````

</TabItem>
</Tabs>

:::info

Polars and DuckDB need to be configured to access S3 within the Windmill script. The job will need to accessed the S3 resources, which either needs to be accessible to the user running the job, or the S3 resource needs to be [set as public in the workspace settings](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage).

:::

### Canonical data pipeline in Windmill w/ Polars and DuckDB

With S3 as the external store, a transformation script in a flow will typically perform:

1. Pulling data from S3.
2. Running some computation on the data.
3. Storing the result back to S3 for the next scripts to be run.

When running a DuckDB script, Windmill automatically handles connection to your workspace storage :

```sql
-- This queries the windmill api under the hood to figure out the
-- correct connection string
SELECT * FROM read_parquet('s3:///path/to/file.parquet');
SELECT * FROM read_csv('s3://secondary_storage/path/to/file.csv');
````

If you want to use a scripting language, Windmill SDKs now expose helpers to simplify code and help you connect Polars or DuckDB to the Windmill workspace S3 bucket. In your usual IDE, you would need to write for _each script_:

```python
conn = duckdb.connect()
conn.execute(
    """
    SET home_directory='./';
    INSTALL 'httpfs';
    LOAD 'httpfs';
    SET s3_url_style='path';
    SET s3_region='us-east-1';
    SET s3_endpoint='http://minio:9000'; # using MinIo in Docker works perfectly fine if you don't have access to an AWS S3 bucket!
    SET s3_use_ssl=0;
    SET s3_access_key_id='<ACCESS_KEY>';
    SET s3_secret_access_key='<SECRET_KEY>';
"""
)
