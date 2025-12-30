---
doc_id: meta/5_sql_quickstart/index
chunk_id: meta/5_sql_quickstart/index#chunk-6
heading_path: ["Quickstart PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake", "Raw queries"]
chunk_type: code
tokens: 867
summary: "Raw queries"
---

## Raw queries

### Safe interpolated arguments

To allow more flexibility than with prepared statements, Windmill offers the possibility to do safe string interpolation in your queries thanks to [backend schema validation](./meta-13_json_schema_and_parsing-index.md#backend-schema-validation). This allows you to use script parameters for elements you would usually not be able to, such as table or column names. In order to avoid SQL injections however, these parameters are checked at runtime and the job will fail if any of these rules is not followed:

- The parameter is a non-empty string.
- The characters are all either alphabetical (ASCII only), numeric, or an underscore (`_`). Meaning no whitespace or symbol is allowed.
- The string does not start with a number.
- If the parameter is an enum, it must be one of the defined variants.

These rules are strict enough to protect from any kind of unexpected injection, but lenient enough to have some powerful use cases. Let's look at an example:

```sql
-- :daily_minimum_calories (int)
-- %%table_name%% fruits/vegetables/cereals

SELECT name, calories FROM %%table_name%% WHERE calories > daily_minimum_calories
```

In this example the argument `table_name` is defined as a string that can be either `"fruits"`, `"vegetables"` or `"cereals"`, and the user of the script can then choose which table to query by setting this argument. If the user of the script tries to query a different table, the job will fail before making a connection to the DB, and thus protecting potentially sensitive data.

It the enum variants are ommited, the field is considered to be a regular string and only the other rules apply:

```sql
-- :daily_minimum_calories (int)
-- %%table_name%%

SELECT name, calories FROM %%table_name%% WHERE calories > daily_minimum_calories
```

Keep in mind that this means users of this script can try this query against all existant and non-existant tables of the database.


### Unsafe interpolation on a REST script

A more convenient but less secure option is to execute raw queries with a TypeScript, Deno or Python client. You can for instance do string interpolation to make the name of the table a parameter of your script: `SELECT * FROM ${table}`. However this is dangerous since the string is directly interpolated and this open the door for [SQL injections](https://en.wikipedia.org/wiki/SQL_injection). Use with care and only in trusted environment.

#### PostgreSQL

<Tabs className="unique-tabs">

<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'windmill-client';
import { Client } from 'pg';

// Define the resource type as specified
type Postgresql = {
  host: string,
  port: number,
  user: string,
  dbname: string,
  sslmode: string,
  password: string,
  root_certificate_pem: string
}

// The main function that will execute a query on a Postgresql database
export async function main(query = 'SELECT * FROM demo', pg_resource: Postgresql) {
  // Initialize the PostgreSQL client with SSL configuration disabled for strict certificate validation
  const client = new Client({
    host: pg_resource.host,
    port: pg_resource.port,
    user: pg_resource.user,
    password: pg_resource.password,
    database: pg_resource.dbname,
    ssl: pg_resource.ssl,
  });

  try {
    // Connect to the database
    await client.connect();

    // Execute the query
    const res = await client.query(query);

    // Close the connection
    await client.end();

    // Return the query result
    return res.rows;
  } catch (error) {
    console.error('Database query failed:', error);
    // Rethrow the error to handle it outside or log it appropriately
    throw error;
  }
}
```

View script on [Windmill Hub](https://hub.windmill.dev/scripts/postgresql/7105/execute-arbitrary-query-and-return-results-postgresql).

</TabItem>

<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import {
  type Sql,
} from "https://deno.land/x/windmill@v1.88.1/mod.ts";

import { Client } from "https://deno.land/x/postgres@v0.17.0/mod.ts"

type Postgresql = {
  host: string;
  port: number;
  user: string;
  dbname: string;
  sslmode: string;
  password: string;
};
export async function main(db: Postgresql, query: Sql = "SELECT * FROM demo;") {
  if (!query) {
    throw Error("Query must not be empty.");
  }
  const { rows } = await pgClient(db).queryObject(query);
  return rows;
}

export function pgClient(db: any) {
  let db2 = {
    ...db,
    hostname: db.host,
    database: db.dbname,
    tls: {
        enabled: false,
    },
  }
  return new Client(db2)
}
```

View script on [Windmill Hub](https://hub.windmill.dev/scripts/postgresql/1294/execute-query-and-return-results-postgresql).

</TabItem>

<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
from typing import TypedDict, Dict, Any
import psycopg2
