---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-32
heading_path: ["Windmill Deployment Guide", "Get secret (automatically decrypted)"]
chunk_type: code
tokens: 42
summary: "Get secret (automatically decrypted)"
---

## Get secret (automatically decrypted)
db_password = wmill.get_variable("f/meal-planner/vars/db_password")
```text

**Rust:**
```rust
// Pass as typed resource parameter
fn main(postgres: Postgresql) -> Result<(), Error> {
    let conn = postgres.connect()?;
    // ...
}
```yaml

---
