# Windmill Skill Guide

## Overview

Windmill is a workflow automation platform. This project uses Windmill for:
- Scheduled jobs (meal planning, nutrition tracking)
- Multi-step workflows with error handling
- Integration with external APIs (Tandoor, FatSecret)

---

## Flow Features (Quick Reference)

### Retries
```yaml
# In flow step settings
retries:
  constant:
    attempts: 5
    seconds: 60
  exponential:
    attempts: 3
    base: 2
    multiplier: 1
```
- Constant: fixed delay between attempts
- Exponential: `delay = multiplier * base ^ attempt`
- If both defined, constant tries first

### Error Handler
- Special step executed when flow errors after all retries exhausted
- Receives error details in `error` field
- Use for: notifications (Slack/Discord), fallback actions, logging

### Branches
```javascript
// Branch One: first true branch executes
results.status === 'success'  // predicate expression

// Branch All: all branches execute in parallel
```

### For Loops
```javascript
// Iterator expression
["item1", "item2", "item3"]
// Or from previous result
results.a.items
```
Options:
- `skip_failure`: continue on item error
- `parallel`: run iterations concurrently
- `parallelism`: limit concurrent iterations
- `squash`: same worker, no cold starts (TypeScript/Python only)

### Early Stop / Break
- Stops flow based on predicate expression
- Within for-loop: breaks loop only
- At flow level: prevents execution based on inputs

### Sleep / Delays
- Passive suspension (no resource consumption)
- Duration in seconds (supports hours/days/months)
- Use for: rate limiting, scheduled delays, cooling periods

### Caching
```yaml
cache:
  enabled: true
  ttl_seconds: 3600
```
- Caches results for identical inputs
- Applies to: scripts, flows, flow steps, app inline scripts

### Concurrency Limits
```yaml
concurrency:
  max_executions: 10
  time_window_seconds: 60
  key: "$workspace"  # or "$args[api_key]"
```
- Prevents exceeding API rate limits
- Jobs queued when limit reached

### Job Debouncing
```yaml
debouncing:
  delay_seconds: 5
  key: "$args[user_id]"
```
- Cancels pending duplicate jobs
- Only newest job executes

---

## CLI Commands

### Installation
```bash
npm install -g windmill-cli
wmill --version
wmill upgrade
```

### Workspace
```bash
wmill workspace                    # List workspaces
wmill workspace add <name> <id> <remote>
wmill workspace switch <name>
wmill workspace whoami
```

### Scripts
```bash
wmill script                       # List all
wmill script push <path>           # Push to remote
wmill script bootstrap <path> <lang>  # Create new
wmill script run <path> -d '{"arg": "value"}'
wmill script generate-metadata     # Regenerate schema/locks
```

Languages: `deno`, `python3`, `bun`, `bash`, `go`, `nativets`, `postgresql`, `mysql`, `bigquery`, `snowflake`, `graphql`, `powershell`, `rust`

### Flows
```bash
wmill flow                         # List all
wmill flow push <file> <path>      # Push YAML
wmill flow bootstrap <path>        # Create new
wmill flow run <path> -d '{...}'
wmill flow generate-locks          # Update inline script locks
```

### Resources & Variables
```bash
wmill resource                     # List resources
wmill resource push <file> <path>

wmill variable                     # List variables
wmill add <path> --value=<val> --secret
```

---

## Python SDK

```python
import wmill

# Resources & Variables
db = wmill.get_resource('u/user/db_config')
key = wmill.get_variable('u/user/api_key')
wmill.set_variable('u/user/counter', '42')

# Run scripts/flows
result = wmill.run_script_by_path('f/scripts/calc', args={'x': 10})
job_id = wmill.run_script_by_path_async('f/scripts/long_task', args={})
result = wmill.get_result(job_id)

# State management
state = wmill.get_state()
wmill.set_state({'last_run': '2025-01-01'})

# S3 integration
from wmill import S3Object
s3_obj = S3Object(s3='/path/to/file.txt')
content = wmill.load_s3_file(s3_obj)
wmill.write_s3_file(s3_obj, b'data')
```

**Notes:**
- Uses `WM_TOKEN` env var automatically inside Windmill
- Not thread-safe: create separate `wmill.Windmill()` instance per thread

---

## Graphiti Knowledge Search

Before implementing Windmill features, search the knowledge graph:

```python
# Search for specific topics
graphiti_search_memory_facts(
    query="windmill retries exponential backoff",
    group_ids=["windmill-docs"]
)

# List all indexed knowledge
graphiti_get_episodes(
    group_ids=["windmill-docs"],
    max_episodes=30
)
```

---

## Best Practices

1. **Error Handling**: Always define error handlers for critical flows
2. **Retries**: Use exponential backoff for external API calls
3. **Caching**: Cache expensive computations and API responses
4. **Concurrency**: Set limits when calling rate-limited APIs
5. **Debouncing**: Use for user-triggered actions to prevent duplicates
6. **State**: Use `get_state()`/`set_state()` for persistent flow state
