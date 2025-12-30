---
doc_id: ops/features/observability
chunk_id: ops/features/observability#chunk-4
heading_path: ["observability", "Visualization"]
chunk_type: prose
tokens: 107
summary: "Dagger works by building up a DAG of operations and evaluating them, often in parallel."
---
Dagger works by building up a DAG of operations and evaluating them, often in parallel. By nature, this is a difficult thing to display. It's easy to show the output of one operation at a time, but as soon as you have parallelism, you'll get jumbled output that's hard to understand.

This quickly creates the need to visualize your workflows to understand and measure what's going on. Dagger includes two features for this purpose - a Terminal UI and Dagger Cloud's Traces.
