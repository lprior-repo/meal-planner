---
doc_id: meta/5_sql_quickstart/index
chunk_id: meta/5_sql_quickstart/index#chunk-4
heading_path: ["Quickstart PostgreSQL, MySQL, MS SQL, BigQuery, Snowflake", "Result collection"]
chunk_type: code
tokens: 204
summary: "Result collection"
---

## Result collection

You can choose what the script will return with the `result_collection` directive :

| Collection strategies             | Output                                   |
| --------------------------------- | ---------------------------------------- |
| last_statement_all_rows (default) | Array of records                         |
| last_statement_first_row          | Record                                   |
| last_statement_all_rows_scalar    | Array of scalars                         |
| last_statement_first_row_scalar   | Scalar                                   |
| all_statements_all_rows           | Array of array of records                |
| all_statements_first_row          | Array of records                         |
| all_statements_all_rows_scalar    | Array of array of scalars                |
| all_statements_first_row_scalar   | Array of scalars                         |
| legacy (deprecated)               | Behavior before introduction of the flag |

Examples:

```sql
-- result_collection=all_statements_first_row_scalar
SELECT 1;
SELECT 2;
SELECT 3;

-- Result: [1, 2, 3]
```

```sql
-- result_collection=last_statement_all_rows
INSERT INTO my_table VALUES ('a', 'b', 'c');
INSERT INTO my_table VALUES ('1', '2', '3');
SELECT * FROM my_table;
-- Result: [
--   { "col1": "a", "col2": "b", "col3": "c" },
--   { "col1": "1", "col2": "2", "col3": "3" }
-- ]
--
```
