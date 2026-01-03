---
doc_id: ops/query/hash-diff
chunk_id: ops/query/hash-diff#chunk-3
heading_path: ["query hash-diff", "Diff between 2 hashes using short form"]
chunk_type: code
tokens: 182
summary: "Diff between 2 hashes using short form"
---

## Diff between 2 hashes using short form
$ moon query hash-diff 0b55b234 2388552f
```

By default, this will output the contents of a hash file (which is JSON), highlighting the differences between the left and right hashes. Lines that match will be printed in white, while the left differences printed in green, and right differences printed in red. If you use `git diff`, this will feel familiar to you.

```
Left:  0b55b234f1018581c45b00241d7340dc648c63e639fbafdaf85a4cd7e718fdde
Right: 2388552fee5a02062d0ef402bdc7232f0a447458b058c80ce9c3d0d4d7cfe171

{
	"command": "build",
	"args": [
+		"./dist"
-		"./build"
	],
	...
}
```

The differences can also be output in JSON by passing the `--json` flag. The output has the following structure:

```
{
	left: string,
	left_hash: string,
	left_diffs: string[],
	right: string,
	right_hash: string,
	right_diffs: string[],
}
```

### Options

- `--json` - Display the manifest in JSON format.

### Configuration

- [`hasher`](/docs/config/workspace#hasher) in `.moon/workspace.yml`
