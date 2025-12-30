---
doc_id: meta/53_custom_instance_database/index
chunk_id: meta/53_custom_instance_database/index#chunk-3
heading_path: ["Custom Instance Database", "What happens behind the scenes"]
chunk_type: prose
tokens: 141
summary: "What happens behind the scenes"
---

## What happens behind the scenes

When you create a Custom Instance Database, Windmill runs CREATE DATABASE in your instance Postgres server. For security reasons, these databases are not accessed using the Windmill database credentials specified in DATABASE_URL.
Instead, Windmill has a separate user called `custom_instance_user` with a randomly generated password, which is stored in global_settings.custom_instance_pg_databases.user_pwd.

You should never use that password directly. Windmill automatically fetches it safely when needed

`custom_instance_user` is granted access only to the databases created as Custom Instance Databases.

Although it shouldn't be necessary, you can use the `Refresh custom_instance_user password` button in the setup screen to regenerate a password if you encounter authentication issues.
