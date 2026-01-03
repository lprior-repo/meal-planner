---
doc_id: tutorial/windmill/ducklake
chunk_id: tutorial/windmill/ducklake#chunk-3
heading_path: ["Ducklake", "Using Ducklake in scripts"]
chunk_type: code
tokens: 287
summary: "Using Ducklake in scripts"
---

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
