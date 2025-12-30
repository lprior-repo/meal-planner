---
doc_id: meta/10_error_handling/index
chunk_id: meta/10_error_handling/index#chunk-7
heading_path: ["Error handling", "Instance error handler"]
chunk_type: prose
tokens: 292
summary: "Instance error handler"
---

## Instance error handler

You can define a script to be executed automatically in case of error in your instance (all workspaces).

This Superadmin Error handler is defined by setting the path to the script to be executed as an env variable to all servers using: `GLOBAL_ERROR_HANDLER_PATH_IN_ADMINS_WORKSPACE`.

The following args will be passed to the error handler:

- path: The path of the script or flow that errored.
- email: The email of the user who ran the script or flow that errored.
- error: The error details.
- job_id: The job id.
- is_flow: Whether the error comes from a flow.
- workspace_id: The workspace id of the failed script or flow.

Here is a template for your workspace error handler:

```ts
// Global / workspace error handler template

export async function main(
	path: string, // The path of the script or flow that errored
	email: string, // The email of the user who ran the script or flow that errored
	error: object, // The error details
	job_id: string, // The job id
	is_flow: boolean, // Whether the error comes from a flow
	workspace_id: string // The workspace id of the failed script or flow
) {
	const run_type = is_flow ? 'flow' : 'script';
	console.log(
		`An error occurred with ${run_type} ${path} run by ${email} in workspace ${workspace_id}`
	);
	console.log(error);
	return error;
}
```
