---
doc_id: concept/connect/connection
chunk_id: concept/connect/connection#chunk-4
heading_path: ["connection", "Example"]
chunk_type: code
tokens: 31
summary: "```typescript
await connection(
  async () => {
    await dag
      ."
---
```typescript
await connection(
  async () => {
    await dag
      .container()
      .from("alpine")
      .withExec(["apk", "add", "curl"])
      .withExec(["curl", "https://dagger.io/"])
      .sync()
  },
  { LogOutput: process.stderr }
)
```
