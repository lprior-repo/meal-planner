---
doc_id: meta/1_self_host/index
chunk_id: meta/1_self_host/index#chunk-7
heading_path: ["Self-host", "Run Windmill without using a Postgres superuser"]
chunk_type: code
tokens: 196
summary: "Run Windmill without using a Postgres superuser"
---

## Run Windmill without using a Postgres superuser

Create the database with your non-super user as owner:

```sql
CREATE DATABASE windmill OWNER nonsuperuser
```

As a superuser, create the windmill_user and windmill_admin roles with the
proper privileges, using:

```bash
curl https://raw.githubusercontent.com/windmill-labs/windmill/main/init-db-as-superuser.sql -o init-db-as-superuser.sql
psql <DATABASE_URL> -f init-db-as-superuser.sql
```

where `init-db-as-superuser.sql` is
[this file](https://raw.githubusercontent.com/windmill-labs/windmill/main/init-db-as-superuser.sql).

Then finally, run the following commands:

```sql
GRANT windmill_admin TO nonsuperuser;
GRANT windmill_user TO nonsuperuser;
```

**NOTE: Make sure the roles `windmill_admin` and `windmill_user` have access to the database and the schema:**

You can ensure this by running the following commands as superuser while inside the database. Replace the schema
name `public` with your schema, in case you use a different one:

```sql
GRANT USAGE ON SCHEMA public TO windmill_admin;
GRANT USAGE ON SCHEMA public TO windmill_user;
```

:::note
If you use a schema other than `public`, pass `PG_SCHEMA=<schema>` as an environment variable to every `windmill_server` container.
:::
