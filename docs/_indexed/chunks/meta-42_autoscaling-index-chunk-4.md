---
doc_id: meta/42_autoscaling/index
chunk_id: meta/42_autoscaling/index#chunk-4
heading_path: ["Autoscaling", "Autoscaling algorithm"]
chunk_type: prose
tokens: 573
summary: "Autoscaling algorithm"
---

## Autoscaling algorithm

The autoscaling algorithm is based on the number of jobs waiting for workers in the queue for the tags that the worker group is listening from (tags can be overriden) and based on the occupancy rate of the workers of that worker group.

The algorithm is as follows:

Every 30s, for every worker group autoscaling configuration:

1. It checks if the current number of workers (`count`) is within the allowed range (between `min_workers` and `max_workers`). If not, it adjusts the number to fit within this range.
2. If there are more than (`full_scale_jobs_waiting` OR `max_workers` if not defined) jobs , it will increase the number of workers up to `max_workers` if there are less (otherwise if workers already above or equal target, do nothing), that's a "full scale-out". Note that full-scale out events are not subject to the cooldown period since they are meant to handle sudden spike.
3. The function looks at the last autoscaling event (`last_event`) to see if it's too soon to make another change (this is called a cooldown period, defined by `full_scale_cooldown_seconds` for full scale out events or `cooldown_seconds` for normal events).
4. If there are enough jobs waiting in the queue (more than `inc_scale_jobs_waiting`), it will increase the number of workers by an `inc_num_workers` (default: (max_workers - min_workers) / 5), that's an "incremental scale-out".

5. If there aren't many jobs waiting, it looks at how busy the current workers are using the `occupancy` data:

   - If they're not very busy (below `dec_scale_occupancy_rate`, default 25%) for a while (`occupancy_rate_15s && occupancy_rate_5m && occupancy_rate_30m < inc_scale_occupancy_rate`), it will reduce the number of workers by `inc_num_workers`.
   - If they're very busy (`occupancy_rate_15s && occupancy_rate_5m && occupancy_rate_30m > dec_scale_occupancy_rate`) for a while, it will increase the number of workers by `inc_num_workers`.

The function uses occupancy rates over different time periods (`occupancy_rate_15s`, `occupancy_rate_5m`, `occupancy_rate_30m`) to make decisions, ensuring that changes are based on sustained trends rather than momentary spikes. The 3 values MUST be below or above the threshold to trigger a scale in or out.
When making scale in or scale out, it doesn't just jump to the minimum or maximum. Instead, it increases or decreases by `inc_num_workers` each time, which is calculated based on the custom parameter provided for incremental scale-in/out (default: (max_workers - min_workers) / 5).

7. Every time it decides to change the number of workers, it logs this decision as an "autoscaling event" with an explanation of why it made the change.

The goal is to have just enough workers to handle the current workload (represented by `queue_counts`) efficiently, without having too many idle workers or too few to handle the jobs.
