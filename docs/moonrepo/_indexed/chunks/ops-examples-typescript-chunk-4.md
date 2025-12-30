---
doc_id: ops/examples/typescript
chunk_id: ops/examples/typescript#chunk-4
heading_path: ["TypeScript example", "FAQ"]
chunk_type: prose
tokens: 70
summary: "FAQ"
---

## FAQ

### How to preserve pretty output?

TypeScript supports a pretty format where it includes codeframes and color highlighting for failures. However, when `tsc` is piped or the terminal is not a TTY, the pretty format is lost. To preserve and always display the pretty format, be sure to pass the `--pretty` argument!
