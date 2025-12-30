---
doc_id: meta/10_error_handling/index
chunk_id: meta/10_error_handling/index#chunk-5
heading_path: ["Error handling", "Workspace error handler"]
chunk_type: prose
tokens: 824
summary: "Workspace error handler"
---

## Workspace error handler

Configure automatic error handling for workspace-level errors (e.g. scheduled job failures, trigger failures without their own error handlers). Choose from built-in notification options or define custom error handling logic.

Configure workspace error handlers from **Workspace Settings > Error Handler** tab. The system supports four types of error handlers:

### Slack error handler

Send error notifications to Slack channels. Requires workspace to be [connected to Slack](../../integrations/slack.mdx).

**Configuration:**
- Enable/disable Slack error handler toggle
- Specify Slack channel (without # prefix)
- Available on [Cloud plans and Self-Hosted & Enterprise Edition](/pricing)

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/6QPONDONd5k?vq=1080p"
	title="Workspace Error handler on Slack"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

### Microsoft Teams error handler

Send error notifications to Microsoft Teams channels. Requires workspace to be [connected to Teams](../../integrations/teams.mdx).

**Configuration:**
- Enable/disable Teams error handler toggle
- Select from available Teams channels dropdown
- Available on [Cloud plans and Self-Hosted & Enterprise Edition](/pricing)

### Email error handler

Send error notifications via email to specified recipients.

**Configuration:**
- Specify email addresses to receive error notifications
- Only available on Self-Hosted instances (not available on Cloud)
- Requires SMTP configuration

### Custom error handler

Execute custom scripts or flows as error handlers for advanced error handling logic.

**Configuration:**
- Script or flow selection via script picker
- Additional arguments can be configured if the chosen script or flow has parameters
- Template creation options

**Parameters passed to custom error handlers:**

All custom workspace error handlers receive the following base parameters:

- `workspace_id`: The workspace id where the error occurred
- `job_id`: The job id of the failed execution
- `path`: The path of the script or flow that errored
- `is_flow`: Whether the error comes from a flow
- `started_at`: When the failed job started
- `email`: The email of the user who ran the script or flow that errored
- `schedule_path`: The schedule path (only present if the error comes from a scheduled job)

**Custom error handler template:**

```ts
// Custom workspace error handler template

export async function main(
	workspace_id: string, // The workspace id where the error occurred
	job_id: string, // The job id of the failed execution
	path: string, // The path of the script or flow that errored
	is_flow: boolean, // Whether the error comes from a flow
	started_at: string, // When the failed job started
	email: string, // The email of the user who ran the script or flow that errored
	schedule_path?: string // The schedule path (only present if error from scheduled job)
) {
	const run_type = is_flow ? 'flow' : 'script';
	console.log(
		`Workspace error: ${run_type} ${path} run by ${email} failed in workspace ${workspace_id}`
	);
	console.log(`Job ${job_id} started at ${started_at}`);
	
	if (schedule_path) {
		console.log(`Scheduled job from: ${schedule_path}`);
	}
	
	// Add your custom error handling logic here
	// Examples: send to external monitoring, create incidents, etc.
	
	// Note: The actual error details are available through the job context
	// and can be retrieved using Windmill's job APIs if needed
	
	return { handled: true, workspace_id, job_id };
}
```

---

From the workspace settings, go to the "Error handler" tab and select your preferred error handler type.

![Workspace Error handler](./workspace_error_handler.png 'Workspace Error handler')

### Error handler execution

- Error handlers are executed by the automatically created group `g/error_handler`
- If your error handler requires variables or resources, add them to the `g/error_handler` group
- Error handlers run as different users depending on type:
  - Custom, Slack, Teams error handlers: `error_handler@windmill.dev`
  - Email error handlers: `email_error_handler@windmill.dev`
- The system prevents infinite loops by not triggering error handlers for error handler jobs themselves

### Advanced configuration

**Skip error handler for cancelled jobs:**
Enable the "Do not run error handler for canceled jobs" option to prevent error handlers from triggering when jobs are manually cancelled.
