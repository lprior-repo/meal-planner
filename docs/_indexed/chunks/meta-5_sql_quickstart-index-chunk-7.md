---
doc_id: meta/5_sql_quickstart/index
chunk_id: meta/5_sql_quickstart/index#chunk-7
heading_path: ["Quickstart PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake", "Define the PostgreSQL resource type as specified"]
chunk_type: code
tokens: 681
summary: "Define the PostgreSQL resource type as specified"
---

## Define the PostgreSQL resource type as specified
class postgresql(TypedDict):
    host: str
    port: int
    user: str
    dbname: str
    sslmode: str
    password: str
    root_certificate_pem: str

def main(query: str, db_config: postgresql) -> Dict[str, Any]:
    # Connect to the PostgreSQL database
    conn = psycopg2.connect(
        host=db_config["host"],
        port=db_config["port"],
        user=db_config["user"],
        password=db_config["password"],
        dbname=db_config["dbname"],
        sslmode=db_config["sslmode"],
        sslrootcert=db_config["root_certificate_pem"],
    )

    # Create a cursor object
    cur = conn.cursor()

    # Execute the query
    cur.execute(query)

    # Fetch all rows from the last executed statement
    rows = cur.fetchall()

    # Close the cursor and connection
    cur.close()
    conn.close()

    # Convert the rows to a list of dictionaries to make it more readable
    columns = [desc[0] for desc in cur.description]
    result = [dict(zip(columns, row)) for row in rows]

    return result
```

View script on [Windmill Hub](https://hub.windmill.dev/scripts/postgresql/7106/execute-arbitrary-query-postgresql).

</TabItem>
</Tabs>

:::tip

You can find more Script examples related to PostgreSQL on
[Windmill Hub](https://hub.windmill.dev/integrations/postgresql).

:::

### MySQL

The same logic goes for MySQL.

<Tabs className="unique-tabs">

<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import { createConnection } from 'mysql';

// Define the Mysql resource type as specified
type Mysql = {
  ssl: boolean,
  host: string,
  port: number,
  user: string,
  database: string,
  password: string
}

// The main function that will execute a query on a Mysql resource
export async function main(mysqlResource: Mysql, query: string): Promise<any> {
  // Create a promise to handle the MySQL connection and query execution
  return new Promise((resolve, reject) => {
    // Create a connection to the MySQL database using the resource credentials
    const connection = createConnection({
      host: mysqlResource.host,
      port: mysqlResource.port,
      user: mysqlResource.user,
      password: mysqlResource.password,
      database: mysqlResource.database,
      ssl: mysqlResource.ssl
    });

    // Connect to the MySQL database
    connection.connect(err => {
      if (err) {
        reject(err);
        return;
      }

      // Execute the query provided as a parameter
      connection.query(query, (error, results) => {
        // Close the connection after the query execution
        connection.end();

        if (error) {
          reject(error);
        } else {
          resolve(results);
        }
      });
    });
  });
}
```

View script on [Windmill Hub](https://hub.windmill.dev/scripts/mysql/7108/execute-arbitrary-query-mysql).

</TabItem>

<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import { createPool as createMysqlPool } from "npm:mysql2/promise";

// Define the MySQL resource type as specified
type Mysql = {
  ssl: boolean,
  host: string,
  port: number,
  user: string,
  database: string,
  password: string

}

// The main function that executes a query on a MySQL database
export async function main(
  mysqlResource: Mysql,
  query: string,
): Promise<any> {
  // Adjust the SSL configuration based on the mysqlResource.ssl value
  const sslConfig = mysqlResource.ssl ? { rejectUnauthorized: true } : false;

  // Create a new connection pool using the provided MySQL resource
  const pool = createMysqlPool({
    host: mysqlResource.host,
    user: mysqlResource.user,
    database: mysqlResource.database,
    password: mysqlResource.password,
    port: mysqlResource.port,
    // Use the adjusted SSL configuration
    ssl: sslConfig,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
  });

  try {
    // Get a connection from the pool and execute the query
    const [rows] = await pool.query(query);
    return rows;
  } catch (error) {
    // If an error occurs, throw it to be handled by the caller
    throw new Error(`Failed to execute query: ${error}`);
  } finally {
    // Always close the pool after the operation is complete
    await pool.end();
  }
}

```

View script on [Windmill Hub](https://hub.windmill.dev/scripts/mysql/7107/execute-arbitrary-query-mysql).

</TabItem>

<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
from typing import TypedDict
import mysql.connector as mysql_connector
