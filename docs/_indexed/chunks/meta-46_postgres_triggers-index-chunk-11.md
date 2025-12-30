---
doc_id: meta/46_postgres_triggers/index
chunk_id: meta/46_postgres_triggers/index#chunk-11
heading_path: ["Postgres triggers", "Troubleshooting"]
chunk_type: prose
tokens: 647
summary: "Troubleshooting"
---

## Troubleshooting
If you're experiencing issues when creating or running Postgres triggers, here are some common problems and how to resolve them.

### Failed to start trigger
When a trigger fails to start, you may encounter one of these issues:

#### 1. WAL sender limit reached
When starting a trigger, you may encounter an error indicating no more room for WAL sender connections. This occurs when an active trigger attempts to establish a connection but the `max_wal_senders` limit has been reached.

#### Try any of these following solutions:
- **Disable one of the running triggers**: You can disable one of the triggers using the same Postgres resource. By doing so, the resource will free up a connection, allowing you to use the newly created trigger.
- **Increase the `max_wal_senders` limit**: You can increase this limit on your Postgres server to allow more connections. For more information, refer to the [Postgres documentation on max_wal_senders](https://www.postgresql.org/docs/current/runtime-config-replication.html#GUC-MAX-WAL-SENDERS).
  **Note**: Simply increasing the limit may not be enough if the `max_replication_slots` limit is also reached.

#### Example Error:
In this example, the database has `max_wal_senders` set to 2. Two triggers are already running (shown as "currently 2" in the error), preventing a third trigger from starting. To resolve this, either disable one of the running triggers or increase the database's `max_wal_senders` limit.

![Error: No more room left for WAL sender](./no_more_room_wal_sender_error.png)

### Failed to create trigger
When creating a new trigger, you may encounter these issues:

#### 1. Replication slot limit reached
If you encounter an error stating that the `max_replication_slots` limit is reached, this error happens because Windmill, in basic mode, tries to create both a replication slot and a publication when a new trigger is set up. If the `max_replication_slots` limit is exceeded, the new replication slot cannot be created.

#### Try any of these following solutions:
- **Delete an existing replication slot**: You can navigate to the [Advanced](#advanced) section and delete an unused replication slot. This will free up space for a new replication slot.
- **Increase the `max_replication_slots` limit**: Increase the replication slots limit on your Postgres server to allow more replication slots. For more information, refer to the [Postgres documentation on max_replication_slots](https://www.postgresql.org/docs/current/runtime-config-replication.html#GUC-MAX-REPLICATION-SLOTS).
- **Manage replication slots and publications directly**: Since Windmill automatically creates a publication and replication slot when setting up a trigger, you can go to the Advanced section of the interface to manage these elements manually. This includes creating, selecting, or deleting replication slots and publications as needed. For more information, see the section on [Managing Postgres publications and replication slots](#advanced).

#### Example Error:
In this example, the database has reached its maximum number of replication slots (shown as "all replication slots are in use" in the error). This prevents the creation of a new trigger since Windmill cannot create the required replication slot. To resolve this, either delete unused replication slots or increase the database's `max_replication_slots` limit.

![Error: No replication slots available](./no_replication_slots_available_error.png)

---

For more help with troubleshooting, refer to the Postgres logs or contact Windmill support.
