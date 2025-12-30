---
doc_id: meta/46_postgres_triggers/index
chunk_id: meta/46_postgres_triggers/index#chunk-3
heading_path: ["Postgres triggers", "Requirements"]
chunk_type: code
tokens: 347
summary: "Requirements"
---

## Requirements

Before using Postgres triggers with Windmill, your database must be properly configured for logical replication. The primary requirement is setting the Write-Ahead Log (WAL) level to `'logical'`.

### Setting `wal_level` to `logical`

You have two options to configure this setting. Both options require a restart of your Postgres instance to take effect.

#### Option 1: Using SQL (requires database restart)

1. Run the following SQL command to set `wal_level` to `'logical'`:         
   
  ```sql
   ALTER SYSTEM SET wal_level = 'logical';
  ```

2. After executing the command, restart your Postgres instance for the changes to take effect.

#### Option 2: Editing the `postgresql.conf` file (requires database restart)

1. Locate and open your `postgresql.conf` file. The location of this file may vary depending on your installation.

2. Look for the `wal_level` setting. If it's not already present, **add** the following line to the file:

  ```ini
   wal_level = logical
  ```

   If the setting is already there, **update** it to `logical`.

3. Save the file and restart your Postgres instance for the changes to take effect.

### Verifying logical replication

You can verify that logical replication is enabled by running the following query:

```sql
SHOW wal_level;
```

This should return:

```plaintext
 wal_level
-----------
 logical
```

### Impact of Enabling Logical Replication

Enabling logical replication turns on detailed logging, which is essential for supporting the replication process. Be aware that this will increase the amount of data written to the Write-Ahead Log (WAL). Typically, you can expect a 10% to 30% increase in the amount of data written to the WAL, depending on the volume of write activity in your database.

---
