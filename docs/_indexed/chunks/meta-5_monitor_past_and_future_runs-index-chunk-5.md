---
doc_id: meta/5_monitor_past_and_future_runs/index
chunk_id: meta/5_monitor_past_and_future_runs/index#chunk-5
heading_path: ["Jobs runs", "Jobs labels"]
chunk_type: prose
tokens: 72
summary: "Jobs labels"
---

## Jobs labels

Labels allow to add static or dynamic tags to [jobs](./meta-20_jobs-index.md) with property "wm_labels" followed by an array of strings.

```js
export async function main() {
  return {
    "wm_labels": ["showcase_labels", "another_label"]
  }
}
```

Jobs can be filtered by labels in the Runs menu to monitor specific groups of jobs.

![Run labels](./runs_labels.png 'Run labels')
