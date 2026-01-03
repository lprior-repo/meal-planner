---
doc_id: ops/moonrepo/ci-2
chunk_id: ops/moonrepo/ci-2#chunk-16
heading_path: ["Continuous integration (CI)", "Reporting run results"]
chunk_type: prose
tokens: 53
summary: "Reporting run results"
---

## Reporting run results

If you're using GitHub Actions as your CI provider, we suggest using our [`moonrepo/run-report-action`](https://github.com/marketplace/actions/moon-ci-run-reports). This action will report the results of a [`moon ci`](/docs/commands/ci) run to a pull request as a comment and workflow summary.

.github/workflows/ci.yml

```yaml
