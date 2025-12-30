---
doc_id: meta/47_environment_variables/index
chunk_id: meta/47_environment_variables/index#chunk-3
heading_path: ["Environment variables", "Contextual variables"]
chunk_type: prose
tokens: 557
summary: "Contextual variables"
---

## Contextual variables

Contextual variables are environment variables automatically set by Windmill. This is how the Deno and Python clients get their implicit
credentials to interact with the platform.

| Name | Example of value | Description |
|------|------------------|-------------|
| WM_WORKSPACE | demo | Workspace id of the current script |
| WM_TOKEN | q1E2qcLyO00yxioll7oph76N9CJDqn | Token ephemeral to the current script with equal permission to the \ permission of the run (Usable as a bearer token)" |
| WM_EMAIL | demo@windmill.dev | Email of the user that executed the current script |
| WM_USERNAME | ruben | Username of the user that executed the current script |
| WM_BASE_URL | https://app.windmill.dev/ | base url of this instance |
| WM_JOB_ID | 017e0ad5-f499-73b6-5488-92a61c5196dd | Job id of the current script |
| WM_JOB_PATH | u/user/script_path | Path of the script or flow being run if any |
| WM_FLOW_JOB_ID | 017e0ad5-f499-73b6-5488-92a61c5196dd | Job id of the encapsulating flow if the job is a flow step |
| WM_ROOT_FLOW_JOB_ID | 017e0ad5-f499-73b6-5488-92a61c5196dd | Job id of the root flow if the job is a flow step |
| WM_FLOW_PATH | u/user/flow_path | Path of the encapsulating flow if the job is a flow step |
| WM_SCHEDULE_PATH | u/user/triggering_flow_path | Path of the schedule if the job of the step or encapsulating step has \ been triggered by a schedule" |
| WM_PERMISSIONED_AS | u/henri | Fully Qualified (u/g) owner name of executor of the job |
| WM_STATE_PATH | u/user/flow_path/c_henri | State resource path unique to a script and its trigger |
| WM_STATE_PATH_NEW | u/user/flow_path/c_henri | State resource path unique to a script and its trigger (legacy) |
| WM_FLOW_STEP_ID | c | The node id in a flow (like 'a', 'b', or 'f') |
| WM_OBJECT_PATH | u_user_flow_path/u_user_flow_path/c/17[...]196dd | Script or flow step execution unique path, useful for storing results in an external service |
| WM_WORKER_GROUP | default | Name of the worker group the job is running on |
| WM_RUNNABLE_ID | 1712845957812678132 | Hash of the script. Useful as cache key for cache that should be runnable specific. |
| WM_END_USER_EMAIL | demo@windmill.dev | Email of the end user that executed the current script. Only available when triggered from an app. |

### Custom contextual variables

From Variables tab, [admins](./meta-16_roles_and_permissions-index.md) can create custom contextual variables that will act as env variables for all jobs within a workspace.

We still recommend using [user-defined variables](./meta-2_variables_and_secrets-index.md#user-defined-variables) but in some cases (e.g. your imports depend on env variables), this might be a good escape hatch.

![Create Custom Contextual Variable](../2_variables_and_secrets/create_custom_contextual_variable.png)
