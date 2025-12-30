---
doc_id: ops/guides/debug-task
chunk_id: ops/guides/debug-task#chunk-4
heading_path: ["Debugging a task", "Inspect the hash manifest"]
chunk_type: code
tokens: 471
summary: "Inspect the hash manifest"
---

## Inspect the hash manifest

With the hash in hand, let's dig deeper into moon's internals, by inspecting the hash manifest at `.moon/cache/hashes/<hash>.json`, or running the [`moon query hash`](/docs/commands/query/hash) command:

```shell
moon query hash <hash>
```

The manifest is JSON and its contents are all the information used to generate its unique hash. This information is an array, and breaks down as follows:

- The first item in the array is the task itself. The important fields to diagnose here are `deps` and `inputs`.
  - Dependencies are other tasks (and their hash) that this task depends on.
  - Inputs are all the files (and their hash from `git hash-object`) this task requires to run.
- The remaining items are toolchain/language specific, some examples are:
  - **Node.js** - The current Node.js version and the resolved versions/hashes of all `package.json` dependencies.
  - **Rust** - The current Rust version and the resolved versions/hashes of all `Cargo.toml` dependencies.
  - **TypeScript** - Compiler options for changing compilation output.

Some issues to look out for:

- Do the dependencies match the task's configured [`deps`](/docs/config/project#deps) and [`implicitDeps`](/docs/config/tasks#implicitdeps)?
- Do the inputs match the task's configured [`inputs`](/docs/config/project#inputs) and [`implicitInputs`](/docs/config/tasks#implicitinputs)? If not, try tweaking the config.
- Are the toolchain/language specific items correct?
- Are dependency versions/hashes correctly parsed from the appropriate lockfile?

### Diffing a previous hash

Another avenue for diagnosing a task is to diff the hash against a hash from a previous run. Since we require multiple hashes, we'll need to run the task multiple times, [inspect the logs](#inspect-trace-logs), and extract the hash for each. If you receive the same hash for each run, you'll need to tweak configuration or change files to produce a different hash.

Once you have 2 unique hashes, we can pass them to the [`moon query hash-diff`](/docs/commands/query/hash-diff) command. This will produce a `git diff` styled output, allowing for simple line-by-line comparison debugging.

```shell
moon query hash-diff <hash-left> <hash-right>
```

```diff
Left:  0b55b234f1018581c45b00241d7340dc648c63e639fbafdaf85a4cd7e718fdde
Right: 2388552fee5a02062d0ef402bdc7232f0a447458b058c80ce9c3d0d4d7cfe171

[
	{
		"command": "build",
		"args": [
+			"./dist"
-			"./build"
		],
		...
	}
]
```

This is extremely useful in diagnoising why a task is running differently than before, and is much easier than inspecting the hash manifest files manually!
