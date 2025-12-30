---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-50
heading_path: ["Windmill Deployment Guide", "2. Configure error handler"]
chunk_type: code
tokens: 122
summary: "2. Configure error handler"
---

## 2. Configure error handler
wmill workspace update --error-handler-slack-channel "meal-planner-alerts"
```

### Custom Error Handler Script

```typescript
// f/meal-planner/handlers/notifications/workspace_error_handler.ts
export async function main(
    workspace_id: string,
    job_id: string,
    path: string,
    is_flow: boolean,
    started_at: string,
    email: string,
    schedule_path?: string
) {
    const run_type = is_flow ? 'flow' : 'script';

    // Send to monitoring system
    await fetch('https://monitoring.example.com/api/alerts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            severity: 'error',
            source: 'windmill',
            title: `${run_type} ${path} failed`,
            workspace: workspace_id,
            job_id,
            started_at,
            triggered_by: email,
            schedule: schedule_path
        })
    });

    return { handled: true };
}
```

### Schedule Error Handlers

```bash
