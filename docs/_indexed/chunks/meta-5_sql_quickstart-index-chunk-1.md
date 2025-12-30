---
doc_id: meta/5_sql_quickstart/index
chunk_id: meta/5_sql_quickstart/index#chunk-1
heading_path: ["Quickstart PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake"]
chunk_type: prose
tokens: 258
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake, Redshift, Oracle, DuckDB

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

In this quick start guide, we will write our first script in SQL. We will see how to connect a Windmill instance to an external SQL service and then send queries to the database using Windmill Scripts.

![Windmill & PostgreSQL, MySQL, BigQuery and Snowflake](./sqls.png)

This tutorial covers how to create a simple script through Windmill web IDE. See the dedicated page to [develop scripts locally](./meta-4_local_development-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Local development"
		description="Develop from various environments such as your terminal, VS Code, and JetBrains IDEs."
		href="/docs/advanced/local_development"
	/>
</div>

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	id="main-video"
	src="/videos/test_postgres.mp4"
/>

<br />

Windmill supports [PostgreSQL](https://www.postgresql.org/), [MySQL](https://www.mysql.com/), [Microsoft SQL Server](https://www.microsoft.com/sql-server), [BigQuery](https://cloud.google.com/bigquery) and [Snowflake](https://www.snowflake.com/). In any case, it requires creating a dedicated resource.

Although all users can use BigQuery, Snowflake and MS SQL through resources and [community-available languages](./meta-0_scripts_quickstart-index.md) (TypeScript, Python, Go, Bash etc.), only instances under [Enterprise edition](/pricing) and cloud workspaces can use BigQuery, Snowflake, Oralce DB and MS SQL runtimes as a dedicated language.
