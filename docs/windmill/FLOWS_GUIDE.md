# Windmill Flows Guide

This guide covers creating and managing Windmill flows in this repository.

## Quick Reference

```bash
# Push flow to Windmill (use directory, not file)
wmill flow push f/fatsecret/oauth_setup.flow f/fatsecret/oauth_setup

# Run flow
wmill flow run f/fatsecret/oauth_setup -d '{}'

# Sync all (scripts + flows)
wmill sync push --yes
```

## Flow File Structure

```
windmill/f/<domain>/<flow_name>.flow/
└── flow.yaml    # Flow definition
```

**Important**: When pushing flows, use the `.flow` directory path, NOT the `flow.yaml` file:
```bash
# Correct
wmill flow push f/fatsecret/oauth_setup.flow f/fatsecret/oauth_setup

# Wrong - causes "ENOTDIR" error
wmill flow push f/fatsecret/oauth_setup.flow/flow.yaml f/fatsecret/oauth_setup
```

## Flow YAML Structure

```yaml
summary: Flow Name
description: What it does
value:
  modules:
    - id: a
      summary: Step description
      value:
        type: script
        path: f/domain/script_name
        input_transforms:
          param:
            type: static
            value: '$res:u/admin/resource_name'
  same_worker: false
schema:
  $schema: 'https://json-schema.org/draft/2020-12/schema'
  type: object
  properties: {}
  required: []
```

## Input Transforms

### Static Value
```yaml
input_transforms:
  param:
    type: static
    value: 'hardcoded_value'
```

### Resource Reference
```yaml
input_transforms:
  config:
    type: static
    value: '$res:u/admin/my_resource'
```

### From Previous Step
```yaml
input_transforms:
  data:
    type: javascript
    expr: results.a.some_field
```

### From Resume Payload (approval flows)
```yaml
input_transforms:
  verifier:
    type: javascript
    expr: resume.verifier
```

## Approval/Prompt Flows

For flows that need user input mid-execution (like OAuth):

### Step with Suspend + Resume Form

```yaml
- id: b
  summary: Enter user input
  suspend:
    required_events: 1
    timeout: 900  # seconds
    resume_form:
      schema:
        type: object
        properties:
          verifier:
            type: string
            title: "Verifier Code"
            description: "Paste the code here"
        required:
          - verifier
  value:
    type: rawscript
    language: bun
    content: |
      import * as wmill from "windmill-client"
      
      export async function main(auth_url: string) {
        const urls = await wmill.getResumeUrls("user");
        return {
          resume: urls.resume,
          cancel: urls.cancel,
          description: {
            render_all: [
              { markdown: `**[Click here](${auth_url})**` }
            ]
          }
        };
      }
    input_transforms:
      auth_url:
        type: javascript
        expr: results.a.auth_url
```

### Why TypeScript for Prompts?

Windmill requires `wmill.getResumeUrls()` to show inline prompt UI. This function only exists in:
- TypeScript (Bun/Deno): `wmill.getResumeUrls()`
- Python: `wmill.get_resume_urls()`

**Not available in Rust SDK.**

Keep the TypeScript minimal - just get URLs and format description. All business logic stays in Rust.

### Accessing Resume Data

In the step after suspend, access user input via `resume`:
```yaml
input_transforms:
  user_input:
    type: javascript
    expr: resume.field_name
```

## OAuth Flow Pattern

See `windmill/f/fatsecret/oauth_setup.flow/flow.yaml` for complete example.

**Pattern:**
1. **Step A (Rust)**: Get auth URL, store pending token
2. **Step B (TypeScript)**: Show prompt with link + input field
3. **Step C (Rust)**: Exchange verifier for access token
4. **Step D (Rust)**: Verify connection works

**Token Storage**: Use Windmill internal resources (`wmill.set_resource()`)
- Pending tokens: `u/admin/<service>_pending_oauth` (type: `state`)
- Access tokens: `u/admin/<service>_oauth_credentials` (type: `state`)

## Pushing Flows via API

If CLI has issues, use the API directly:

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "http://localhost/api/w/meal-planner/flows/create" \
  -d @flow_payload.json
```

## Common Issues

### "ENOTDIR" on flow push
Use directory path, not file path. See Quick Reference above.

### Flow not syncing with `wmill sync push`
Flows may not auto-sync. Use `wmill flow push` explicitly.

### Suspended flow blocking CLI
Run flows via API with async, or use Windmill UI. CLI waits forever on suspended flows.

```bash
# Async via API
curl -X POST -H "Authorization: Bearer $TOKEN" \
  "http://localhost/api/w/meal-planner/jobs/run/f/f/fatsecret/oauth_setup" \
  -d '{}'
```

### Cancel suspended flow
```bash
curl -X POST -H "Authorization: Bearer $TOKEN" \
  "http://localhost/api/w/meal-planner/jobs_u/cancel/<job_id>" \
  -d '{"reason": "Cancelled"}'
```

## Related Documentation

- [Windmill Development Guide](./DEVELOPMENT_GUIDE.md) - Scripts, resources, CLI
- [Flow Approval Docs](./flows/11_flow_approval.mdx) - Suspend/resume details
- [Webhooks](./core_concepts/4_webhooks/index.mdx) - Triggering flows externally
