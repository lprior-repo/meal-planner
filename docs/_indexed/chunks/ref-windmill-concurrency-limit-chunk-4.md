---
doc_id: ref/windmill/concurrency-limit
chunk_id: ref/windmill/concurrency-limit#chunk-4
heading_path: ["Concurrency limits", "Custom concurrency key"]
chunk_type: prose
tokens: 57
summary: "Custom concurrency key"
---

## Custom concurrency key

This parameter is optional. Concurrency keys are global, you can have them be workspace specific using the variable `$workspace`. You can also use an argument's value using `$args[name_of_arg]`.

Jobs can be filtered from the [Runs menu](./meta-windmill-index-76.md) using the Concurrency Key.
