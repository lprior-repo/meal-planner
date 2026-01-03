---
doc_id: ops/guides/profile
chunk_id: ops/guides/profile#chunk-4
heading_path: ["Task profiling", "Views"]
chunk_type: prose
tokens: 214
summary: "Views"
---

## Views

Chrome DevTools provide 3 views for analyzing activities within a snapshot. Each view gives you a different perspective on these activities.

### Bottom up

The Bottom up view is helpful if you encounter a heavy function and want to find out where it was called from.

- The "Self Time" column represents the aggregated time spent directly in that activity, across all of its occurrences.
- The "Total Time" column represents aggregated time spent in that activity or any of its children.
- The "Function" column is the function that was executed, including source location, and any children.

### Top down

The Top down view works in a similar fashion to [Bottom up](#bottom-up), but displays functions starting from the top-level entry points. These are also known as root activities.

### Flame chart

DevTools represents main thread activity with a flame chart. The x-axis represents the recording over time. The y-axis represents the call stack. The events on top cause the events below it.
