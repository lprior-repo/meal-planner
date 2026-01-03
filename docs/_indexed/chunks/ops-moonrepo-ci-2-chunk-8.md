---
doc_id: ops/moonrepo/ci-2
chunk_id: ops/moonrepo/ci-2#chunk-8
heading_path: ["Continuous integration (CI)", "Comparing revisions"]
chunk_type: prose
tokens: 106
summary: "Comparing revisions"
---

## Comparing revisions

By default the command will attempt to detect the base and head revisions automatically based on the current CI provider (powered by the [`ci_env`](https://github.com/milesj/rust-cicd-env) Rust crate). If nothing was detected, this will fallback to the configured [`vcs.defaultBranch`](/docs/config/workspace#defaultbranch) for the base revision, and `HEAD` for the head revision.

These values can be customized with the `--base` and `--head` command line options, or the `MOON_BASE` and `MOON_HEAD` environment variables, which takes highest precedence.

```shell
$ moon ci --base <BRANCH> --head <SHA>
