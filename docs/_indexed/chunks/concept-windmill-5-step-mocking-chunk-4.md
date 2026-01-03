---
doc_id: concept/windmill/5-step-mocking
chunk_id: concept/windmill/5-step-mocking#chunk-4
heading_path: ["Step mocking / Pin result", "Features"]
chunk_type: prose
tokens: 167
summary: "Features"
---

## Features

### History exploration
- Use the history button to explore previous step results.
- View and select from past successful runs.
- Imported flows and scripts retain their run history.

### Pinning results

Pin any successful run result to reuse it.

![Pin result](../assets/flows/pin_result.png "Pin result")

You can edit pinned data by overriding pin functionality (you can still test the step).

  ![Override pin](../assets/flows/override_pin.png "Override pin")

### Mocking

You can also edit the mocked value directly.

  ![Direct editing](../assets/flows/direct_editing.png "Direct editing")
  
[Test step](./ops-windmill-18-test-flows.md) functionality remains available even with pinned results.

:::tip Cache for steps

The [cache for steps feature](./tutorial-windmill-4-cache.md) allows you to cache the results of a step for a specified number of seconds, thereby reducing the need for redundant computations when re-running the same step with identical input.

:::
