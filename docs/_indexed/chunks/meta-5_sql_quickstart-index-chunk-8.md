---
doc_id: meta/5_sql_quickstart/index
chunk_id: meta/5_sql_quickstart/index#chunk-8
heading_path: ["Quickstart PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake", "Define the MySQL resource type"]
chunk_type: prose
tokens: 128
summary: "Define the MySQL resource type"
---

## Define the MySQL resource type
class mysql(TypedDict):
    ssl: bool
    host: str
    port: float
    user: str
    database: str
    password: str

def main(mysql_credentials: mysql, query; str) -> str:
    # Connect to the MySQL database using the provided credentials
    connection = mysql_connector.connect(
        host=mysql_credentials["host"],
        user=mysql_credentials["user"],
        password=mysql_credentials["password"],
        database=mysql_credentials["database"],
        port=int(mysql_credentials["port"]),
        ssl_disabled=not mysql_credentials["ssl"],
    )

    # Create a cursor object
    cursor = connection.cursor()

    # Execute the query
    cursor.execute(query)

    # Fetch one result
    result = cursor.fetchone()

    # Close the cursor and connection
    cursor.close()
    connection.close()

    # Return the result
    return str(result[0])
```

View script on [Windmill Hub](https://hub.windmill.dev/scripts/mysql/7109/execute-arbitrary-query-mysql).

</TabItem>
</Tabs>

And so on for [MS SQL](#ms-sql), [BigQuery](#bigquery) and [Snowflake](#snowflake).
