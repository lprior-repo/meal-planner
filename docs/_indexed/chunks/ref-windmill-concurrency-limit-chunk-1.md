---
doc_id: ref/windmill/concurrency-limit
chunk_id: ref/windmill/concurrency-limit#chunk-1
heading_path: ["Concurrency limits"]
chunk_type: prose
tokens: 166
summary: "Concurrency limits"
---

# Concurrency limits

> **Context**: The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows. Its primary goal is to prev

The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows. Its primary goal is to prevent exceeding the API Limit of the targeted API, eliminating the need for complex workarounds using worker groups.

![Concurrency limit](../assets/code_editor/concurrency_limit.png)

Concurrency limit is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only.

Concurrency limit can be set from the Settings menu. When jobs reach the concurrency limit, they are automatically queued for execution at the next available optimal slot given the time window.

The Concurrency limit operates globally and across flow runs. It involves three key parameters:
