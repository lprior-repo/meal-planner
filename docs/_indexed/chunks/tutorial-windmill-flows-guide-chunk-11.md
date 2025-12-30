---
doc_id: tutorial/windmill/flows-guide
chunk_id: tutorial/windmill/flows-guide#chunk-11
heading_path: ["Windmill Flows Guide", "Approval/Prompt Flows"]
chunk_type: code
tokens: 223
summary: "Approval/Prompt Flows"
---

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
```javascript

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
```text
