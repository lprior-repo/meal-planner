---
doc_id: meta/8_triggers/index
chunk_id: meta/8_triggers/index#chunk-5
heading_path: ["Triggers", "Suspended mode"]
chunk_type: prose
tokens: 241
summary: "Suspended mode"
---

## Suspended mode

When a trigger is in suspended mode, it continues to accept payloads and queue jobs, but those jobs won't run automatically. This is useful for debugging your runnable or trigger logic without disabling the trigger entirely.

To enable suspended mode, toggle the "Suspend job execution" option in the trigger settings:

![Enable suspended mode](./enable_suspended_mode.png)

### Managing suspended jobs

You can review all suspended jobs by clicking the "See suspended jobs" button:

![Open suspended jobs](./open_suspended_jobs_button.png)

This opens a table showing all queued jobs for the trigger:

![Suspended jobs table](./suspended_jobs_table.png)

From this table, you can:
- Resume individual jobs to execute them
- Discard jobs that are no longer needed
- Resume all jobs at once
- Discard all jobs at once

### Updating trigger configuration

If you modify the trigger's configuration (such as changing the runnable, retry settings, or error handler) and save, resumed jobs will run using the updated configuration:

![Reassigned suspended jobs](./reassigned_suspended_jobs.png)

:::warning
If your old runnable had a preprocessor, the new one should have one too (and vice versa), as the arguments format differs based on whether a preprocessor is present.
:::
