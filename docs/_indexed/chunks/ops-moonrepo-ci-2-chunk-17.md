---
doc_id: ops/moonrepo/ci-2
chunk_id: ops/moonrepo/ci-2#chunk-17
heading_path: ["Continuous integration (CI)", "..."]
chunk_type: prose
tokens: 72
summary: "..."
---

## ...
jobs:
  ci:
    name: 'CI'
    runs-on: 'ubuntu-latest'
    steps:
      # ...
      - run: 'moon ci'
      - uses: 'moonrepo/run-report-action@v1'
        if: success() || failure()
        with:
          access-token: ${{ secrets.GITHUB_TOKEN }}
```

### Community offerings

The following GitHub actions are provided by the community:

- [`appthrust/moon-ci-retrospect`](https://github.com/appthrust/moon-ci-retrospect) - Displays the results of a `moon ci` run in a more readable fashion.
