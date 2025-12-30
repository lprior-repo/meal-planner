---
doc_id: meta/27_data_pipelines/index
chunk_id: meta/27_data_pipelines/index#chunk-1
heading_path: ["Data pipelines"]
chunk_type: prose
tokens: 652
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import BarChart from '@site/src/components/BarChart';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Data pipelines

> **Context**: import DocCard from '@site/src/components/DocCard'; import BarChart from '@site/src/components/BarChart'; import Tabs from '@theme/Tabs'; import TabIt

In essence, an ETL (Extract, Transform, Load) process is a [Directed Acyclic Graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph) (DAG) of jobs where each job reads data, performs computations, and outputs new or updated datasets.

Windmill streamlines the creation of data pipelines that are not only fast and reliable but also straightforward to construct:

- **Developer Experience**: Windmill's design facilitates the swift assembly of data [flows](./tutorial-flows-1-flow-editor.md), allowing for step-by-step data processing in a visually intuitive and manageable manner.
- **Control and Efficiency**: It offers the ability to manage [parallelism](./concept-flows-13-flow-branches.md#branch-all) across steps and set [concurrency limits](./ref-flows-6-concurrency-limit.md) to accommodate external resources that may be sensitive to overload or have rate limits.
- **Flexibility in Execution**: Flows in Windmill can be [restarted](./ops-flows-18-test-flows.md#restart-from-step-iteration-or-branch) from any point, enhancing the process of pipeline development and debugging by making it more flexible and efficient.
- **Simplified Monitoring**: Built-in [error and recovery handling](./meta-10_error_handling-index.md) mechanisms simplify monitoring, ensuring that managing your data pipelines is both effective and straightforward.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/I9owHiLUrKw?vq=hd1440"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

The particularity of data pipeline flows vs. any other kind of automation flows is that they run computation on large datasets and the result of such computation is itself a (potentially large) dataset that needs to be stored.

For the compute, as data practitioner for the most demanding ETLs, we have observed that in almost all cases, the system they run on is ill-designed for their task. Much faster alternatives now exist
leveraging the modern OLAP processing libraries. We have integrated with [Polars](https://www.pola.rs/) and [DuckDB](https://duckdb.org/), as ones of the best-in-class in-memory data processing
libraries and they fit particularly well Windmill since you can assign variously sized workers depending on the step.

To give you a quick idea:

- Running a `SELECT COUNT(*), SUM(column_1), AVG(column_2) FROM my_table GROUP_BY key` with _600M_ entries in `my_table` requires less than _24Gb_ of memory using DuckDB
- Running a `SELECT * FROM table_a JOIN table_b ORDER BY key`, with `table_a` having _300M_ rows and `table_b` _75M_ rows with DuckDB requires _24Gb_ of memory

Add to those numbers that on AWS for example, you can get up to [24Tb of memory on a single server](https://aws.amazon.com/ec2/instance-types/high-memory/). Nowadays, you don't need a complex distributed computing architecture to process a large amount of data.

And for storage, you can now link a Windmill workspace to an S3 bucket and use it as source and/or target of your processing steps seamlessly, without any boilerplate.

The very large majority of ETLs can be processed step-wise on single nodes and Windmill provides (one of) the [best models](../../misc/3_benchmarks/index.mdx) for orchestrating non-sharded compute. Using this model, your ETLs will see a massive performance improvement, your infrastructure
will be easier to manage and your pipeline will be easier to write, maintain, and monitor.
