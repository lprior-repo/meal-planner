---
doc_id: ops/windmill/14-retries
chunk_id: ops/windmill/14-retries#chunk-4
heading_path: ["Retries", "Continue on error with error as step's return"]
chunk_type: prose
tokens: 96
summary: "Continue on error with error as step's return"
---

## Continue on error with error as step's return

When enabled, the flow will continue to the next step after going through all the retries (if any) even if this step fails. This enables to process the error in a [branch one](./concept-windmill-13-flow-branches.md) for instance.

By default, each step is set to "Stop on error and propagate error up".

![Continue on error step](../assets/flows/continue_on_error1.png "Continue on error step")

![Continue on error flow](../assets/flows/continue_on_error2.png "Continue on error flow")
