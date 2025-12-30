---
doc_id: meta/42_autoscaling/index
chunk_id: meta/42_autoscaling/index#chunk-2
heading_path: ["Autoscaling", "Autoscaling configuration"]
chunk_type: prose
tokens: 351
summary: "Autoscaling configuration"
---

## Autoscaling configuration

You configure a minimum and maximum number of [workers](./meta-9_worker_groups-index.md). The autoscaler will adjust the number of workers between the minimum and maximum based on the workload by calling a script which call your underlying infra orchestrator such as Kubernetes, ECS or Nomad. Coming soon, those will be hanlded natively by Windmill without the need for running a job.

Autoscaling is configured in each [worker group](/core_concepts/9_worker_groups/index.mdx) config under "Autoscaling". It takes the following configuration:

![Autoscaling](./config.png)

### Rules

| Parameter        | Description                                         |
| ---------------- | --------------------------------------------------- |
| Enabled          | Whether autoscaling is enabled for the worker group |
| Min # of Workers | The minimum number of workers to scale down to      |
| Max # of Workers | The maximum number of workers to scale up to        |

### Integration

| Integration Type | Description                                             |
| ---------------- | ------------------------------------------------------- |
| Dry run          | Test autoscaling behavior without making actual changes |
| Custom script    | Use your own script to handle scaling workers           |
| ECS              | Native ECS integration (coming soon)                    |
| Nomad            | Native Nomad integration (coming soon)                  |
| Kubernetes       | Native Kubernetes integration                            |

### Custom script

When using a custom script, you'll need to provide a path to script in the [admins workspace](./meta-18_instance_settings-index.md#admins-workspace), and optionally a custom [tag](./meta-9_worker_groups-index.md#set-tags-to-assign-specific-queues) for executing the script.

The arguments that are passed to the script are: worker group, desired workers, reason, and event type. For instance, if you are using Kubernetes, you can use the following script:

```bash
worker_group="$1"
desired_workers="$2"
reason="$3"
event_type="$4"
namespace="mynamespace"

echo "Applying $event_type of $desired_workers to $worker_group bc $reason"
