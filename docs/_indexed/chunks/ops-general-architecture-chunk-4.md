---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-4
heading_path: ["Architecture", "Binary Contract"]
chunk_type: prose
tokens: 93
summary: "Binary Contract"
---

## Binary Contract

Every binary follows this pattern:

1. **Read JSON from stdin**
2. **Do one thing** (~50 lines max)
3. **Write JSON to stdout** or error JSON to stdout with exit code 1

### Example

```rust
fn main() {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input).unwrap();
    
    let config: MyConfig = serde_json::from_str(&input).unwrap();
    match do_work(&config) {
        Ok(output) => println!("{}", serde_json::to_string(&output).unwrap()),
        Err(e) => {
            println!(r#"{{"success": false, "error": "{}"}}"#, e);
            std::process::exit(1);
        }
    }
}
```
