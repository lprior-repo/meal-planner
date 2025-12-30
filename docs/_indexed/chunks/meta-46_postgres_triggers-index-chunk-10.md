---
doc_id: meta/46_postgres_triggers/index
chunk_id: meta/46_postgres_triggers/index#chunk-10
heading_path: ["Postgres triggers", "Handling external database hosters"]
chunk_type: prose
tokens: 620
summary: "Handling external database hosters"
---

## Handling external database hosters

When using a Postgres database hosted by external providers, special configurations might be necessary to ensure compatibility with Windmill's Postgres triggers feature. This section provides guidelines for handling various database hosters to avoid common connection issues.

---

### Neon
If your Postgres database is hosted on [**Neon**](https://neon.tech), special considerations are required when configuring your Postgres resource in Windmill. By default, Neon uses **pooled connections** with `pgbouncer`, which are not compatible with Windmill's triggers due to restrictions on the `replica` parameter.

#### Why pooled connections fail by default
Neon’s pooled connections are managed using `pgbouncer`. By default, `pgbouncer` allows only a specific subset of startup parameters, and **logical replication**, which Windmill uses to create triggers, requires the `replica` parameter, which is not allowed by default.

If you attempt to use Neon's `-pooler` host without modifying the `pgbouncer` configuration, Windmill's triggers will fail to connect because `pgbouncer` will reject the `replica` parameter.

---

#### Avoiding common pitfalls: Configuring Neon with Windmill

When entering the database details manually (`host`, `port`, `db_name`, `password`, `ssl_mode`, `root_certificate_pem`, etc.), you have two options:

---

#### Option 1: Use the non-pooled connection host

**Recommended for simplicity.**  
Avoid using the `-pooler` host provided by Neon.

1. Remove the `-pooler` suffix from the host.
   Example:
   - **Original `host` (with pooled connection)**:  
     `<cluster-name>-pooler.neon.tech`
   - **Updated `host` (without pooled connection)**:  
     `<cluster-name>.neon.tech`

2. Enter the remaining parameters as provided by Neon:
   - **`db_name`**: The name of the database
   - **`password`**: The password for your database
   - **`port`**: The port (usually `5432`)
   - **`ssl_mode`**: Typically `require`
   - **`root_certificate_pem`**: Optional certificate for secure SSL connections

This configuration works without requiring changes to Neon's `pgbouncer` settings.

#### **Good configuration**
For example, if Neon provides the following details:
- `host`: `<cluster-name>-pooler.neon.tech`
- `db_name`: `my_database`
- `password`: `my_password`
- `port`: `5432`
- `ssl_mode`: `require`

Configure the Postgres resource as follows:
- **`host`**: `<cluster-name>.neon.tech`  
  _(Remove the `-pooler` suffix.)_
- **`db_name`**: `my_database`  
- **`password`**: `my_password`  
- **`port`**: `5432`  
- **`ssl_mode`**: `require`  
- **`root_certificate_pem`**: Provide if required by Neon.

---

#### Option 2: Enable pooled connections by modifying `pgbouncer`

**For advanced users who prefer using pooled connections.**  
To use Neon’s `-pooler` host with Windmill's Postgres triggers, you must update the `pgbouncer` configuration on your Neon instance to allow the `replica` parameter. 

1. **Locate the `pgbouncer` configuration file**:  
   Check [Neon’s documentation](https://neon.tech/docs/introduction) for guidance on accessing and modifying the `pgbouncer` configuration.

2. **Update the `ignore_startup_parameters` setting**:  
   Add `replica` to the `ignore_startup_parameters` list in the `pgbouncer` configuration file.

   Example:
   ```txt
   ignore_startup_parameters = replica

---

### Future updates for other database hosting services

This section will be updated if additional database hosting services require special configurations for Postgres triggers.  
If you are using a database service other than Neon and encounter issues when setting up triggers, please **contact Windmill support** for assistance.  
We’ll work with you to identify and document the specific requirements needed for compatibility.


---
