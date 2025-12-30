---
doc_id: meta/5_sql_quickstart/index
chunk_id: meta/5_sql_quickstart/index#chunk-3
heading_path: ["Quickstart PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake", "Create script"]
chunk_type: code
tokens: 1144
summary: "Create script"
---

## Create script

Next, let's create a script that will use the newly created Resource. From the Home page,
click on the "+Script" button. Name the Script, give it a summary, and select your preferred language, [PostgreSQL](#postgresql-1), [MySQL](#mysql-1), [MS SQL](#ms-sql-1), [BigQuery](#bigquery-1), [Snowflake](#snowflake-1).

![Script creation first step](../../../assets/integrations/sql_new_script.png.webp)

You can also give more details to your script, in the [settings section](./tutorial-script_editor-settings.md), you can also get back to that later at any point.

### PostgreSQL

Arguments need to be passed in the given format:

```sql
-- $1 name1 = default arg
-- $2 name2
INSERT INTO demo VALUES ($1::TEXT, $2::INT) RETURNING *
```

"name1", "name2" being the names of the arguments, and "default arg" the optional default value.

Database resource can be specified from the UI or directly within script with a line `-- database resource_path`.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/pin_database.mp4"
/>

<br/>

You can then write your prepared statement.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/test_postgres.mp4"
/>

### MySQL

Arguments need to be passed in the given format:

```sql
-- :name1 (text) = default arg
-- :name2 (int)
INSERT INTO demo VALUES (:name1, :name2)
```

"name1", "name2" being the names of the arguments, and "default arg" the optional default value.

Database resource can be specified from the UI or directly within script with a line `-- database resource_path`.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/pin_database.mp4"
/>

<br/>
You can then write your prepared statement.

![Mysql statement](./mysql_statement.png.webp)

### MS SQL

Arguments need to be passed in the given format:

```sql
-- @P1 name1 (varchar) = default arg
-- @P2 name2 (int)
INSERT INTO demo VALUES (@P1, @P2)
```

"name1", "name2" being the names of the arguments, and "default arg" the optional default value.

Database resource can be specified from the UI or directly within script with a line `-- database resource_path`.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/pin_database.mp4"
/>

<br/>
You can then write your prepared statement.

![Mysql statement](./mssql_statement.png.webp)

### BigQuery

Arguments need to be passed in the given format:

```sql
-- @name1 (string) = default arg
-- @name2 (integer)
-- @name3 (string[])
INSERT INTO `demodb.demo` VALUES (@name1, @name2, @name3)
```

"name1", "name2", "name3" being the names of the arguments, "default arg" the optional default value and `string`, `integer` and `string[]` the types.

Database resource can be specified from the UI or directly within script with a line `-- database resource_path`.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/pin_database.mp4"
/>

<br/>
You can then write your prepared statement.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/test_bigquery.mp4"
/>

### Snowflake

Arguments need to be passed in the given format:

```sql
-- ? name1 (varchar) = default arg
-- ? name2 (int)
INSERT INTO demo VALUES (?, ?)
```

"name1", "name2" being the names of the arguments, "default arg" the optional default value and `varchar` & `int` the types.

Database resource can be specified from the UI or directly within script with a line `-- database resource_path`.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/pin_database.mp4"
/>

<br/>
You can then write your prepared statement.

![Snowflake statement](./snowflake_statement.png.webp)

### Amazon Redshift

Since Redshift is compatible with Windmill's PostgreSQL, you can follow the same instructions as for [PostgreSQL scripts](#postgresql-1). Make sure to select your Redshift instance as a resource.

Remeber when using a a Redshift resource, you should write valid Redshift, and not PostgreSQL. For example the `RETURNING *` syntax is not supported, so you may want to change the default script to something like:

```sql
-- $1 name1 = default arg
-- $2 name2
INSERT INTO demo VALUES ($1::TEXT, $2::INT)
```

Learn more about [the differences here](https://docs.aws.amazon.com/redshift/latest/dg/c_redshift-and-postgres-sql.html).

### Oracle

Arguments need to be passed in the given format:

```sql
-- database f/your/path
-- :name1 (text) = default arg
-- :name2 (int)
-- :name3 (int)
INSERT INTO demo VALUES (:name1, :name2);
UPDATE demo SET col2 = :name3 WHERE col2 = :name2;
```

"name1", "name2", "name3" being the names of the arguments, and "default arg" the optional default value.

### DuckDB

DuckDB arguments need to be passed in the given format:
```sql
-- $name1 (text) = default arg
-- $name2 (int)
INSERT INTO demo VALUES ($name1, $name2)
```
"name1", "name2" being the names of the arguments, and "default arg" the optional default value.  

You can pass a file on S3 as an argument of type s3object. This will substitute it with the correct 's3:///...' path at runtime.
You can then query this file using the standard read_csv/read_parquet/read_json functions :
```sql
-- $file (s3object)
SELECT * FROM read_parquet($file)
```

Alternatively, you can reference files on the workspace directly using s3:// notation.

For primary workspace storage:
```sql
SELECT * FROM read_parquet('s3:///path/to/file.parquet')
```

For secondary storage:
```sql
SELECT * FROM read_parquet('s3://<secondary_storage>/path/to/file.parquet')
```

This notation also works with glob patterns:
```sql
SELECT * FROM read_parquet('s3:///myfiles/*.parquet')
```

The s3:// notation now uses the Windmill S3 Proxy by default.

You can also attach to other database resources (BigQuery, PostgreSQL and MySQL). We use the official and community DuckDB extensions under the hood :
```sql
ATTACH '$res:u/demo/amazed_postgresql' AS db (TYPE postgres);
SELECT * FROM db.public.friends;
```


Database resource can be specified from the UI or directly within the script with a line `-- database resource_path`.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/pin_database.mp4"
/>

<br/>
You can then write your prepared statement.
