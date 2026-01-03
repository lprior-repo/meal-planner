---
id: tutorial/windmill/ducklake
title: "Ducklake"
category: tutorial
tags: ["windmill", "tutorial", "beginner", "ducklake"]
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Ducklake</title>
  <description>import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;;</description>
  <created_at>2026-01-02T19:55:27.586398</created_at>
  <updated_at>2026-01-02T19:55:27.586398</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Getting started" level="2"/>
    <section name="Using Ducklake in scripts" level="2"/>
    <section name="DuckDB example" level="2"/>
    <section name="Using the database manager" level="2"/>
    <section name="What Ducklake does behind the scenes" level="2"/>
  </sections>
  <features>
    <feature>duckdb_example</feature>
    <feature>getting_started</feature>
    <feature>js_allFriends</feature>
    <feature>js_friend</feature>
    <feature>js_main</feature>
    <feature>js_sql</feature>
    <feature>python_main</feature>
    <feature>using_ducklake_in_scripts</feature>
    <feature>using_the_database_manager</feature>
    <feature>what_ducklake_does_behind_the_scenes</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="service">mysql</dependency>
    <dependency type="feature">meta/windmill/index-25</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./index.mdx</entity>
    <entity relationship="uses">/docs/core_concepts/custom_instance_database</entity>
    <entity relationship="uses">./ducklake_images/ducklake_settings.png &apos;Ducklake settings&apos;</entity>
    <entity relationship="uses">./ducklake_images/ducklake_button.png &apos;S3 content&apos;</entity>
    <entity relationship="uses">./ducklake_images/ducklake_db_manager.png &apos;Explore ducklake&apos;</entity>
    <entity relationship="uses">./ducklake_images/ducklake_catalog_db.png &apos;Catalog database&apos;</entity>
    <entity relationship="uses">./ducklake_images/ducklake_s3_content.png &apos;S3 content&apos;</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,tutorial,beginner,ducklake</tags>
</doc_metadata>
-->

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Ducklake

> **Context**: import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

This page is part of our section on [Persistent storage & databases](./meta-windmill-index-25.md) which covers where to effectively store and manage the data manipulated by Windmill. Check that page for more options on data storage.

Ducklake allows you to store massive amounts of data in S3, but still query it efficiently in natural SQL language.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	id="main-video"
	src="/videos/ducklake_demo.mp4"
/>
<br />

[Learn more about Ducklake](https://ducklake.select/)

## Getting started

Prerequisites:

- A workspace storage configured
- A Postgres or MySQL resource if you are not superuser. Superusers can use a [Custom Instance Database](/docs/core_concepts/custom_instance_database).

Go to `workspace settings` -> `Object storage (S3)` and configure a Ducklake :

![Ducklake settings](./ducklake_images/ducklake_settings.png 'Ducklake settings')

## Using Ducklake in scripts

Ducklakes are referenced by their name. 'main' is the special default ducklake name, which can be omitted when referencing it.

<Tabs className="unique-tabs">
<TabItem value="typescript" label="Typescript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'windmill-client';

export async function main(user_id: string) {
	// let sql = wmill.ducklake('named_ducklake');
	let sql = wmill.ducklake();

	// This string interpolation syntax is safe
	// and is transformed into a parameterized query
	let friend = await sql`SELECT * FROM friend WHERE id = ${user_id}`.fetchOne();
	// let allFriends = await sql`INSERT INTO friend VALUES ('John', 21)`.fetch();

	return friend;
}
```

</TabItem>

<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill

def main(user_id: str):
    # dl = wmill.ducklake('named_ducklake')
    dl = wmill.ducklake()

    # DuckDB scripts use named arguments
    friend = dl.query('SELECT * FROM friend WHERE id = $id', id=user_id).fetch_one()
    # all_friends = dl.query('SELECT * FROM friend').fetch()

    return friend
```

</TabItem>

<TabItem value="duckdb" label="DuckDB" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```sql
-- $user_id (bigint)

-- ATTACH 'ducklake://named_ducklake' AS dl;
ATTACH 'ducklake' AS dl;
USE dl;

SELECT * FROM friend WHERE id = $user_id;

-- Note: the original DuckDB syntax `ATTACH 'ducklake:postgres:connection_string'` does not benefit from Windmill's integration.
```

</TabItem>
</Tabs>

You can use the Ducklake button in the editor bar for convenience, which will insert the necessary statements for you.
![S3 content](./ducklake_images/ducklake_button.png 'S3 content')

## DuckDB example

DuckDB is the native query engine for Ducklake. Other integrations (TypeScript, Python...) run DuckDB scripts under the hood.
Note that these integrations do not start a new job when running the queries. The DuckDB script is run inline within the same worker.

In the example below, we pass a list of messages with positive, neutral or negative sentiment.  
This list might come from a Python script which queries new reviews from the Google My Business API,
and sends them to an LLM to determine their sentiment.  
The messages are then inserted into a Ducklake table, which effectively creates a new parquet file and stores metadata in the catalog.

```sql
-- $messages (json[])

ATTACH 'ducklake://main' AS dl;
USE dl;

CREATE TABLE IF NOT EXISTS messages (
  content STRING NOT NULL,
  author STRING NOT NULL,
  date STRING NOT NULL,
  sentiment STRING
);

CREATE TEMP TABLE new_messages AS
  SELECT
    value->>'content' AS content,
    value->>'author' AS author,
    value->>'date' AS date,
    value->>'sentiment' AS sentiment
  FROM json_each($messages);

INSERT INTO messages
  SELECT * FROM new_messages;
```

## Using the database manager

In your Ducklake settings, clicking the "Explore" button will open the database manager. You can perform all CRUD operations through the UI or with the SQL Repl.

![Explore ducklake](./ducklake_images/ducklake_db_manager.png 'Explore ducklake')

## What Ducklake does behind the scenes

If you explore your catalog database, you will see that Ducklake created some tables for you. These metadata tables store information about your data and where it is located in S3 :

![Catalog database](./ducklake_images/ducklake_catalog_db.png 'Catalog database')

If you explore your selected workspace storage you will see your tables and their contents as columnar, parquet files :

![S3 content](./ducklake_images/ducklake_s3_content.png 'S3 content')


## See Also

- [Persistent storage & databases](./index.mdx)
- [Custom Instance Database](/docs/core_concepts/custom_instance_database)
- [Ducklake settings](./ducklake_images/ducklake_settings.png 'Ducklake settings')
- [S3 content](./ducklake_images/ducklake_button.png 'S3 content')
- [Explore ducklake](./ducklake_images/ducklake_db_manager.png 'Explore ducklake')
