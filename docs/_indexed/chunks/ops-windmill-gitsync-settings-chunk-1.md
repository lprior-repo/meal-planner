---
doc_id: ops/windmill/gitsync-settings
chunk_id: ops/windmill/gitsync-settings#chunk-1
heading_path: ["Git sync settings"]
chunk_type: prose
tokens: 202
summary: "Git sync settings"
---

# Git sync settings

> **Context**: Managing git-sync configuration between your local `wmill.yaml` file and the Windmill workspace backend is made easy using the wmill CLI. Git-sync set

Managing git-sync configuration between your local `wmill.yaml` file and the Windmill workspace backend is made easy using the wmill CLI. Git-sync settings operations are behind the `wmill gitsync-settings` subcommand.

The `gitsync-settings` command allows you to synchronize filter settings, path configurations, and branch-specific overrides without affecting the actual workspace content (scripts, flows, apps, etc.).

Git-sync settings management is done using `wmill gitsync-settings pull` & `wmill gitsync-settings push`.

Settings operations are configuration-only and work with your `wmill.yaml` file structure. The command will show you the list of changes and ask for confirmation before applying them.

When pulling, the source is the remote workspace git-sync configuration and the target is your local `wmill.yaml` file, and when pushing, the source is your local `wmill.yaml` and the target is the remote workspace configuration.
