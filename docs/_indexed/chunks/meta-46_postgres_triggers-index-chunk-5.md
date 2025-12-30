---
doc_id: meta/46_postgres_triggers/index
chunk_id: meta/46_postgres_triggers/index#chunk-5
heading_path: ["Postgres triggers", "How to use"]
chunk_type: prose
tokens: 305
summary: "How to use"
---

## How to use
Learn how to set up and configure Postgres triggers in Windmill through these key steps.

### Create a Postgres trigger
To begin, navigate to the Postgres triggers page and create a new trigger. Follow the steps below to set up your environment.

### Set up a Postgres resource
You need to either:
- Create a new Postgres resource by providing:
  - Hostname, port, database name, username, and password.
  - Advanced options such as SSL settings if needed.
- Reuse an existing Postgres resource.

### Define what to track
Once the Postgres resource is configured, you can choose what to track.

#### All tables
The trigger will listen for transactions on all tables in the database.

Example:

![Track all tables example](./track_all_tables.png 'Track all tables example')

#### Specific schemas
The trigger will listen for transactions on all tables within the selected schemas. Any new tables added to these schemas in the future will also be tracked automatically.

Example:  
Tracking the `public` and `marketing` schemas:

![Track specific schemas example](./track_specific_schemas_marketing_public.png 'Track specific schemas: marketing and public')

#### Specific tables
The trigger will listen only for transactions on the specified tables. You can also choose which columns to retrieve when tracking specific tables.

Example:  
In this setup, the `bakery` table in the `paris` schema is tracked, but only the `name` and `address` columns are retrieved.

![Track specific tables example](./track_specific_tables_bakery.png 'Track specific tables: user and bakery')

---
