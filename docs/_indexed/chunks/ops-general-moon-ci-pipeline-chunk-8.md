---
doc_id: ops/general/moon-ci-pipeline
chunk_id: ops/general/moon-ci-pipeline#chunk-8
heading_path: ["Build & Test (Moon)", "Troubleshooting"]
chunk_type: prose
tokens: 48
summary: "Troubleshooting"
---

## Troubleshooting

**"sccache not found"**: Ensure mise is installed: `mise install`

**"moon not found"**: Check PATH includes `.moon/bin`

**Cache not working**: Check `moon.yml` has correct input paths. Run with `--log debug`.

See: [ARCHITECTURE.md](./ops-general-architecture.md) for how binaries work
