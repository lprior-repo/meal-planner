---
doc_id: meta/27_data_pipelines/index
chunk_id: meta/27_data_pipelines/index#chunk-4
heading_path: ["Data pipelines", "then you can start using your connection to pull CSVs/Parquet/JSON/... files from S3"]
chunk_type: code
tokens: 396
summary: "then you can start using your connection to pull CSVs/Parquet/JSON/... files from S3"
---

## then you can start using your connection to pull CSVs/Parquet/JSON/... files from S3
conn.sql("SELECT * FROM read_parquet(s3://windmill_bucket/file.parquet)")
```

In Windmill, you can just do:

```
conn = duckdb.connect()
s3_resource = wmill.get_resource("/path/to/resource")
conn.execute(wmill.duckdb_connection_settings(s3_resource)["connection_settings_str"])

conn.sql("SELECT * FROM read_parquet(s3://windmill_bucket/file.parquet)")
```

And similarly for Polars:

```python
args = {
    "anon": False,
    "endpoint_url": "http://minio:9000",
    "key": "<ACCESS_KEY>",
    "secret": "<SECRET_KEY>",
    "use_ssl": False,
    "cache_regions": False,
    "client_kwargs": {
        "region_name": "us-east-1",
    },
}
s3 = s3fs.S3FileSystem(**args)
with s3.open("s3://windmill_bucket/file.parquet", mode="rb") as f:
    dataframe = pl.read_parquet(f)
```

becomes in Windmill:

```python
s3_resource = wmill.get_resource("/path/to/resource")
s3 = s3fs.S3FileSystem(**wmill.polars_connection_settings(s3_resource))
with s3.open("s3://windmill_bucket/file.parquet", mode="rb") as f:
    dataframe = pl.read_parquet(f)
```

And more to come! With both Windmill providing the boilerplate code, and Polars and DuckDB handling reading and writing from/to S3 natively, you can interact with S3 files very naturally and your Windmill scripts become concise and focused on what really matters: processing the data.

In the end, a canonical pipeline step in Windmill will look something like this:

```python
import polars as pl
import s3fs
import datetime
import wmill

s3object = dict
def main(input_dataset: s3object):
    # initialization: connect Polars to the workspace bucket
    s3_resource = wmill.get_resource("/path/to/resource")
    s3 = s3fs.S3FileSystem(wmill.duckdb_connection_settings(s3_resource))

    # reading data from s3:
    bucket = s3_resource["bucket"]
    input_dataset_uri = "s3://{}/{}".format(bucket, input_dataset["s3"])
    output_dataset_uri = "s3://{}/output.parquet".format(bucket)
    with s3.open(input_dataset_uri, mode="rb") as input_dataset, s3.open(output_dataset_uri, mode="rb") as output_dataset:
        input = pl.read_parquet(input_dataset)

        # transforming the data
        output = (
            input.filter(pl.col("L_SHIPDATE") >= datetime.datetime(1994, 1, 1))
                .filter(
                    pl.col("L_SHIPDATE")
                    < datetime.datetime(1994, 1, 1) + datetime.timedelta(days=365)
                )
                .filter((pl.col("L_DISCOUNT").is_between(0.06 - 0.01, 0.06 + 0.01)))
                .filter(pl.col("L_QUANTITY") < 24)
                .select([(pl.col("L_EXTENDEDPRICE") * pl.col("L_DISCOUNT")).alias("REVENUE")])
                .sum()
                .collect()
        )

        # writing the output back to S3
        output.write_parquet(output_dataset)

    # returning the URI of the output for next steps to process it
    return s3object({
        "s3": output_dataset_uri
    })
```

The example uses Polars. If you're more into SQL you can use DuckDB, but the code will have the same structure: initialization, reading from S3, transforming, writing back to S3.
