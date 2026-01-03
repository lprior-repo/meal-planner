---
doc_id: tutorial/windmill/data-tables
chunk_id: tutorial/windmill/data-tables#chunk-3
heading_path: ["Data tables", "Usage"]
chunk_type: code
tokens: 486
summary: "Usage"
---

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
