---
doc_id: meta/53_custom_instance_database/index
chunk_id: meta/53_custom_instance_database/index#chunk-2
heading_path: ["Custom Instance Database", "Setup"]
chunk_type: prose
tokens: 205
summary: "Setup"
---

## Setup

When setting up a Ducklake or Data Table, superadmins can select the "Instance" option to use the Windmill instance database as the backend.

On the right of the dropdown, you will see the status of the custom instance database. You can open the dropdown to select a previously created Custom Instance Database, or type any name to create a new one.

In this example, we see that ducklake_catalog requires setup. Let's click on Setup and carry on.

![Custom instance database settings](./custom_instance_db_setup_1.png 'Custom instance database settings 1')

![Custom instance database settings](./custom_instance_db_setup_2.png 'Custom instance database settings 2')

The custom instance database is ready to go ! Click on Manage to explore the database :

![Custom instance database settings](./custom_instance_db_manager.png 'Custom instance database manager')

The database is empty, but you can create tables and manage it as you would with any Postgres database. For Ducklake, you should not touch the database directly, as Ducklake will create its own metadata tables.
