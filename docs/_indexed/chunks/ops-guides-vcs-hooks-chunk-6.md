---
doc_id: ops/guides/vcs-hooks
chunk_id: ops/guides/vcs-hooks#chunk-6
heading_path: ["VCS hooks", "Examples"]
chunk_type: prose
tokens: 132
summary: "Examples"
---

## Examples

### Pre-commit

A perfect use case for the `pre-commit` hook is to check linting and formatting of the files being committed. If either of these tasks fail, the commit will abort until they are fixed. Be sure to use the [`--affected`](/docs/run-task#running-based-on-affected-files-only) option so that we *only run* on changed projects!

.moon/workspace.yml

```yaml
vcs:
  hooks:
    pre-commit:
      - 'moon run :lint :format --affected --status=staged'
```

> By default this will run on the *entire* project (all files). If you want to filter it to only the changed files, enable the [`affectedFiles`](/docs/config/project#affectedfiles) task option.

**Tags:**

- [vcs](/docs/tags/vcs)
- [hooks](/docs/tags/hooks)
- [git](/docs/tags/git)
- [git-hooks](/docs/tags/git-hooks)
