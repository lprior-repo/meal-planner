---
doc_id: tutorial/extending/function-caching
chunk_id: tutorial/extending/function-caching#chunk-4
heading_path: ["function-caching", "Backwards compatibility"]
chunk_type: mixed
tokens: 229
summary: "> **Note:** This section is relevant to users of Dagger prior to engine version v0."
---
> **Note:** This section is relevant to users of Dagger prior to engine version v0.19.4 only.

Prior to engine version v0.19.4, function calls all implicitly had the behavior of the "session" cache policy, with no configurability available.

Users of modules that were created prior to v0.19.4 will initially retain that default of "session" caching when they upgrade. After running `dagger develop`, a new setting in dagger.json will appear:

```json
{
  "disableDefaultFunctionCaching": true
}
```

Once the author has annotated functions with the desired cache configuration (or has determined that the default cache policy is appropriate for each function), they can delete that line from `dagger.json` to opt-in to the new function caching features.

The reason for this is that some functions may require a specific TTL, "session" or "never" caching in order to behave as expected. For example, if a function pulls data from an external network service, it may not be desireable for it to have the default TTL of 7 days in the case where that data changes more frequently than once a week.
