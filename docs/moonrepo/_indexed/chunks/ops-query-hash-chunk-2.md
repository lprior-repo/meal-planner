---
doc_id: ops/query/hash
chunk_id: ops/query/hash#chunk-2
heading_path: ["query hash", "Query hash using short form"]
chunk_type: code
tokens: 96
summary: "Query hash using short form"
---

## Query hash using short form
$ moon query hash 0b55b234
```

By default, this will output the contents of the hash manifest (which is JSON), and the fully qualified resolved hash.

```
Hash: 0b55b234f1018581c45b00241d7340dc648c63e639fbafdaf85a4cd7e718fdde

{
  "command": "build",
  "args": ["./build"]
  // ...
}
```

The command can also be output raw JSON by passing the `--json` flag.

### Options

- `--json` - Display the diff in JSON format.

### Configuration

- [`hasher`](/docs/config/workspace#hasher) in `.moon/workspace.yml`
