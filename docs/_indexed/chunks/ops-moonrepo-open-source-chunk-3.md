---
doc_id: ops/moonrepo/open-source
chunk_id: ops/moonrepo/open-source#chunk-3
heading_path: ["Open source usage", "..."]
chunk_type: prose
tokens: 37
summary: "..."
---

## ...
jobs:
  ci:
    name: 'CI'
    runs-on: 'ubuntu-latest'
    steps:
      # ...
      - run: 'yarn moon ci'
      - uses: 'moonrepo/run-report-action@v1'
        if: success() || failure()
        with:
          access-token: ${{ secrets.GITHUB_TOKEN }}
```
