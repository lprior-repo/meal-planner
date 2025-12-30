---
doc_id: meta/21_concurrency_limits/index
chunk_id: meta/21_concurrency_limits/index#chunk-5
heading_path: ["Concurrency limits", "Concurrency limit in Script & Flows"]
chunk_type: prose
tokens: 210
summary: "Concurrency limit in Script & Flows"
---

## Concurrency limit in Script & Flows

### Concurrency limit of a script

[Concurrency limit of a script](./ref-script_editor-concurrency-limit.md) can be set from the [Settings](./tutorial-script_editor-settings.md) menu. Pick "Runtime" and then "Concurrency limits" and define a time window, max number of executions of the script within that time window and optionally a custom concurrency key.

![Concurrency limit](../../assets/code_editor/concurrency_limit.png)

### Concurrency limit of a flow

From the Flow Settings Advanced menu, pick "Concurrency limits" and define a time window, a max number of executions of the flow within that time window and optionally a custom concurrency key.

![Concurrency limit of flow](../../assets/flows/concurrency_flow.png "Concurrency limit of flow")

### Concurrency limit of scripts within flow

The Concurrency limit operates globally and across flow runs. It involves two key parameters: "Maximum number of runs" and the "Per time window (seconds)."

Concurrency limit can be set for each step of a flow in the `Advanced` menu, on tab "Runtime" - "Concurrency".

![Concurrency limit Scripts within Flow](../../assets/code_editor/concurrency_limit_flow.png "Concurrency limit Scripts within Flow")
