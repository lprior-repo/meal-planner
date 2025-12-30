---
doc_id: meta/46_postgres_triggers/index
chunk_id: meta/46_postgres_triggers/index#chunk-7
heading_path: ["Postgres triggers", "Additional options"]
chunk_type: prose
tokens: 1497
summary: "Additional options"
---

## Additional options
The following section showcases additional options provided by PostgreSQL's logical replication feature that Windmill integrates with.

### Filtering rows with WHERE condition
When tracking specific tables, you can filter rows by providing a WHERE condition.

Key notes:
- The `WHERE` clause allows only simple expressions.
- It cannot contain:
  - User-defined functions, operators, types, and collations.
  - System column references.
  - Non-immutable built-in functions.

Important:
- You only need to provide the condition, not the entire `WHERE` clause. For example, instead of writing `WHERE speciality = 'croissant'`, just provide the condition: `speciality = 'croissant'`.
- If your trigger is set to track `UPDATE` and/or `DELETE` transactions, the `WHERE` clause can only reference columns that are part of the table’s replica identity.  
  See the [REPLICA IDENTITY documentation](https://www.postgres.org/docs/current/sql-altertable.html#SQL-ALTERTABLE-REPLICA-IDENTITY) for more details.
- If your trigger tracks only `INSERT` transactions, the `WHERE` clause can reference any column.

For more details, refer to the [Postgres WHERE clause documentation](https://www.postgresql.org/docs/current/logical-replication-row-filter.html#LOGICAL-REPLICATION-ROW-FILTER-RESTRICTIONS).

Illustration:  
Here’s an example showing how to filter rows based on the condition `speciality = 'croissant'` in the `bakery` table of the `paris` schema:

![Where condition example](./where_condition_paris_bakery.png 'Filtering rows example: speciality = croissant')

---

### Selecting specific columns

When tracking specific tables, you can reduce the data sent to the triggered function by retrieving only the columns you need.

However, **if the transaction being tracked includes `UPDATE` or `DELETE` transactions**, selecting specific columns can introduce constraints:

#### Key considerations for `INSERT`, `UPDATE`, and `DELETE` transactions:
- **INSERT** transactions are unaffected by this limitation, and you can select any columns, regardless of whether they are included in the replica identity.
- For `UPDATE` or `DELETE` transactions, the columns you select **must be part of the table's replica identity**. If the selected columns are not part of the replica identity, the database will fail to process the query.

#### What happens if the configuration is invalid?
- If a trigger includes `UPDATE` or `DELETE` transactions while excluding columns required for the replica identity, the associated database query will fail.
- To resolve this issue, you have two options:
  1. **Update the trigger configuration**: Modify the trigger to include the columns that are part of the replica identity.
  2. **Delete and recreate the publication**: Delete the existing publication and configure a new one that accommodates the necessary columns.

For more details, see the [REPLICA IDENTITY documentation](https://www.postgresql.org/docs/current/sql-altertable.html#SQL-ALTERTABLE-REPLICA-IDENTITY).

---

#### Example

Consider the `bakery` table in the `paris` schema. The table has three columns: `id`, `name`, and `address`.
By default, PostgreSQL uses the `DEFAULT` replica identity, which means it tracks the primary key column(s) to identify rows for updates and deletes. If your trigger includes `UPDATE` or `DELETE` transactions and only non-primary key columns are selected (e.g., `name` and `address`), those transactions will fail because the primary key column is required for tracking changes.

#### 1. `DEFAULT` replica identity
The default replica identity tracks only the primary key column(s). For the `bakery` table, the primary key could be any column, such as `id`, `bakery_id`, or another column designated by the user.

- **Correct configuration**: 
    - The trigger should track the primary key column (e.g., `id`, `bakery_id`, etc.), along with any additional columns required for your logic.
    - For example, if `id` is the primary key, the trigger should at least track `id`.
    - This ensures that `UPDATE` and `DELETE` transactions will succeed.
    - Here’s an example of the correct column selection (assuming the primary key is `id`):

    ![Correct column selection example](./correct_selection_columns.png 'Correct column selection example')

- **Incorrect configuration**:
    - If only `name` and `address` are selected, and the primary key column (e.g., `id`) is not included in the tracked columns, `UPDATE` and `DELETE` transactions will fail.
    - To fix this:
      - Add the primary key column (e.g., `id`, `bakery_id`, or whatever the primary key column is named) to the trigger's tracked columns.
      - Alternatively, update or delete the publication and recreate it with the correct configuration.

#### 2. `USING INDEX` replica identity
With `USING INDEX index_name`, the replica identity tracks the columns of a unique index.

- **Correct configuration**: 
    - The trigger must track at least the columns that are part of the unique index.
    - If the `bakery` table has a unique index (e.g., `idx_bakery_name_address`) covering `name` and `address`, the trigger should track **at least** those two columns, but it can also track other columns, such as `id`, if needed for your logic.

- **Incorrect configuration**:
    - If the columns tracked by the trigger do not match those in the unique index, `UPDATE` and `DELETE` transactions will fail.
    - To fix this:
      - Ensure the trigger tracks **at least** the columns in the `USING INDEX` replica identity or create an appropriate unique index.

#### 3. `FULL` replica identity
The `FULL` replica identity records the old values of **all columns** in the row.

- **Correct configuration**: 
    - The trigger can track any combination of columns, as all columns are tracked with `FULL` replica identity.
    - For example, tracking `name`, `address`, and the primary key column (e.g., `id`, `bakery_id`) is completely acceptable and won’t cause any issues.

- **Incorrect configuration**:
    - There is no issue with tracking any columns when using the `FULL` replica identity because the replica identity covers all columns in the row. However, using more columns than necessary may be inefficient.
    - If performance is a concern, it's recommended to limit the tracked columns to those that are necessary for the trigger.

#### 4. `NOTHING` replica identity
The `NOTHING` replica identity records no information about the old row, which is typically used for system tables.

- **Correct configuration**:
    - This configuration is generally not applicable to user tables like `bakery`, but if applied to the `bakery` table, the trigger would not be able to track `UPDATE` or `DELETE` transactions.
    - This means no `UPDATE` or `DELETE` operations would work with the trigger, as no data would be recorded for the affected rows.

- **Incorrect configuration**:
    - The `NOTHING` replica identity will cause the trigger to fail for `UPDATE` and `DELETE` transactions. You cannot fix this without changing the replica identity to one of the other options (`DEFAULT`, `USING INDEX`, or `FULL`).

#### Conclusion
- **For `UPDATE` and `DELETE` operations**, ensure that the tracked columns include the primary key column (e.g., `id`, `bakery_id`, or whatever the primary key column is named) or match the requirements of the replica identity configuration.
- If the default replica identity is used (`DEFAULT`), ensure that the primary key column is included in the tracked columns to avoid failures with `UPDATE` and `DELETE`.
- For `USING INDEX`, make sure the trigger tracks **at least** the columns in the unique index. You can also track other columns, but the index columns must be tracked to ensure the correct behavior for `UPDATE` and `DELETE` transactions.
- If the replica identity is set to `FULL`, you can safely track any columns.
- Avoid using `NOTHING` replica identity if you need to track `UPDATE` and `DELETE` operations.

---
