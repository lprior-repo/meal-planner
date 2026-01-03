---
doc_id: ops/guides/open-source
chunk_id: ops/guides/open-source#chunk-2
heading_path: ["Open source usage", "Reporting run results"]
chunk_type: prose
tokens: 45
summary: "Reporting run results"
---

## Reporting run results

We also suggest using our [`moonrepo/run-report-action`](https://github.com/marketplace/actions/moon-ci-run-reports) GitHub action. This action will report the results of a [`moon ci`](/docs/commands/ci) run to a pull request as a comment and workflow summary.

.github/workflows/ci.yml

```yaml
