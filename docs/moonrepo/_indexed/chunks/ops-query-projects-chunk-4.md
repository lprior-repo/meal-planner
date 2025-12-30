---
doc_id: ops/query/projects
chunk_id: ops/query/projects#chunk-4
heading_path: ["query projects", "Find all projects with a `lint` or `build` task"]
chunk_type: code
tokens: 180
summary: "Find all projects with a `lint` or `build` task"
---

## Find all projects with a `lint` or `build` task
$ moon query projects --tasks "lint|build"
$ moon query projects "task=[lint,build]"
```

By default, this will output a list of projects in the format of `<id> | <source> | <stack> | <type> | <language> | <description>`, separated by new lines. If no description is defined, "..." will be displayed instead.

```
web | apps/web | frontend | application | typescript | ...
```

The projects can also be output in JSON by passing the `--json` flag. The output has the following structure:

```
{
	projects: Project[],
	options: QueryOptions,
}
```

### Affected projects

This command can also be used to query for affected projects, based on the state of the VCS working tree. For advanced control, you can also pass the results of `moon query touched-files` to stdin.

```
