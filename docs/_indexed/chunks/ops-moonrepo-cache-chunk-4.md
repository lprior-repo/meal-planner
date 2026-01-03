---
doc_id: ops/moonrepo/cache
chunk_id: ops/moonrepo/cache#chunk-4
heading_path: ["Cache", "File structure"]
chunk_type: prose
tokens: 200
summary: "File structure"
---

## File structure

The following diagram outlines our cache folder structure and why each piece exists.

```
.moon/cache/
	# Stores hash manifests of every ran task. Exists purely for debugging purposes.
	hashes/
		# Contents includes all sources used to generate the hash.
		<hash>.json

	# Stores `tar.gz` archives of a task's outputs based on its generated hash.
	outputs/
		<hash>.tar.gz

	# State information about anything and everything within moon. Toolchain,
	# dependencies, projects, running targets, etc.
	states/
		# Files at the root pertain to the entire workspace.
		<state>.json

		# Files for a project are nested within a folder by the project name.
		<project>/
			# Informational snapshot of the project, its tasks, and its configs.
			# Can be used at runtime by tasks that require this information.
			snapshot.json

			<task>/
				# Contents of the child process, including the exit code and
				# unique hash that is referenced above.
				lastRun.json

				# Outputs of last run target.
				stderr.log
				stdout.log
```
