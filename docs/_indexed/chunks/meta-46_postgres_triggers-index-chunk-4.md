---
doc_id: meta/46_postgres_triggers/index
chunk_id: meta/46_postgres_triggers/index#chunk-4
heading_path: ["Postgres triggers", "Additional Configuration for Logical Replication"]
chunk_type: code
tokens: 478
summary: "Additional Configuration for Logical Replication"
---

## Additional Configuration for Logical Replication

For logical replication to work properly, you need to configure additional parameters in your `postgresql.conf` file. These parameters control the number of replication processes and slots available for replication. Both settings require a restart of your Postgres instance to take effect.

### `max_wal_senders`

The `max_wal_senders` setting determines the maximum number of **walsender** processes that can run concurrently. A **walsender** is responsible for sending the Write-Ahead Log (WAL) data to subscribers for logical replication. The default value is 10, but you can increase this based on your replication needs.

```ini
#max_wal_senders = 10  # max number of walsender processes (change requires restart)
```

- **Impact on Triggers**: Each active trigger in logical replication will use a **walsender** process. So, if `max_wal_senders` is set to 10, only 10 active triggers can be used at the same time. If you reach this limit, you will need to increase the `max_wal_senders` value to accommodate more active triggers.

#### `max_replication_slots`

The `max_replication_slots` setting determines how many **replication slots** can be created. Replication slots are used to maintain state for each logical replication subscription. This setting also limits the number of triggers that can be created for logical replication.

```ini
#max_replication_slots = 10  # max number of replication slots (change requires restart)
```

- **Impact on Trigger Creation**: You can only create as many triggers as there are replication slots available. So if `max_replication_slots` is set to 10, you will be able to create a maximum of 10 triggers. If you need more triggers, you will need to increase the `max_replication_slots` value.

### Summary of limits

- **Active triggers**: The number of active triggers you can have is limited by `max_wal_senders`. If you set `max_wal_senders` to 10, only 10 active triggers can be running simultaneously.
  
- **Trigger creation**: The number of triggers you can create is limited by `max_replication_slots`. If you set `max_replication_slots` to 10, you can only create 10 triggers in total.

---

### Final considerations

When configuring these settings, make sure to account for the number of active triggers and replication slots needed for your application. If you expect to have many triggers or high replication activity, you may need to increase both `max_wal_senders` and `max_replication_slots`.
