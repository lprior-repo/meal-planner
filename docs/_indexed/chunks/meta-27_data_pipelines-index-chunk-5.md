---
doc_id: meta/27_data_pipelines/index
chunk_id: meta/27_data_pipelines/index#chunk-5
heading_path: ["Data pipelines", "In-memory data processing performance"]
chunk_type: prose
tokens: 934
summary: "In-memory data processing performance"
---

## In-memory data processing performance

By using Polars, DuckDB, or any other data processing libraries inside Windmill, the computation will happen on a single node. Even though you might have multiple Windmill workers, a script will still be run by a single worker and the computation won't be distributed. We've run some benchmarks to expose the performance and scale you could expect for such a setup.

We've taken a well-known benchmark dataset: the [TCP-H](https://www.tpc.org/tpch/default5.asp) dataset. It has the advantage of being available in any size and being fairly representative of real use cases. We've generated multiple versions: 1Gb, 5Gb, 10Gb and 25Gb (if you prefer thinking in terms of rows, the biggest table of the 25Gb version has around 150M rows). We won't detail here the structure of the database or the queries we've run, but TPC-H is well-documented if needed.

The following procedure was followed:

- Datasets provided by TPC-H as CSVs were uploaded as parquet files on S3.
- TPC-H provides a set of canonical queries. They perform numerous joins, aggregations, group-bys, etc. 8 of them were converted in the different dialects.
- Those queries were run sequentially as scripts in for-loop flow in Windmill, and this for each of the benchmark sets of data (1Gb, 5Gb, 10Gb, etc.). The memory of the Windmill server was recorded.
- Each script was:
  - Reading the data straight from the S3 parquet files
  - Running the query
  - Storing the result in a separate parquet file on S3

A couple of notes before the results:

- We've run those benchmarks on a `m4.xlarge` AWS server (8 vCPUs, 32Gb of memory). It's not a small server, but also not terribly large. Keep in mind you can get up to 24Tb of Memory on a single server on AWS (yes, it's not cheap, but it's possible!)
- Polars comes with a lazy mode, in which it is supposed to be more memory efficient. We've benchmarked both normal and lazy mode.
- We also ran those benchmarks on Spark, as a well-known and broadly used reference. To be as fair as possible, the Spark "cluster" was composed of a single node running also on an `m4.xlarge` AWS instance.

<BarChart
	title="Duration of the 8 queries ran sequentially (in seconds)"
	yTitle="duration (in seconds)"
	labels={['Bench 1G', 'Bench 5G', 'Bench 10G', 'Bench 25G']}
	rawData={[
		{
			label: 'Spark',
			data: [285, 720, 1170, 2505]
		},
		{
			label: 'Windmill + Polars',
			data: [42, 183, 370, 0]
		},
		{
			label: 'Windmill + Polars lazy',
			data: [247, 1246, 2480, 6498]
		},
		{
			label: 'Windmill + DuckDB in memory',
			data: [61, 260, 560, 2767]
		}
	]}
/>

<BarChart
	title="Memory peak for the run of the 8 queries ran sequentially (in GB)"
	yTitle="Memory peak (in GB)"
	labels={['Bench 1G', 'Bench 5G', 'Bench 10G', 'Bench 25G']}
	rawData={[
		{
			label: 'Spark',
			data: [7.26, 10.3, 11.7, 20.9]
		},
		{
			label: 'Windmill + Polars',
			data: [1.78, 12.2, 24.2, 0]
		},
		{
			label: 'Windmill + Polars lazy',
			data: [2.11, 2.42, 10.4, 19.6]
		},
		{
			label: 'Windmill + DuckDB in memory',
			data: [2.94, 6.05, 12.3, 25.7]
		}
	]}
/>

<br />

Polars is the fastest at computing the results, but consumes slightly more memory than Spark (it OOMed for the 25G benchmark). Polars in lazy mode, however, is a lot more memory efficient and can process more data, at the expense of computation time.
Overall, both Polars and DuckDB behave very well in terms of memory consumption and computation time. The 10G benchmark contains tables with up to 60 million rows, and we were far from using the most powerful AWS instance. So, it is true that
this doesn't scale horizontally, but it also confirms that a majority of data pipelines can be addressed with a large enough instance. And when you think about it, what's more convenient? Managing a single beefy server or a fleet of small servers?

:::info

DuckDB offers the possibility to back its database with a file on disk to save some memory. This mode fits perfectly with Windmill flows using a shared directory between steps. We implemented a simple flow where the first step loads the DB in
a file, and the following steps consume this file to run the queries. We were able to run the 8 queries on the 100Gb benchmark successfully. It took 40 minutes and consumed 29,1Gb at the peak.

:::
