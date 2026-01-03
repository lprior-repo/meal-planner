---
doc_id: ops/windmill/rust-sdk-winmill-patterns
chunk_id: ops/windmill/rust-sdk-winmill-patterns#chunk-7
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents", "Calling other scripts and managing jobs"]
chunk_type: code
tokens: 179
summary: "Calling other scripts and managing jobs"
---

## Calling other scripts and managing jobs

### Asynchronous execution (fire and forget)

```rust
use serde_json::json;

let job_id = wm.run_script_async(
    "u/user/my_script",     // script path
    false,                   // by_hash: false = use path
    json!({"param": "value"}),
    Some(10)                 // schedule delay in seconds (optional)
).await?;
println!("Started job: {}", job_id);
```text

### Synchronous execution (wait for result)

```rust
let result = wm.run_script_sync(
    "f/production/process_data",
    false,                          // by_hash
    json!({"input": data}),
    None,                           // schedule_delay
    Some(120),                      // timeout in seconds
    true,                           // verbose logging
    true                            // assert_result_not_none
).await?;
```text

### Job monitoring

```rust
// Wait for job completion
let result = wm.wait_job(&job_id, Some(60), true, true).await?;

// Check job status
let status = wm.get_job_status(&job_id).await?; // Running | Waiting | Completed

// Get result directly
let result = wm.get_result(&job_id).await?;
```text

### Progress tracking

```rust
// Set progress (0-100)
wm.set_progress(50, None).await?;

// Get progress
let progress = wm.get_progress(Some(job_id.to_string())).await?;
```yaml

---
