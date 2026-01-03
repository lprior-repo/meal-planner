---
doc_id: ops/guides/debug-task
chunk_id: ops/guides/debug-task#chunk-3
heading_path: ["Debugging a task", "Inspect trace logs"]
chunk_type: code
tokens: 370
summary: "Inspect trace logs"
---

## Inspect trace logs

If configuration looks good, let's move on to inspecting the trace logs, which can be a non-trivial amount of effort. Run the task to generate the logs, bypass the cache, and include debug information:

```shell
MOON_DEBUG_PROCESS_ENV=true MOON_DEBUG_PROCESS_INPUT=true moon run <target> --log trace --updateCache
```

Once ran, a large amount of information will be logged to the terminal. However, most of it can be ignored, as we're only interested in the "is this task affected by changes" logs. This breaks down as follows:

1. First, we gather touched files from the local checkout, which is typically `git status --porcelain --untracked-files` (from the `moon_process::command_inspector` module). The logs do not output the list of files that are touched, but you can run this command locally to verify the output.
2. Secondly, we gather all files from the project directory, using the `git ls-files --full-name --cached --modified --others --exclude-standard <path> --deduplicate` command (also from the `moon_process::command_inspector` module). This command can also be ran locally to verify the output.
3. Lastly, all files from the previous 2 commands will be hashed using the `git hash-object` command. If you passed the `MOON_DEBUG_PROCESS_INPUT` environment variable, you'll see a massive log entry of all files being hashed. This is what we use to generate moon's specific hash.

If all went well, you should see a log entry that looks like this:

```
Generated hash <hash> for target <target>
```

The important piece is the hash, which is a 64-character SHA256 hash, and represents the unique hash of this task/target. This is what moon uses to determine a cache hit/miss, and whether or not to skip re-running a task.

Let's copy the hash and move on to the next step.
