---
doc_id: ops/moonrepo/touched-files
chunk_id: ops/moonrepo/touched-files#chunk-4
heading_path: ["query touched-files", "Return all files between 2 revisions"]
chunk_type: code
tokens: 223
summary: "Return all files between 2 revisions"
---

## Return all files between 2 revisions
$ moon query touched-files --base <branch> --head <commit>
```

By default, this will output a list of absolute file paths, separated by new lines.

```
/absolute/file/one.ts
/absolute/file/two.ts
```

The files can also be output in JSON by passing the `--json` flag. The output has the following structure:

```
{
	files: string[],
	options: QueryOptions,
}
```

### Options

- `--defaultBranch` - When on the default branch, compare against the previous revision.
- `--base <rev>` - Base branch, commit, or revision to compare against. Defaults to [`vcs.defaultBranch`](/docs/config/workspace#defaultbranch).
- `--head <rev>` - Current branch, commit, or revision to compare with. Defaults to `HEAD`.
- `--json` - Display the files in JSON format.
- `--local` - Gather files from the local state instead of remote.
- `--remote` - Gather files from the remote state instead of local.
- `--status <type>` - Filter files based on a touched status. Can be passed multiple times.
  - Types: `all` (default), `added`, `deleted`, `modified`, `staged`, `unstaged`, `untracked`

### Configuration

- [`vcs`](/docs/config/workspace#vcs) in `.moon/workspace.yml`
