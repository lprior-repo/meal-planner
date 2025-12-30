---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-2
heading_path: ["Workers and worker groups", "Assign custom worker groups"]
chunk_type: code
tokens: 1524
summary: "Assign custom worker groups"
---

## Assign custom worker groups

Assign custom worker groups to scripts and flows in Windmill for efficient execution on different machines with varying specifications.

This feature is useful if you want to run some scripts on a GPU machine, or if you want to run some scripts on high-memory machine.

### How to have a worker join a worker group

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/LbjgWKFQWJc"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

Create a worker group in your [docker-compose.yml](https://github.com/windmill-labs/windmill/blob/main/docker-compose.yml) and simply pass the worker group as the env variable `WORKER_GROUP=<name_of_worker_group>` for it to automatically join its corresponding worker group.

Windmill's responsibility is not to spawn the worker itself but to play well with existing service orchestrator such as Kubernetes, ECS, Nomad or Docker Compose, and any IaC. In those, you define the number of replicas (which can be auto-scaled up or down), the resource to allocate to those workers and the `WORKER_GROUP` passed as env.

Upon start, those workers will automatically join their worker group and fetch their configurations (including init scripts). They will also listen for changes on the worker group configuration for hot reloading.

Here is an example of a worker group specification in [docker-compose](https://github.com/windmill-labs/windmill/blob/main/docker-compose.yml):

```yaml
windmill_worker_highmem:
  image: ghcr.io/windmill-labs/windmill-ee:main
  pull_policy: always
  deploy:
    replicas: 2
    resources:
      limits:
        cpus: '1'
        memory: 4096M
  restart: unless-stopped
  environment:
    - DATABASE_URL=${DATABASE_URL}
    - MODE=worker
    - WORKER_GROUP=highmem
```

Assign replicas, resource constraints, and that's it, the worker will automatically join the worker group on start and be displayed on the Workers page in the Windmill app!

Worker only require a database URL and can thus be spawned in separate VPCs if needed (as long as there is a tunnel to the database). There is also an agent mode for situations where workers are running in an untrusted environment.

### Set tags to assign specific queues

You can assign groups to flows and flow steps to be executed on specific queues. The name of those queues are called tags. Worker groups listen to those tags.

<img
	src={require('./tags_and_queues.png').default}
	alt="Tags and Queues infographics"
	title="Tags and Queues infographics"
	width="75%"
/>

<br />

There are 2 worker groups by default: [default](#default-worker-group) and [native](#native-worker-group).

#### Default worker group

The tags of _default_ worker group are:

- `deno`: The default worker group for [Deno scripts](./meta-1_typescript_quickstart-index.md).
- `python3`: The default worker group for [Python scripts](./meta-2_python_quickstart-index.md).
- `go`: The default worker group for [Go scripts](./meta-3_go_quickstart-index.md).
- `bash`: The default worker group for [Bash scripts](./meta-4_bash_quickstart-index.md).
- `powershell`: The default worker group for [Powershell scripts](./meta-4_bash_quickstart-index.md).
- `dependency`: Where [dependency](./meta-6_imports-index.md) jobs are run.
- `flow`: The default worker group for executing [flows](./tutorial-flows-1-flow-editor.md) modules outside of the script steps.
- `hub`: The default worker group for executing [Hub](https://hub.windmill.dev/) scripts.
- `bun`: The default worker group for [Bun](./meta-1_typescript_quickstart-index.md) scripts.
- `php`: The default worker group for [PHP](./meta-8_php_quickstart-index.md) scripts.
- `rust`: The default worker group for [Rust](./meta-9_rust_quickstart-index.md) scripts.
- `ansible`: The default worker group for [Ansible](./meta-10_ansible_quickstart-index.md) scripts.
- `csharp`: The default worker group for [C#](./meta-11_csharp_quickstart-index.md) scripts.
- `java`: The default worker group for [Java](./meta-13_java_quickstart-index.md) scripts.
- `nu`: The default worker group for [Nu scripts](./meta-4_bash_quickstart-index.md#nu).
- `ruby`: The default worker group for [Ruby](./meta-14_ruby_quickstart-index.md) scripts.
- `other`: Everything else (other than the [native](#native-worker-group) tags).

#### Native worker group

Native workers are workers within the _native_ worker group.
This group is pre-configured to listen to native jobs tags. Those jobs are executed under a special mode with subworkers for increased throughput.

You can set the number of native workers to 0. Just make sure that you assign the native tags to other worker groups. Otherwise, the jobs with those tags will never be executed.

The tags of _native_ worker group are:

- `nativets`: The default worker group for [Rest](./meta-6_rest_grapqhql_quickstart-index.md) scripts.
- `postgresql`: The default worker group for [PostgreSQL](./meta-5_sql_quickstart-index.md) scripts.
- `mysql`: The default worker group for [MySQL](./meta-5_sql_quickstart-index.md) scripts.
- `mssql`: The default worker group for [MS SQL](./meta-5_sql_quickstart-index.md) scripts.
- `graphql`: The default worker group for [Graphql](./meta-5_sql_quickstart-index.md) scripts.
- `snowflake`: The default worker group for [Snowflake](./meta-5_sql_quickstart-index.md) scripts.
- `bigquery`: The default worker group for [Bigquery](./meta-5_sql_quickstart-index.md) scripts.

<br />
<br />

If you assign custom worker groups to all your workers, make sure that they cover all tags above, otherwise those jobs will never be executed.

Button `Reset to native tags` will reset the tags of [_native_](#native-worker-group) worker group to a given worker group.

Button `Reset to all tags` will reset the tags of [_default_](#default-worker-group) and [_native_](#native-worker-group) worker group to a given worker group.

Button `Reset to all tags minus native ones` will reset the tags of [_default_](#default-worker-group) worker group to a given worker group.

![Reset to tags buttons](./reset_tags.png 'Reset to tags buttons')

To make custom tags available from the UI, go to the dedicated "Workers" tab on the workspace and click on the "Assignable Tags" button:

![Worker Group Assignable Tags](./worker_group_ui_2.png.webp)

#### Restrict tags to specific workspaces

It is possible to restrict some tags to specific workspace using the following syntax:

```
gpu(workspace+workspace2)
```

Only 'workspace' and 'workspace2' will be able to use the `gpu` tags.

Jobs within a same job queue can be given a [priority](./meta-20_jobs-index.md#high-priority-jobs) between 1 and 100. Jobs with a higher priority value will be given precedence over jobs with a lower priority value in the job queue.

### How to assign worker tags to a worker group

Use the edit/create config next to the worker group name in Windmill UI:

![Worker group config](../../../static/images/worker_group_config.png 'Worker group config')

**Note**: The worker group management UI is a [Cloud plans & Self-Hosted Enterprise Edition](/pricing) feature. It is still possible to use worker groups with the community edition by passing to each worker the env variable `WORKER_TAGS`:

```
WORKER_TAGS=tag1,tag2
```

### How to assign a custom worker group to a script or flow

For scripts deployed on the script editor, select the corresponding worker group tag in the settings section.

![Worker group tag](./select_script_builder.png.webp)

For scripts inlined in the flow editor, select it in the module header:

![Worker group tag](./select_flow.png.webp)

If no worker group is assigned to a script, it will be assigned the default worker group for its language.

You can assign a worker group to an entire flow in the flow's settings:

![Flow's Worker Group](flow_wg.png.webp)

### Dynamic tag

If a workspace tag contains the substring `$workspace`, it will be replaced by the workspace id corresponding to the job. This is especially useful to have the same script deployed to different workspace and have them run on different workers.

With the following assignable tag:

```
normal-$workspace
```

the workspaces, `dev`, `staging`, `prod` and the worker groups: `normal-dev`, `normal-staging`, `normal-prod`. The same script wih the tag `normal-$workspace` will run on the corresponding worker group depending on the workspace it is deployed to. This enable to share the same control plane but use workers with different network restrictions for tighter security.

Last, if the tags contain `$args[argName]` (e.g: `foo-$args[foobar])` then the tag will be replaced by the string value at the arg key `argName` and thus can be fully dynamic.

See [Deploy to staging prod](./meta-12_staging_prod-index.md) to see a full UI flow to deploy to staging and prod.
