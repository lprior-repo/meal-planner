---
doc_id: meta/10_error_handling/index
chunk_id: meta/10_error_handling/index#chunk-6
heading_path: ["Error handling", "Trigger error handlers"]
chunk_type: prose
tokens: 577
summary: "Trigger error handlers"
---

## Trigger error handlers

Each trigger type (HTTP routes, Webhooks, Kafka, SQS, WebSocket, Postgres, NATS, MQTT, GCP, Email) can have its own local error handler configured. If a trigger-specific error handler is defined, it will be used for that trigger instead of the workspace error handler. **Trigger error handlers only work for scripts** (not flows).


### Configuring trigger error handlers

When creating or editing a trigger, you can configure the same error handler options as workspace error handlers:
- **Custom script or flow**: Execute your own custom error handling logic
- **Slack integration**: Send error notifications to Slack channels
- **Microsoft Teams integration**: Send error notifications to Teams channels  
- **Email notifications**: Send error alerts via email to specified recipients

For each trigger error handler, you can also specify:
- **Error handler arguments**: Additional arguments for the custom error handler (only configurable if the chosen script or flow has parameters)
- **Retry configuration**: Number of retries and retry strategy before invoking the error handler

### Parameters passed to trigger error handlers

Trigger error handlers receive the following base parameters:
- `error`: The error details from the failed job
- `path`: The path of the script or flow that errored
- `is_flow`: Whether the error comes from a flow (always `false` for triggers)
- `trigger_path`: The trigger path in format `<trigger_kind>/<trigger_path>` (e.g., `http_trigger/my-webhook`, `kafka_trigger/my-topic`)
- `workspace_id`: The workspace id where the error occurred
- `email`: The email of the user who triggered the execution
- `job_id`: The job id of the failed execution
- `started_at`: When the failed job started

If using a custom trigger error handler, additional custom arguments can be passed via the error handler configuration.

### Example trigger error handler

Here's a template for a trigger error handler:

```ts
// Trigger error handler template
export async function main(
	error: object, // The error details from the failed job
	path: string, // The path of the script or flow that errored
	is_flow: boolean, // Whether the error comes from a flow
	trigger_path: string, // The trigger path in format <trigger_kind>/<trigger_path>
	workspace_id: string, // The workspace id where the error occurred
	email: string, // The email of the user who triggered the execution
	job_id: string, // The job id of the failed execution
	started_at: string // When the failed job started
) {
	const run_type = is_flow ? 'flow' : 'script';
	console.log(
		`Trigger error: ${run_type} ${path} run by ${email} failed in workspace ${workspace_id}`
	);
	console.log(`Trigger: ${trigger_path}, Job ID: ${job_id}, Started: ${started_at}`);
	console.log('Error details:', error);
	
	// Add custom logic for trigger-specific error handling
	
	return error;
}
```

This allows you to customize error handling behavior per trigger while maintaining consistent fallback to workspace-level error handling.
