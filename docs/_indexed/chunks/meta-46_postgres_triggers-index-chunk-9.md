---
doc_id: meta/46_postgres_triggers/index
chunk_id: meta/46_postgres_triggers/index#chunk-9
heading_path: ["Postgres triggers", "Creating a script from tracked tables"]
chunk_type: code
tokens: 817
summary: "Creating a script from tracked tables"
---

## Creating a script from tracked tables

Windmill enables you to automatically generate a script template for specific tables and/or schemas tracked by a trigger. This feature simplifies the creation of a TypeScript script with the necessary structure to handle data passed by the trigger.

### Prerequisites

- Postgres resource: a Postgres [resource](./meta-3_resources_and_types-index.md) must be configured in your environment to enable this feature.
- At least one schema: you need to select at least one schema to track.
- Specific tables and/or schema: This feature works only for specific tables and/or schemas. Make sure your selection matches the criteria for script generation.

### How to use

1. Set up Postgres resource: Ensure that a Postgres resource is configured in the resources page.

2. Select schema and tables: Choose the schema and tables you want to track. Note that this feature does not work for all tables; only those meeting the criteria for tracking will be available.

3. Click on "Create from template": After selecting the desired tables and schemas, click on the Create from Template button. This will open a new tab containing a TypeScript script.

   - The script will include a main function that takes an argument representing the information sent to the script. This argument is a JSON object structured as follows:

```json
{
  "transaction_type": "insert" | "update" | "delete",
  "schema_name": "string",
  "table_name": "string",
  "old_row?": {
    ...
  },
  "row": {
    ...
  }
}
```
### Explanation of fields

- transaction_type: Specifies the type of change (either `insert`, `update`, or `delete`).
- schema_name: The name of the schema being tracked (type: `string`).
- table_name: The name of the table being tracked (type: `string`).
- old_row (optional): Contains the previous state of the row before the change occurred. This field is only present for `update` transactions and reflects the values of the row prior to the update.
- row: Contains the data of the row involved in the transaction. The data type of each field in `row` depends on the column's data type in the Postgres table. For `insert` and `update` transactions, this represents the new or updated values. For `delete` transactions, this represents the deleted row.

#### Example table schema

Consider a table `users` in the public schema with the following SQL definition:

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY, 
    name VARCHAR(100) NOT NULL,
    lastname VARCHAR(100) NOT NULL,
    age INT CHECK (age > 0),
    personal_information JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
```
For this schema, the corresponding row in the JSON object would look like this:

```json
{
    row: {
		id?: number,
		name?: string,
		lastname?: string,
		age: number,
		personal_information: unknown,
		created_at?: Date,
		updated_at?: Date,
	}
}
```
### Key notes

- Transaction types: The `transaction_type` field in the JSON object can be one of `insert`, `update`, or `delete`, depending on the change type in the tracked table.
- Row data: The `row` field contains the data of the specific table or schema, and can be used directly in your script for processing.
- Old row: The `old_row` field is included only for `update` transactions and contains the previous values of the row before the update occurred. This is useful for comparing changes or auditing modifications.

### Script template example

Once the template is generated, you can modify it to meet your needs. Below is an example of the generated script template, based on a sample transaction, with a `users` table in the public schema.

```typescript
export async function main(
  transaction_type: "insert" | "update" | "delete",
  schema_name: string,
  table_name: string,
  old_row?: {
		id?: number,
		name?: string,
		lastname?: string,
		age: number,
		personal_information: unknown,
		created_at?: Date,
		updated_at?: Date,
	},
  row: {
		id?: number,
		name?: string,
		lastname?: string,
		age: number,
		personal_information: unknown,
		created_at?: Date,
		updated_at?: Date,
	}
) {
}
```
---
