---
doc_id: meta/46_postgres_triggers/index
chunk_id: meta/46_postgres_triggers/index#chunk-8
heading_path: ["Postgres triggers", "Advanced"]
chunk_type: prose
tokens: 503
summary: "Advanced"
---

## Advanced
The Advanced section provides granular control over publications and replication slots, offering flexibility beyond Windmill's default automatic management.
### Managing Postgres publications
By default, Windmill automatically creates a publication and a replication slot for you when setting up a trigger. However, in the Advanced section, you can:

- **Create a custom publication**: If you prefer to use your own publication, you can create it directly from the interface.
    - Example: Create a publication named `windmill_publication_gracious`, which tracks all tables in the `public` and `private` schemas, and is set to track only update and delete transactions.

      ![Creating publication example](./create_publication_example.png 'Create a custom publication: windmill_publication_illuminating')

- **Choose an existing publication**: Instead of relying on the default publication created by Windmill, you can select an existing publication from your database to use for your trigger.
    - For example, when retrieving the publication `windmill_publication_non_violent`, all tables are tracked, and the publication tracks insert, update, and delete transactions by default.
    - In the image below, the tracked tables and insert transaction type for the publication are displayed. You can use the publication as is or:
      - Update the publication by adding or removing tables and schemas being tracked, or modifying the transaction types.
      - Delete the publication if no longer needed.

      ![Retrieving and managing publication example](./retrieve_publication_example.png 'Retrieve and manage publication: windmill_publication_non_violent')

For more information on Postgres publications, refer to the [Postgres documentation on publications](https://www.postgresql.org/docs/current/logical-replication-publication.html).

---

### Managing Postgres replication slots
In the Advanced section, you can also manage your replication slots. Windmill will automatically create a replication slot for you by default, but you can interact with replication slots as follows:

- **Create a custom replication slot**: If needed, you can create your own replication slot directly in the interface.
    - Example: Create a replication slot named `windmill_replication_adored`.

      ![Creating Replication Slot Example](./create_replication_slot_example.png 'Creating Replication Slot Example')

- **Choose an existing replication slot**: You can select an existing replication slot from your database and link it to the trigger.
    - Example: Retrieve and manage the replication slot `windmill_1737909146368_4zuvg52h3pge` for your trigger.

      ![Retrieving Replication Slot Example](./retrieve_replication_slot_example.png 'Retrieving Replication Slot Example')

- **Delete a replication slot**: If a replication slot is no longer necessary, you can delete it through the interface.

Windmill will display only logical replication slots and inactive slots. For more details, refer to the [Postgres documentation on replication slots](https://www.postgresql.org/docs/current/warm-standby.html#STREAMING-REPLICATION-SLOTS).

---
