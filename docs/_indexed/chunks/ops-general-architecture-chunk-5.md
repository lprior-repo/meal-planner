---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-5
heading_path: ["Meal Planner Architecture", "Binary Contract"]
chunk_type: prose
tokens: 201
summary: "Binary Contract"
---

## Binary Contract

Every binary follows the same contract:

### Input
- Reads JSON from **stdin**
- Schema defined by a `*Input` or `*Config` struct

### Output
- Writes JSON to **stdout** on success
- Schema defined by a `*Output` or `*Result` struct

### Errors
- Writes JSON error to **stdout** (not stderr) with exit code 1
- Format: `{"success": false, "error": "message"}`

### Example Binary (~50 lines max)

```rust
//! tandoor/bin/test_connection.rs
//! Does one thing: tests Tandoor API authentication

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use std::io::{self, Read};

fn main() {
    let result = run();
    match result {
        Ok(output) => {
            println!("{}", serde_json::to_string(&output).unwrap());
        }
        Err(e) => {
            println!(r#"{{"success": false, "error": "{}"}}"#, e);
            std::process::exit(1);
        }
    }
}

fn run() -> anyhow::Result<serde_json::Value> {
    // 1. Read input
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;
    let config: TandoorConfig = serde_json::from_str(&input)?;

    // 2. Do one thing
    let client = TandoorClient::new(&config)?;
    let result = client.test_connection()?;

    // 3. Return output
    Ok(serde_json::to_value(result)?)
}
```text
