---
id: tutorial/windmill/data-tables
title: "Data tables"
category: tutorial
tags: ["windmill", "tutorial", "beginner", "data"]
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Data tables</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;; import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;;</description>
  <created_at>2026-01-02T19:55:27.583456</created_at>
  <updated_at>2026-01-02T19:55:27.583456</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Getting started" level="2"/>
    <section name="Usage" level="2"/>
    <section name="Assets integration" level="3"/>
    <section name="Workspace-scoped" level="3"/>
    <section name="Special data table: `main`" level="3"/>
    <section name="Database types" level="2"/>
    <section name="1. Custom instance database" level="3"/>
    <section name="2. Postgres resource" level="3"/>
    <section name="Permissions" level="2"/>
  </sections>
  <features>
    <feature>1_custom_instance_database</feature>
    <feature>2_postgres_resource</feature>
    <feature>assets_integration</feature>
    <feature>database_types</feature>
    <feature>getting_started</feature>
    <feature>js_allFriends</feature>
    <feature>js_friend</feature>
    <feature>js_main</feature>
    <feature>js_sql</feature>
    <feature>permissions</feature>
    <feature>python_main</feature>
    <feature>special_data_table_main</feature>
    <feature>usage</feature>
    <feature>workspace-scoped</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="feature">meta/windmill/index-25</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./index.mdx</entity>
    <entity relationship="uses">./datatable_images/datatable_settings_1.png &apos;Data Table settings&apos;</entity>
    <entity relationship="uses">/docs/core_concepts/custom_instance_database</entity>
    <entity relationship="uses">./datatable_images/datatable_schemas.png &apos;Data Table schemas&apos;</entity>
    <entity relationship="uses">./datatable_images/datatable_asset.png &apos;Data Table asset&apos;</entity>
    <entity relationship="uses">./datatable_images/datatable_asset_flow.png &apos;Data Table asset flow&apos;</entity>
    <entity relationship="uses">/docs/core_concepts/custom_instance_database</entity>
  </related_entities>
  <examples count="5">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,tutorial,beginner,data</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Data tables

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

This page is part of our section on [Persistent storage & databases](./meta-windmill-index-25.md) which covers where to effectively store and manage the data manipulated by Windmill. Check that page for more options on data storage.

Windmill **Data Tables** let you store and query relational data with **near-zero setup** using databases managed automatically by Windmill. They provide a simple, safe, workspace-scoped way to leverage SQL inside your workflows without exposing credentials.

---

## Getting started

Go to `workspace settings` -> `Data Tables` and configure a Data Table :

![Data Table settings](./datatable_images/datatable_settings_1.png 'Data Table settings')

Superadmins can use a [Custom Instance Database](/docs/core_concepts/custom_instance_database) and get started with no setup.

## Usage

<Tabs className="unique-tabs">
<TabItem value="typescript" label="Typescript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'windmill-client';

export async function main(user_id: string) {
	// let sql = wmill.datatable('named_datatable');
	let sql = wmill.datatable();

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
    # db = wmill.datatable('named_datatable')
    db = wmill.datatable()

    # Postgres scripts use positional arguments
    friend = db.query('SELECT * FROM friend WHERE id = $1', user_id).fetch_one()
    # all_friends = db.query('SELECT * FROM friend').fetch()

    return friend
```

</TabItem>

<TabItem value="duckdb" label="DuckDB" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```sql
-- $user_id (bigint)

-- ATTACH 'datatable://named_datatable' AS dt;
ATTACH 'datatable' AS dt;
USE dt;

SELECT * FROM friend WHERE id = $user_id;
```

</TabItem>
</Tabs>

We recommend to only have one or a few data tables per workspace, and to use schemas to organize your data.

![Data Table schemas](./datatable_images/datatable_schemas.png 'Data Table schemas')

You can reference schemas normally with the `schema.table` syntax, or set the default search path with this syntax (Python / Typescript) :

```ts
sql = wmill.datatable(':myschema'); // or 'named_datatable:myschema'
sql`SELECT * FROM mytable`; // refers to myschema.mytable
```

### Assets integration

Data tables are **assets** in Windmill.
When you reference a data table in a script, Windmill automatically parses the code and detects them.
You can then click on it and explore the data table in the Database Explorer.

![Data Table asset](./datatable_images/datatable_asset.png 'Data Table asset')

Windmill auto detects if the data table was used in Read (SELECT ... FROM) or Write mode (UPDATE, DELETE ...).
Assets are displayed as asset nodes in flows, making it easy to visualize data dependencies between scripts.

![Data Table asset flow](./datatable_images/datatable_asset_flow.png 'Data Table asset flow')

---

### Workspace-scoped

Data tables are scoped to a **workspace**. All members of the workspace can access its data tables. Credentials are managed internally by Windmill and are **never exposed** to users.

### Special data table: `main`

The data table named **`main`** is the _default_ data table. Scripts can access it without specifying its name.

Example:

```python
## Uses the 'main' data table implicitly
wmill.datatable()
```

---

## Database types

Windmill currently supports two backend database types for Data Tables:

### 1. Custom instance database

- Uses the **Windmill instance database**.
- Zero-setup, one-click provisioning.
- Requires **superadmin** to configure.
- Although the database exists at the _instance level_, it is only accessible to workspaces that define a data table pointing to it.
- See [Custom Instance Database](/docs/core_concepts/custom_instance_database) for more details.

### 2. Postgres resource

- Attach a **workspace Postgres resource** to the data table.
- Ideal when you want full control over database hosting, but still benefit from Windmill's credential management and workspace scoping.

---

## Permissions

Currently, Windmill does **not** enforce database-level permissions in data tables.

- Any workspace member can execute **full CRUD** operations.
- Table/row-level permissions may be introduced in a later version.

Windmill ensures secure access by handling database credentials internally.


## See Also

- [Persistent storage & databases](./index.mdx)
- [Data Table settings](./datatable_images/datatable_settings_1.png 'Data Table settings')
- [Custom Instance Database](/docs/core_concepts/custom_instance_database)
- [Data Table schemas](./datatable_images/datatable_schemas.png 'Data Table schemas')
- [Data Table asset](./datatable_images/datatable_asset.png 'Data Table asset')
